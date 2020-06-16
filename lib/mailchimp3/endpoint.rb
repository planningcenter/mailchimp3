require 'faraday'
require 'json'

module MailChimp3
  class Endpoint
    attr_reader :url, :last_result

    def initialize(oauth_access_token: nil, basic_auth_key: nil, dc: nil, url: nil, version: 3)
      @oauth_access_token = oauth_access_token
      @basic_auth_key = basic_auth_key
      @dc = dc
      @dc ||= @basic_auth_key.split('-').last if @basic_auth_key
      @url = url || _build_url
      @version = version
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
        body[:apikey] = @oauth_access_token || @basic_auth_key if @version == 2
        req.body = body.to_json
      end
      if @last_result.status == 204
        true
      else
        _build_response(@last_result)
      end
    end

    def patch(body = {})
      @last_result = _connection.patch(@url) do |req|
        req.body = body.to_json
      end
      _build_response(@last_result)
    end

    def put(body = {})
      @last_result = _connection.put(@url) do |req|
        req.body = body.to_json
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

    def v2
      self.class.new(
        url: _build_v2_url,
        basic_auth_key: @basic_auth_key,
        oauth_access_token: @oauth_access_token,
        version: 2
      )
    end

    private

    def _build_response(result)
      body = _parse_body(result)
      case (status = result.status)
      when 200..299
        body
      when 400
        fail Errors::BadRequest, status: status, body: body
      when 401
        fail Errors::Unauthorized, status: status, body: body
      when 403
        fail Errors::Forbidden, status: status, body: body
      when 404
        fail Errors::NotFound, status: status, body: body
      when 405
        fail Errors::MethodNotAllowed, status: status, body: body
      when 422
        fail Errors::UnprocessableEntity, status: status, body: body
      when 400..499
        fail Errors::ClientError, status: status, body: body
      when 500
        fail Errors::InternalServerError, status: status, body: body
      when 500..599
        fail Errors::ServerError, status: status, body: body
      else
        fail "unknown status #{status}"
      end
    end

    def _parse_body(result)
      JSON.parse(result.body)
    rescue JSON::ParserError
      raise Errors::ServerError, status: result.status, body: result.body
    end

    def _build_endpoint(path)
      @cache[path] ||= begin
        self.class.new(
          url: File.join(url, path.to_s),
          basic_auth_key: @basic_auth_key,
          oauth_access_token: @oauth_access_token,
          version: @version
        )
      end
    end

    def _build_url
      "https://#{@dc}.api.mailchimp.com/3.0/"
    end

    def _build_v2_url
      "https://#{@dc}.api.mailchimp.com/2.0/"
    end

    def _connection
      @connection ||= Faraday.new(url: url) do |faraday|
        faraday.adapter :excon
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
