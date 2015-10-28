require_relative '../spec_helper'
require 'json'

describe MailChimp3::Endpoint do
  let(:base) { described_class.new(basic_auth_key: 'key-us2') }

  subject { base }

  describe '#method_missing' do
    before do
      @result = subject.lists
    end

    it 'returns a wrapper object with updated url' do
      expect(@result).to be_a(described_class)
      expect(@result.url).to match(%r{/lists$})
    end
  end

  describe '#[]' do
    before do
      @result = subject.lists[1]
    end

    it 'returns a wrapper object with updated url' do
      expect(@result).to be_a(described_class)
      expect(@result.url).to match(%r{/lists/1$})
    end
  end

  describe '#get' do
    context 'given a good URL' do
      subject { base.lists }

      let(:result) do
        {
          'id'   => 'e8bcf09f6f',
          'name' => 'My List'
        }
      end

      before do
        stub_request(:get, 'https://us2.api.mailchimp.com/3.0/lists')
          .to_return(status: 200, body: { lists: result }.to_json, headers: { 'Content-Type' => 'application/json; charset=utf-8' })
        @result = subject.get
      end

      it 'returns the result of making a GET request to the endpoint' do
        expect(@result).to be_a(Hash)
        expect(@result['lists']).to eq(result)
      end
    end

    context 'given a non-existent URL' do
      subject { base.non_existent }

      let(:result) do
        {
          'status'  => 404,
          'title'  => 'Resource Not Found',
          'detail' => 'The requested resource could not be found.'
        }
      end

      before do
        stub_request(:get, 'https://us2.api.mailchimp.com/3.0/non_existent')
          .to_return(status: 404, body: result.to_json, headers: { 'Content-Type' => 'application/json; charset=utf-8' })
      end

      it 'raises a NotFound error' do
        expect { subject.get }.to raise_error do |error|
          expect(error).to be_a(MailChimp3::Errors::NotFound)
          expect(error.status).to eq(404)
          expect(error.message).to eq('Resource Not Found: The requested resource could not be found.')
          expect(error.details).to eq(
            'status' => 404,
            'title' => 'Resource Not Found',
            'detail' => 'The requested resource could not be found.'
          )
        end
      end
    end

    context 'given a client error' do
      subject { base.error }

      let(:result) do
        {
          'status'  => 400,
          'title' => 'Bad request'
        }
      end

      before do
        stub_request(:get, 'https://us2.api.mailchimp.com/3.0/error')
          .to_return(status: 400, body: result.to_json, headers: { 'Content-Type' => 'application/json; charset=utf-8' })
      end

      it 'raises a ClientError error' do
        expect { subject.get }.to raise_error(MailChimp3::Errors::ClientError)
      end
    end

    context 'given a server error' do
      subject { base.error }

      let(:result) do
        {
          'status'  => 500,
          'title' => 'System error has occurred'
        }
      end

      before do
        stub_request(:get, 'https://us2.api.mailchimp.com/3.0/error')
          .to_return(status: 500, body: result.to_json, headers: { 'Content-Type' => 'application/json; charset=utf-8' })
      end

      it 'raises a ServerError error' do
        expect { subject.get }.to raise_error(MailChimp3::Errors::ServerError)
      end
    end
  end

  describe '#post' do
    subject { base.lists }

    let(:resource) do
      {
        'name' => 'Foo'
      }
    end

    context do
      let(:result) do
        {
          'id'   => 'd3ed40bd7c',
          'name' => 'Foo'
        }
      end

      before do
        stub_request(:post, 'https://us2.api.mailchimp.com/3.0/lists')
          .to_return(status: 201, body: result.to_json, headers: { 'Content-Type' => 'application/json; charset=utf-8' })
        @result = subject.post(resource)
      end

      it 'returns the result of making a POST request to the endpoint' do
        expect(@result).to eq(result)
      end
    end

    context 'when the response is not valid JSON' do
      let(:result) { 'bad' }

      before do
        stub_request(:post, 'https://us2.api.mailchimp.com/3.0/lists')
          .to_return(status: 200, body: result, headers: { 'Content-Type' => 'application/json; charset=utf-8' })
      end

      it 'raises an error' do
        expect { subject.post(resource) }.to raise_error do |error|
          expect(error).to be_a(MailChimp3::Errors::ServerError)
          expect(error.status).to eq(200)
          expect(error.message).to eq('bad')
          expect(error.details).to be_nil
        end
      end
    end
  end

  describe '#patch' do
    subject { base.lists['d3ed40bd7c'] }

    let(:resource) do
      {
        'id'   => 'd3ed40bd7c',
        'name' => 'Foo'
      }
    end

    let(:result) do
      {
        'id'   => 'd3ed40bd7c',
        'name' => 'Foo'
      }
    end

    before do
      stub_request(:patch, 'https://us2.api.mailchimp.com/3.0/lists/d3ed40bd7c')
        .to_return(status: 200, body: result.to_json, headers: { 'Content-Type' => 'application/json; charset=utf-8' })
      @result = subject.patch(resource)
    end

    it 'returns the result of making a PATCH request to the endpoint' do
      expect(@result).to eq(result)
    end
  end

  describe '#delete' do
    subject { base.lists['d3ed40bd7c'] }

    before do
      stub_request(:delete, 'https://us2.api.mailchimp.com/3.0/lists/d3ed40bd7c')
        .to_return(status: 204, body: '')
      @result = subject.delete
    end

    it 'returns true' do
      expect(@result).to eq(true)
    end
  end
end
