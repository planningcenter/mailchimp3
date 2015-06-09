require_relative 'mailchimp3/endpoint'
require_relative 'mailchimp3/errors'

module MailChimp3
  module_function
  def new(*args)
    Endpoint.new(*args)
  end
end
