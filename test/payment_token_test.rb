$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require 'minitest/autorun'
require 'json'
require 'gala'

class Gala::PaymentTokenTest < Minitest::Test

  def setup
    fixtures = File.dirname(__FILE__) + "/fixtures/"
    @token_attrs = JSON.parse(File.read(fixtures + "token.json"))
    @certificate = File.read(fixtures + "certificate.pem")
    @private_key = File.read(fixtures + "private_key.pem")
    @payment_token = Gala::PaymentToken.new(@token_attrs)
    @merchant_id = "358DA5890B9555C0A9EFB84B5CD6FF04BFDCD5AABF5DC14B9872D8DF51EAF439"
    @shared_secret = Base64.decode64("yCUzDuNYTnUnANZEdxC7+DvPmqNslB2YWYn68SBsJHU=")
    @symmetric_key = Base64.decode64("3GTXJ4RuP/IhS23hsdOw2J2ecAZmC0RasbPIFdC3nQM=")

  end

  def test_initialize
    assert_equal @token_attrs["version"], @payment_token.version
    assert_equal @token_attrs["data"], @payment_token.data
    assert_equal @token_attrs["signature"], @payment_token.signature
    assert_equal @token_attrs["header"]["transactionId"], @payment_token.transaction_id
    assert_equal @token_attrs["header"]["ephemeralPublicKey"], @payment_token.ephemeral_public_key
    assert_equal @token_attrs["header"]["publicKeyHash"], @payment_token.public_key_hash
  end

  def test_merchant_id
    cert = OpenSSL::X509::Certificate.new(@certificate)
    assert_equal @merchant_id, Gala::PaymentToken.extract_merchant_id(cert)
  end

  def test_shared_secret
    priv_key = OpenSSL::PKey::EC.new(@private_key)
    assert_equal @shared_secret, Gala::PaymentToken.generate_shared_secret(priv_key, @token_attrs["header"]["ephemeralPublicKey"])
  end

  def test_symmetric_key
    assert_equal @symmetric_key, Gala::PaymentToken.generate_symmetric_key(@merchant_id, @shared_secret)
  end

  def test_decrypt
    temp = @payment_token.decrypt(@certificate, @private_key)
    payment_data = JSON.parse(temp)
    assert_equal "5353756319181169", payment_data["applicationPrimaryAccountNumber"]
    assert_equal "240930", payment_data["applicationExpirationDate"]
    assert_equal "840", payment_data["currencyCode"]
    assert_equal 100, payment_data["transactionAmount"]
    assert_nil payment_data["cardholderName"]
    assert_equal "050110030273", payment_data["deviceManufacturerIdentifier"]
    assert_equal "3DSecure", payment_data["paymentDataType"]
    assert_equal "AMwBRjPWDnAgAA7Rls7mAoABFA==", payment_data["paymentData"]["onlinePaymentCryptogram"]
  end

  def test_failed_decrypt
    @payment_token.data = "bogus4OZho15e9Yp5K0EtKergKzeRpPAjnKHwmSNnagxhjwhKQ5d29sfTXjdbh1CtTJ4DYjsD6kfulNUnYmBTsruphBz7RRVI1WI8P0LrmfTnImjcq1mi"
    exception = assert_raises Gala::PaymentToken::InvalidSignatureError do
      JSON.parse(@payment_token.decrypt(@certificate, @private_key))
    end
    assert_equal("The given signature is not a valid ECDSA signature.", exception.message)
  end
end
