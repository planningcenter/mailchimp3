require 'oauth2'
require 'json'

module MailChimp3
  class OAuth
    def initialize
      @oauth = OAuth2::Client.new(
        MailChimp3.config.client_id,
        MailChimp3.config.client_secret,
        site: 'https://login.mailchimp.com',
        authorize_url: '/oauth2/authorize',
        token_url: '/oauth2/token'
      )
    end

    def authorize_url(redirect_uri:, state: nil)
      params = {
        redirect_uri: redirect_uri,
        state: state,
      }.compact

      @oauth.auth_code.authorize_url(params)
    end

    def complete_auth(code, redirect_uri:)
      token = @oauth.auth_code.get_token(
        code,
        redirect_uri: redirect_uri
      )
      {
        token: token,
        token_string: token.token,
        metadata: metadata(token)
      }
    end

    private

    def metadata(token)
      JSON.parse(token.get('/oauth2/metadata').body).tap do |hash|
        hash.keys.each do |key|
          hash[key.to_sym] = hash.delete(key)
        end
      end
    end
  end
end
