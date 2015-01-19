$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require 'test/unit'
require 'json'
require 'apple_pay'

class ApplePay::TokenTest < Test::Unit::TestCase

  def setup
    fixtures = File.dirname(__FILE__) + "/fixtures/"
    @token_attrs = JSON.parse(File.read(fixtures + "token.json"))
    @certificate = File.read(fixtures + "certificate.pem")
    @private_key = File.read(fixtures + "private_key.pem")
    @apple_pay_token = ApplePay::Token.new(@token_attrs)
    @merchant_id = "F938F4658CA2C1C9C38B8DFCB5DBB2A2245607DDE2F114620E8468EF52D208CA"
    @shared_secret = Base64.decode64("a2pPfemSdA560FnzLSv8zfdlWdGJTonApOLq1zfgx8w=")
    @symmetric_key = Base64.decode64("HOSago9Z1DhhukQvzmgpuCGPuwq1W0AgasMQWNZvUIY=")
  end

  def test_initialize
    assert_equal @token_attrs["version"], @apple_pay_token.version
    assert_equal @token_attrs["data"], @apple_pay_token.data
    assert_equal @token_attrs["signature"], @apple_pay_token.signature
    assert_equal @token_attrs["header"]["transactionId"], @apple_pay_token.transaction_id
    assert_equal @token_attrs["header"]["ephemeralPublicKey"], @apple_pay_token.ephemeral_public_key
    assert_equal @token_attrs["header"]["publicKeyHash"], @apple_pay_token.public_key_hash
  end

  def test_merchant_id
    cert = OpenSSL::X509::Certificate.new(@certificate)
    assert_equal @merchant_id, ApplePay::Token.extract_merchant_id(cert)
  end

  def test_shared_secret
    priv_key = OpenSSL::PKey::EC.new(@private_key)
    assert_equal @shared_secret, ApplePay::Token.generate_shared_secret(priv_key, @token_attrs["header"]["ephemeralPublicKey"])
  end

  def test_symmetric_key
    assert_equal @symmetric_key, ApplePay::Token.generate_symmetric_key(@merchant_id, @shared_secret)
  end

  def test_decrypt
    payment_data = @apple_pay_token.decrypt(@certificate, @private_key)
    assert_equal "4109370251004320", payment_data["applicationPrimaryAccountNumber"]
    assert_equal "200731", payment_data["applicationExpirationDate"]
    assert_equal "840", payment_data["currencyCode"]
    assert_equal 100, payment_data["transactionAmount"]
    assert_equal nil, payment_data["cardholderName"]
    assert_equal "040010030273", payment_data["deviceManufacturerIdentifier"]
    assert_equal "3DSecure", payment_data["paymentDataType"]
    assert_equal "Af9x/QwAA/DjmU65oyc1MAABAAA=", payment_data["paymentData"]["onlinePaymentCryptogram"]
    assert_equal "5", payment_data["paymentData"]["eciIndicator"]
  end
end
