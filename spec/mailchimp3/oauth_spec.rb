require_relative '../spec_helper'

MailChimp3.config.client_id = 'foo'
MailChimp3.config.client_secret = 'bar'

describe MailChimp3::OAuth do
  subject { MailChimp3.oauth }

  describe '#authorize_url' do
    it 'returns the authorization url' do
      url = subject.authorize_url(
        redirect_uri: 'http://example.com/oauth/callback'
      )
      expect(url).to eq('https://login.mailchimp.com/oauth2/authorize?client_id=foo&redirect_uri=http%3A%2F%2Fexample.com%2Foauth%2Fcallback&response_type=code')
    end
  end

  describe '#complete_auth' do
    before do
      stub_request(:post, 'https://login.mailchimp.com/oauth2/token')
        .with(body: {
          'client_id'     => 'foo',
          'client_secret' => 'bar',
          'code'          => '1234567890',
          'grant_type'    => 'authorization_code',
          'redirect_uri'  => 'http://example.com/oauth/callback'
        })
        .to_return(
          status: 200,
          body: {
            access_token: '925680f04933b28f128d721fdf8949fa',
            expires_in: 0,
            scope: nil
          }.to_json,
          headers: {
            'Content-Type' => 'application/json'
          }
        )
        stub_request(:get, 'https://login.mailchimp.com/oauth2/metadata')
          .with(headers: {
            'Authorization' => 'Bearer 925680f04933b28f128d721fdf8949fa'
          })
          .to_return(
            status: 200,
            body: {
              dc: 'us2',
              role: 'owner',
              accountname: 'timmorgan',
              user_id: 2472146,
              login: {
                email: 'tim@timmorgan.org',
                avatar: nil,
                login_id: 2472146,
                login_name: 'timmorgan',
                login_email:'tim@timmorgan.org'
              },
              login_url: 'https://login.mailchimp.com',
              api_endpoint: 'https://us2.api.mailchimp.com'
            }.to_json)
    end

    it 'stores the auth token and metadata' do
      url = subject.authorize_url(
        redirect_uri: 'http://example.com/oauth/callback'
      )
      hash = subject.complete_auth(
        '1234567890',
        redirect_uri: 'http://example.com/oauth/callback'
      )
      expect(hash[:token]).to be_an(OAuth2::AccessToken)
      expect(hash[:token_string]).to eq('925680f04933b28f128d721fdf8949fa')
      expect(hash[:metadata]).to be_a(Hash)
      expect(hash[:metadata][:dc]).to eq('us2')
    end
  end
end
