require 'faraday'
require 'faraday_middleware'

module MailChimp3
  class Endpoint
    attr_reader :url, :last_result

    def initialize(oauth_access_token: nil, basic_auth_key: nil, dc: nil, url: nil)
      @oauth_access_token = oauth_access_token
      @basic_auth_key = basic_auth_key
      @dc = dc
      @dc ||= @basic_auth_key.split('-').last if @basic_auth_key
      @url = url || _build_url
      fail Errors::DataCenterRequiredError, 'You must pass dc.' unless @dc || @url
      @cache = {}
    end

    def method_missing(method_name, *_args)
      _build_endpoint(method_name.to_s)
    end

    def [](id)
      _build_endpoint(id.to_s)
    end

    def get(params = {})
      @last_result = _connection.get(@url, params)
      _build_response(@last_result)
    end

    def post(body = {})
      @last_result = _connection.post(@url) do |req|
        req.body = _build_body(body)
      end
      _build_response(@last_result)
    end

    def patch(body = {})
      @last_result = _connection.patch(@url) do |req|
        req.body = _build_body(body)
      end
      _build_response(@last_result)
    end

    def delete
      @last_result = _connection.delete(@url)
      if @last_result.status == 204
        true
      else
        _build_response(@last_result)
      end
    end

    private

    def _build_response(result)
      case result.status
      when 200..299
        result.body
      when 400
        fail Errors::BadRequest, result
      when 401
        fail Errors::Unauthorized, result
      when 403
        fail Errors::Forbidden, result
      when 404
        fail Errors::NotFound, result
      when 405
        fail Errors::MethodNotAllowed, result
      when 422
        fail Errors::UnprocessableEntity, result
      when 400..499
        fail Errors::ClientError, result
      when 500
        fail Errors::InternalServerError, result
      when 500..599
        fail Errors::ServerError, result
      else
        fail "unknown status #{result.status}"
      end
    end

    def _build_body(body)
      if _needs_url_encoded?
        Faraday::Utils.build_nested_query(body)
      else
        body.to_json
      end
    end

    def _needs_url_encoded?
      @url =~ /oauth\/[a-z]+\z/
    end

    def _build_endpoint(path)
      @cache[path] ||= begin
        self.class.new(
          url: File.join(url, path.to_s),
          basic_auth_key: @basic_auth_key,
          oauth_access_token: @oauth_access_token
        )
      end
    end

    def _build_url
      "https://#{@dc}.api.mailchimp.com/3.0"
    end

    def _connection
      @connection ||= Faraday.new(url: url) do |faraday|
        faraday.adapter :excon
        faraday.response :json, content_type: /\bjson$/
        if @basic_auth_key
          faraday.basic_auth '', @basic_auth_key
        elsif @oauth_access_token
          faraday.headers['Authorization'] = "Bearer #{@oauth_access_token}"
        else
          fail Errors::AuthRequiredError, "You must specify either HTTP basic auth credentials or an OAuth2 access token."
        end
      end
    end
  end
end
