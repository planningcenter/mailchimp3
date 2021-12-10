$:.push File.expand_path('../lib', __FILE__)

require 'mailchimp3/version'

Gem::Specification.new do |s|
  s.name        = "mailchimp3"
  s.version     = MailChimp3::VERSION
  s.homepage    = "https://github.com/seven1m/mailchimp3"
  s.summary     = "wrapper for MailChimp's 3.0 API"
  s.description = "mailchimp3 is a gem for working with MailChimp's RESTful JSON API documented at http://kb.mailchimp.com/api/ using HTTP basic auth or OAuth 2.0. This library can talk to any endpoint the API provides, since it is written to build endpoint URLs dynamically using method_missing."
  s.author      = "Tim Morgan"
  s.license     = "MIT"
  s.email       = "tim@timmorgan.org"

  s.required_ruby_version = '>= 2.0.0'

  s.files = Dir["lib/**/*", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "faraday", "~> 1.0"
  s.add_dependency "excon", ">= 0.71.0"
  s.add_dependency "oauth2", "~> 1.2"
  s.add_development_dependency "rspec", "~> 3.2"
  s.add_development_dependency "webmock", "< 4"
  s.add_development_dependency "pry", "~> 0.10"
end
