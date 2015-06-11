require_relative 'mailchimp3/endpoint'
require_relative 'mailchimp3/oauth'
require_relative 'mailchimp3/errors'

module MailChimp3
  module_function

  def new(*args)
    Endpoint.new(*args)
  end

  def config
    @config ||= Struct.new(:client_id, :client_secret).new
  end

  def oauth
    @oauth ||= MailChimp3::OAuth.new
  end
end
