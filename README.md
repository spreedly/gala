# Gala

[![CircleCI](https://circleci.com/gh/spreedly/gala.svg?style=svg)](https://circleci.com/gh/spreedly/gala)

Named after the [Gala apple](http://en.wikipedia.org/wiki/Gala_(apple)), Gala is a Ruby library for decrypting [Apple Pay payment tokens](https://developer.apple.com/library/ios/documentation/PassKit/Reference/PaymentTokenJSON/PaymentTokenJSON.html).

Gala is available under the MIT License.

## Ruby support

* For Ruby v2.3 and below, please use the [legacy-ruby branch](https://github.com/spreedly/gala/commits/legacy-ruby), or specify gala v0.3.2.
* For Ruby >= 2.4, use the master branch or specify gala v0.4 and above

## Install

Add `gala` to your `Gemfile`.

```ruby
gem "gala", "~> 0.4.0"
```

If you need to track a development branch or reference functionality not yet contained in the RubyGem release you can specify the gala repo directly.

```ruby
gem "gala", git: "https://github.com/spreedly/gala.git", ref: :master
```

Then `bundle install` to fetch Gala into your local environment.

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
$ rake test
Started
......

Finished in 0.017918 seconds.
```

## Releasing

To cut a new gem:

### Setup RubyGems account

Make sure you have a [RubyGems account](https://rubygems.org) and have setup your local gem credentials with something like this:

```bash
$ curl -u rwdaigle https://rubygems.org/api/v1/api_key.yaml > ~/.gem/credentials; chmod 0600 ~/.gem/credentials
<enter rubygems account password>
```

If you are not yet listed as a gem owner, you will need to [request access](http://guides.rubygems.org/command-reference/#gem-owner) from @rwdaigle.

### Release

Build and release the gem with (all changes should be committed and pushed to Github):

```bash
$ rake release
```

## Changelog

### v0.5.0

*Update Openssl to support Ruby 3

### v0.4.0

* Remove unmaintained `aead` gem dependency
* Rely on Ruby 2.4 openssl support for aes-256-gcm ciphers (and specifying the initialization vector length).

### v0.3.2

* Setup CircleCI for more comprehensive Ruby version/compatibility testing
* Use Minitest instead of TestUnit to more seamlessly support higher Ruby versions
* Last planned release that supports < Ruby 2.4

### v0.3.1

* Use Shopify aead library for compatibility w/ Ruby >= v2.2

### v0.3.0

* Verify payment token signature

## Contributors

* [dankimio](https://github.com/dankimio)
* [davidsantoso](https://github.com/davidsantoso)
* [mrezentes](https://github.com/mrezentes)
* [jnormore](https://github.com/jnormore)
