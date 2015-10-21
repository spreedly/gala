# Gala

Named after the [Gala apple](http://en.wikipedia.org/wiki/Gala_(apple)), Gala is a Ruby library for decrypting [Apple Pay payment tokens](https://developer.apple.com/library/ios/documentation/PassKit/Reference/PaymentTokenJSON/PaymentTokenJSON.html).

## Install

Add to your `Gemfile`:

```ruby
gem "gala", git: "https://github.com/spreedly/gala.git"
```

## Usage

Gala works by:

1. Initializing an instance of `Gala::PaymentToken` with the hash of values present in the Apple Pay token string (a JSON representation of [this data](https://developer.apple.com/library/ios/documentation/PassKit/Reference/PaymentTokenJSON/PaymentTokenJSON.html)).
2. Decrypting the token using the PEM formatted merchant certificate and private key (the latter of which, at least, is managed by a third-party such as a gateway or independent processor like [Spreedly](https://spreedly.com)).

```ruby
require "gala"

# token_json = raw token string you get from your iOS app
token_attrs = JSON.parse(token_json)
token = Gala::PaymentToken.new(token_attrs)

certificate_pem = File.read("mycert.pem")
private_key_pem = File.read("private_key.pem")

decrypted_json = token.decrypt(certificate_pem, private_key_pem)
JSON.parse(decrypted_json)
# =>
{
  "applicationPrimaryAccountNumber"=>"4109370251004320",
  "applicationExpirationDate"=>"200731",
  "currencyCode"=>"840",
  "transactionAmount"=>100,
  "deviceManufacturerIdentifier"=>"040010030273",
  "paymentDataType"=>"3DSecure",
  "paymentData"=> {
    "onlinePaymentCryptogram"=>"Af9x/QwAA/DjmU65oyc1MAABAAA=",
    "eciIndicator"=>"5"
  }
}
```

## Testing

```session
$ ruby test/payment_token_test.rb
...
5 tests, 18 assertions, 0 failures, 0 errors, 0 skips
```

## Contributors

* [jnormore](https://github.com/jnormore) for his help with figuring out how to decrypt this thing.
