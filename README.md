# MailChimp3

[![Circle CI](https://circleci.com/gh/seven1m/mailchimp3/tree/master.svg?style=svg)](https://circleci.com/gh/seven1m/mailchimp3/tree/master)

`mailchimp3` is a Rubygem that provides a very thin, simple wrapper around the MailChimp RESTful JSON API.

## Installation

```
gem install mailchimp3 (eventually)
```

## Usage

1. Create a new API object, passing in your credentials (either HTTP Basic or OAuth2 access token):

    ```ruby
    # authenticate with HTTP Basic:
    api = MailChimp3.new(basic_auth_key: 'my key')
    # ...or authenticate with an OAuth2 access token (use the 'oauth2' gem to obtain the token)
    api = MailChimp3.new(oauth_access_token: 'token')
    ```

2. Call a method on the api object to build the endpoint path.

    ```ruby
    api.lists
    # /lists
    ```

3. For IDs, treat the object like a hash (use square brackets).

    ```ruby
    api.lists['abc123'].members
    # /lists/abc123/members
    ```

4. To execute the request, use `get`, `post`, `patch`, or `delete`, optionally passing arguments.

    ```ruby
    api.lists.get(count: 25)
    # GET /lists?count=25
    api.lists['abc123'].members['cde345'].get
    # GET /lists/abc123/members/cde345
    ```

## Example

```ruby
require 'mailchimp3'

api = MailChimp3.new(basic_auth_key: 'abc123abc123abc123abc123abc123ab-us2')
api.lists.post(
  name: 'Church.IO',
  email_type_option: false,
  permission_reminder: 'signed up on https://church.io'
  contact: {
    company: 'TJRM',
    address1: '123 N. Main',
    city: 'Tulsa',
    state: 'OK',
    zip: '74137',
    country: 'US'
  },
  campaign_defaults: {
    from_name: 'Tim Morgan',
    from_email: 'tim@timmorgan.org',
    subject: 'Hello World',
    language: 'English'
  },
)
```

...which returns something like:

```ruby
{
  "id"   => "abc123abc1",
  "name" => "Church.IO",
  "contact" => {
    "company"  => "TJRM",
    "address1" => "123 N. Main",
    "address2" => "",
    "city"     => "Tulsa",
    "state"    => "OK",
    "zip"      => "74137",
    "country"  => "US",
    "phone"    => ""
  },
  "campaign_defaults" => {
    "from_name"  => "Tim Morgan",
    "from_email" => "tim@timmorgan.org",
    "subject"    => "test",
    "language"   => "English"
  },
  # ...
  "stats" => {
    "member_count" => 0,
    # ...
  },
  "_links" => [
    {
      "rel"          => "self",
      "href"         => "https://us2.api.mailchimp.com/3.0/lists/abc123abc1",
      "method"       => "GET",
      "targetSchema" => "https://us2.api.mailchimp.com/schema/3.0/Lists/Instance.json"
    },
    # ...
  ]
}
```

## get()

`get()` works for a collection (index) and a single resource (show).

```ruby
# collection
api.lists['abc123'].members.get(count: 25)
# => { members: array_of_resources }

# single resource
api.lists['abc123'].members['cde345'].get
# => resource_hash
```

## post()

`post()` sends a POST request to create a new resource.

```ruby
api.lists['abc123'].members.post(...)
# => resource_hash
```

## patch()

`patch()` sends a PATCH request to update an existing resource.

```ruby
api.lists['abc123'].members['cde345'].patch(...)
# => resource_hash
```

## delete()

`delete()` sends a DELETE request to delete an existing resource. This method returns `true` if the delete was successful.

```ruby
api.lists['abc123'].members['cde345'].delete
# => true
```

## Errors

The following errors may be raised by the library, depending on the API response status code.

| HTTP Status Codes   | Error Class                                                                   |
| ------------------- | ----------------------------------------------------------------------------- |
| 400                 | `MailChimp3::Errors::BadRequest` < `MailChimp3::Errors::ClientError`          |
| 401                 | `MailChimp3::Errors::Unauthorized` < `MailChimp3::Errors::ClientError`        |
| 403                 | `MailChimp3::Errors::Forbidden` < `MailChimp3::Errors::ClientError`           |
| 404                 | `MailChimp3::Errors::NotFound` < `MailChimp3::Errors::ClientError`            |
| 405                 | `MailChimp3::Errors::MethodNotAllowed` < `MailChimp3::Errors::ClientError`    |
| 422                 | `MailChimp3::Errors::UnprocessableEntity` < `MailChimp3::Errors::ClientError` |
| other 4xx errors    | `MailChimp3::Errors::ClientError`                                             |
| 500                 | `MailChimp3::Errors::InternalServerError` < `MailChimp3::Errors::ServerError` |
| other 5xx errors    | `MailChimp3::Errors::ServerError`                                             |

The exception object has the following methods:

| Method  | Content                                  |
| ------- | ---------------------------------------- |
| status  | HTTP status code returned by the server  |
| message | the message returned by the API          |
| details | the full response returned by the server |

The `message` should be a simple string given by the API, e.g. "Resource Not Found".

`details` is a Ruby hash containing all the details given by the server, and looks like this:

```ruby
{
  "type"     => "http://kb.mailchimp.com/api/error-docs/400-invalid-resource",
  "title"    => "Invalid Resource",
  "status"   => 400,
  "detail"   => "The resource submitted could not be validated. For field-specific details, see the 'errors' array.",
  "instance" => "286179fe-f3dc-4c03-8c14-1021cf0191a2",
  "errors" => [
    {
      "field"   => "",
      "message" => "Required fields were not provided: permission_reminder, campaign_defaults"
    }
  ]
}
```

Alternatively, you may rescue `MailChimp3::Errors::BaseError` and branch your code based on
the status code returned by calling `error.status`.

## Copyright & License

Copyright 2015, Tim Morgan. Licensed MIT.
