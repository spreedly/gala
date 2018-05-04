require 'openssl'
require 'base64'

module Gala
  class PaymentToken

    MERCHANT_ID_FIELD_OID = "1.2.840.113635.100.6.32"
    LEAF_CERTIFICATE_OID = "1.2.840.113635.100.6.29"
    INTERMEDIATE_CERTIFICATE_OID = "1.2.840.113635.100.6.2.14"
    APPLE_ROOT_CERT = File.read(File.dirname(__FILE__) + "/resources/AppleRootCA-G3.pem")

    attr_accessor :version, :data, :signature, :transaction_id, :ephemeral_public_key,
      :public_key_hash, :application_data

    class MissingMerchantIdError < StandardError; end;
    class InvalidSignatureError < StandardError; end;

    def initialize(token_attrs)
      self.version = token_attrs["version"]
      self.data = token_attrs["data"]
      self.signature = token_attrs["signature"]
      headers = token_attrs["header"]
      self.transaction_id = headers["transactionId"]
      self.ephemeral_public_key = headers["ephemeralPublicKey"]
      self.public_key_hash = headers["publicKeyHash"]
      self.application_data = headers["applicationData"]
    end

    def decrypt(certificate_pem, private_key_pem)
      self.class.validate_signature(signature, ephemeral_public_key, data, transaction_id, application_data)

      certificate = OpenSSL::X509::Certificate.new(certificate_pem)
      merchant_id = self.class.extract_merchant_id(certificate)
      private_key = OpenSSL::PKey::EC.new(private_key_pem)
      shared_secret = self.class.generate_shared_secret(private_key, ephemeral_public_key)
      symmetric_key = self.class.generate_symmetric_key(merchant_id, shared_secret)

      # Return JSON string, up to caller to parse
      self.class.decrypt(Base64.decode64(data), symmetric_key)
    end

    class << self

      def validate_signature(signature, ephemeral_public_key, data, transaction_id, application_data)
        # Ensure that the certificates contain the correct custom OIDs
        intermediate_cert = nil
        leaf_cert = nil
        p7 = OpenSSL::PKCS7.new(Base64.decode64(signature))
        p7.certificates.each {|c|
          c.extensions.each { |e|
            leaf_cert = c if e.oid == LEAF_CERTIFICATE_OID
            intermediate_cert = c if e.oid == INTERMEDIATE_CERTIFICATE_OID
          }
        }
        raise InvalidSignatureError, "Signature does not contain the correct custom OIDs." unless leaf_cert && intermediate_cert

        # Ensure that the root CA is the Apple Root CA - G3
        root_cert = OpenSSL::X509::Certificate.new(APPLE_ROOT_CERT)

        # Ensure that there is a valid X.509 chain of trust from the signature to the root CA
        raise InvalidSignatureError, "Unable to verify a valid chain of trust from signature to root certificate." unless chain_of_trust_verified?(leaf_cert, intermediate_cert, root_cert)

        #Ensure that the signature is a valid ECDSA signature
        unless application_data
          verification_string = Base64.decode64(ephemeral_public_key) + Base64.decode64(data) + [transaction_id].pack("H*")
          # verification_string = verification_string + application_data.pack("H*") if application_data
          store = OpenSSL::X509::Store.new
          verified = p7.verify([], store, verification_string, OpenSSL::PKCS7::NOVERIFY )
          raise InvalidSignatureError, "The given signature is not a valid ECDSA signature." unless verified
        end
      end

      def chain_of_trust_verified?(leaf_cert, intermediate_cert, root_cert)
        trusted_certificate_store = OpenSSL::X509::Store.new.tap do |store|
          store.add_cert(root_cert)
          store.add_cert(intermediate_cert)
        end
        trusted_certificate_store.verify(leaf_cert)
      end

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
        # Initialization vector of 16 null bytes
        iv_length = 16
        # 0.chr => "\x00"
        iv = 0.chr * iv_length

        # Last 16 bytes (iv_length) of encrypted data
        tag = encrypted_data[-iv_length..-1]
        # Data without tag
        encrypted_data = encrypted_data[0..(-iv_length - 1)]

        cipher = OpenSSL::Cipher.new("aes-256-gcm").decrypt
        cipher.key = symmetric_key
        cipher.iv_len = iv_length
        cipher.iv = iv

        # Decipher without associated authentication data
        cipher.auth_tag = tag
        cipher.auth_data = ''

        cipher.update(encrypted_data) + cipher.final
      end
    end
  end
end
