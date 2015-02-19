require 'openssl'
require 'base64'
require 'aead'

module Gala
  class PaymentToken

    MERCHANT_ID_FIELD_OID = "1.2.840.113635.100.6.32"

    attr_accessor :version, :data, :signature, :transaction_id, :ephemeral_public_key,
      :public_key_hash

    class MissingMerchantIdError < StandardError; end;

    def initialize(token_attrs)
      self.version = token_attrs["version"]
      self.data = token_attrs["data"]
      self.signature = token_attrs["signature"]
      headers = token_attrs["header"]
      self.transaction_id = headers["transactionId"]
      self.ephemeral_public_key = headers["ephemeralPublicKey"]
      self.public_key_hash = headers["publicKeyHash"]
    end

    def decrypt(certificate_pem, private_key_pem)

      certificate = OpenSSL::X509::Certificate.new(certificate_pem)
      private_key = OpenSSL::PKey::EC.new(private_key_pem)

      merchant_id = self.class.extract_merchant_id(certificate)
      shared_secret = self.class.generate_shared_secret(private_key, ephemeral_public_key)
      symmetric_key = self.class.generate_symmetric_key(merchant_id, shared_secret)

      decrypted_json = self.class.decrypt(Base64.decode64(data), symmetric_key)
      JSON.parse(decrypted_json)
    end

    class << self

      def extract_merchant_id(certificate)
        merchant_id_field = certificate.extensions.find do |ext|
          ext.oid == MERCHANT_ID_FIELD_OID
        end
        raise MissingMerchantIdError unless merchant_id_field
        val = merchant_id_field.value
        val[2..(val.length - 1)]
      end

      def generate_shared_secret(private_key, ephemeral_public_key)
        public_ec = OpenSSL::PKey::EC.new(Base64.decode64(ephemeral_public_key))
        point = OpenSSL::PKey::EC::Point.new(private_key.group, public_ec.public_key.to_bn)
        private_key.dh_compute_key(point)
      end

      # Derive the symmetric key using the key derivation function described in NIST SP 800-56A, section 5.8.1
      #   http://csrc.nist.gov/publications/nistpubs/800-56A/SP800-56A_Revision1_Mar08-2007.pdf
      def generate_symmetric_key(merchant_id, shared_secret)

        kdf_algorithm = "\x0D" + 'id-aes256-GCM'
        kdf_party_v = merchant_id.scan(/../).inject("") { |binary,hn| binary << hn.to_i(16).chr } # Converts each pair of hex characters into bytes in a string.
        kdf_info = kdf_algorithm + "Apple" + kdf_party_v

        digest = Digest::SHA256.new
        digest << 0.chr * 3
        digest << 1.chr
        digest << shared_secret
        digest << kdf_info
        digest.digest
      end

      def decrypt(encrypted_data, symmetric_key)
        init_length = 16
        init_vector = 0.chr * init_length
        mode = ::AEAD::Cipher.new('aes-256-gcm')
        cipher = mode.new(symmetric_key, iv_len: init_length)
        cipher.decrypt(init_vector, '', encrypted_data)
      end
    end
  end
end
