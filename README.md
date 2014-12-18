# EZID Client

EZID API Version 2 bindings. See http://ezid.cdlib.org/doc/apidoc.html.

[![Gem Version](https://badge.fury.io/rb/ezid-client.svg)](http://badge.fury.io/rb/ezid-client)
[![Build Status](https://travis-ci.org/duke-libraries/ezid-client.svg?branch=master)](https://travis-ci.org/duke-libraries/ezid-client)

## Installation

Add this line to your application's Gemfile:

    gem 'ezid-client'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ezid-client

## Basic Resource-oriented Usage (CRUD)

*See the test suite for more examples.*

**Create** (Mint/Create)

[Mint an identifier on a shoulder](http://ezid.cdlib.org/doc/apidoc.html#operation-mint-identifier)

```ruby
>> identifier = Ezid::Identifier.create(shoulder: "ark:/99999/fk4")
I, [2014-12-04T15:06:02.428445 #86655]  INFO -- : EZID MINT ark:/99999/fk4 -- success: ark:/99999/fk4rx9d523
I, [2014-12-04T15:06:03.249793 #86655]  INFO -- : EZID GET ark:/99999/fk4rx9d523 -- success: ark:/99999/fk4rx9d523
=> #<Ezid::Identifier id="ark:/99999/fk4rx9d523" status="public" target="http://ezid.cdlib.org/id/ark:/99999/fk4rx9d523" created="2014-12-04 20:06:02 UTC">
>> identifier.id
=> "ark:/99999/fk4rx9d523"
>> identifier.status
=> "public"
>> identifier.target
=> "http://ezid.cdlib.org/id/ark:/99999/fk4rx9d523"
```

A default shoulder can be configured:

- By environment variable (added in v0.9.1):

```sh
export EZID_DEFAULT_SHOULDER="ark:/99999/fk4"
```

- By client configuration:

```ruby
Ezid::Client.configure do |config|
  config.default_shoulder = "ark:/99999/fk4"
end
```

New identifiers will then be minted on the default shoulder when a shoulder is not specified:

```ruby
>> identifier = Ezid::Identifier.create
I, [2014-12-09T11:22:34.499860 #32279]  INFO -- : EZID MINT ark:/99999/fk4 -- success: ark:/99999/fk43f4wd4v
I, [2014-12-09T11:22:35.317181 #32279]  INFO -- : EZID GET ark:/99999/fk43f4wd4v -- success: ark:/99999/fk43f4wd4v
=> #<Ezid::Identifier id="ark:/99999/fk43f4wd4v" status="public" target="http://ezid.cdlib.org/id/ark:/99999/fk43f4wd4v" created="2014-12-09 16:22:35 UTC">
```

[Create a specific identifier](http://ezid.cdlib.org/doc/apidoc.html#operation-create-identifier)

```ruby
>> identifier = Ezid::Identifier.create(id: "ark:/99999/fk4rx9d523/12345")
I, [2014-12-09T11:21:42.077297 #32279]  INFO -- : EZID CREATE ark:/99999/fk4rx9d523/12345 -- success: ark:/99999/fk4rx9d523/12345
I, [2014-12-09T11:21:42.808534 #32279]  INFO -- : EZID GET ark:/99999/fk4rx9d523/12345 -- success: ark:/99999/fk4rx9d523/12345
=> #<Ezid::Identifier id="ark:/99999/fk4rx9d523/12345" status="public" target="http://ezid.cdlib.org/id/ark:/99999/fk4rx9d523/12345" created="2014-12-09 16:21:42 UTC">
```

**Retrieve** (Get Metadata)

```ruby
>> identifier = Ezid::Identifier.find("ark:/99999/fk4rx9d523")
I, [2014-12-04T15:07:00.648676 #86655]  INFO -- : EZID GET ark:/99999/fk4rx9d523 -- success: ark:/99999/fk4rx9d523
=> #<Ezid::Identifier id="ark:/99999/fk4rx9d523" status="public" target="http://ezid.cdlib.org/id/ark:/99999/fk4rx9d523" created="2014-12-04 20:06:02 UTC">
```

**Update** (Modify)

```ruby
>> identifier.target
=> "http://ezid.cdlib.org/id/ark:/99999/fk43f4wd4v"
>> identifier.target = "http://example.com"
=> "http://example.com"
>> identifier.save
I, [2014-12-09T11:24:26.321801 #32279]  INFO -- : EZID MODIFY ark:/99999/fk43f4wd4v -- success: ark:/99999/fk43f4wd4v
I, [2014-12-09T11:24:27.039288 #32279]  INFO -- : EZID GET ark:/99999/fk43f4wd4v -- success: ark:/99999/fk43f4wd4v
=> #<Ezid::Identifier id="ark:/99999/fk43f4wd4v" status="public" target="http://example.com" created="2014-12-09 16:22:35 UTC">
>> identifier.target
=> "http://example.com"
```

**Delete**

*Identifier status must be "reserved" to delete.* http://ezid.cdlib.org/doc/apidoc.html#operation-delete-identifier

```ruby
>> identifier = Ezid::Identifier.create(shoulder: "ark:/99999/fk4", status: "reserved")
I, [2014-12-04T15:12:39.976930 #86734]  INFO -- : EZID MINT ark:/99999/fk4 -- success: ark:/99999/fk4n58pc0r
I, [2014-12-04T15:12:40.693256 #86734]  INFO -- : EZID GET ark:/99999/fk4n58pc0r -- success: ark:/99999/fk4n58pc0r
=> #<Ezid::Identifier id="ark:/99999/fk4n58pc0r" status="reserved" target="http://ezid.cdlib.org/id/ark:/99999/fk4n58pc0r" created="2014-12-04 20:12:39 UTC">
>> identifier.delete
I, [2014-12-04T15:12:48.853964 #86734]  INFO -- : EZID DELETE ark:/99999/fk4n58pc0r -- success: ark:/99999/fk4n58pc0r
=> #<Ezid::Identifier id="ark:/99999/fk4n58pc0r" DELETED>
```

## Metadata handling

Although "EZID imposes no requirements on the presence or form of citation metadata"[*](http://ezid.cdlib.org/doc/apidoc.html#metadata-requirements-mapping), `ezid-client` is intended to support the EZID [reserved metadata elements](http://ezid.cdlib.org/doc/apidoc.html#internal-metadata) and [metadata profiles](http://ezid.cdlib.org/doc/apidoc.html#metadata-profiles). While it is possible to use the client to send and receive any metadata, the object methods are geared towards the defined elements.  Therefore it was seen fit, for example, to map the method `Ezid::Identifier#status` to the `_status` element.  Likewise, all the reserved elements, except for `_crossref`, have readers and -- for user-writable elements -- writers without the leading underscores.  Since there are both `_crossref` and `crossref` elements, their accessors match the elements names.  Similarly, accessors for metadata profile elements use underscores in place of dots -- for example, `Ezid::Identifer#dc_title` and `#dc_title=` for the `dc.title` element.

**Setting default metadata values**

Default metadata values can be set:

```ruby
Ezid::Client.configure do |config|
  # set multiple defaults with a hash
  config.identifier.defaults = {status: "reserved", profile: "dc"}
  # or set individual elements
  config.identifier.defaults[:status] = "reserved"
  config.identifier.defaults[:profile] = "dc"
end
```

Then new identifiers will receive the defaults:

```ruby
>> identifier = Ezid::Identifier.create(shoulder: "ark:/99999/fk4")
I, [2014-12-09T11:38:37.335136 #32279]  INFO -- : EZID MINT ark:/99999/fk4 -- success: ark:/99999/fk4zs2w500
I, [2014-12-09T11:38:38.153546 #32279]  INFO -- : EZID GET ark:/99999/fk4zs2w500 -- success: ark:/99999/fk4zs2w500
=> #<Ezid::Identifier id="ark:/99999/fk4zs2w500" status="reserved" target="http://ezid.cdlib.org/id/ark:/99999/fk4zs2w500" created="2014-12-09 16:38:38 UTC">
>> identifier.profile
=> "dc"
>> identifier.status
=> "reserved"
```

## Authentication

Credentials can be provided in any -- or a combination -- of these ways:

- Environment variables:

```sh
export EZID_USER="eziduser"
export EZID_PASSWORD="ezidpass"
```

- Client configuration:

```ruby
Ezid::Client.configure do |config|
  config.user = "eziduser"
  config.password = "ezidpass"
end
```

- At client initialization (only if explicitly instantiating `Ezid::Client`):

```ruby
client = Ezid::Client.new(user: "eziduser", password: "ezidpass")
```

## Alternate Host and Disabling SSL

By default `Ezid::Client` connects over SSL to the EZID host at [ezid.cdlib.org](http://ezid.cdlib.org), but the host and SSL settings may be overridden:

- By environment variables:

```sh
export EZID_HOST="localhost"
export EZID_USE_SSL="false" # "false" disables SSL for all requests
```

- Client configuration:

```ruby
Ezid::Client.configure do |config|
  config.host = "localhost"
  config.use_ssl = false
end
```

- At client initialization (only if explicitly instantiating `Ezid::Client`):

```ruby
client = Ezid::Client.new(host: "localhost", use_ssl: false)
```

## Test Helper

If you have tests that (directly or indirectly) use `ezid-client` you may want to require the test helper module:

```ruby
require "ezid/test_helper"
```

The module provides constants:

- `TEST_ARK_SHOULDER` => "ark:/99999/fk4"
- `TEST_DOI_SHOULDER` => "doi:10.5072/FK2"
- `TEST_USER` => "apitest"
- `TEST_HOST` => "ezid.cdlib.org"

The test user password is not provided - contact EZID and configure as above - or use your own EZID credentials, since all accounts can mint/create on the test shoulders.

A convenience method `ezid_test_mode!` is provided to configure the client to:

- authenticate as `TEST_USER`
- use `TEST_HOST` as the host
- use `TEST_ARK_SHOULDER` as the default shoulder
- log to the null device (instead of default STDERR)

## Running the ezid-client tests

See http://ezid.cdlib.org/doc/apidoc.html#testing-the-api.

In order to run the integration tests successfully, you must supply the password for the test account "apitest" (contact EZID).  To run the test suite without the integration tests, use the `rake ci` task.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/ezid-client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
