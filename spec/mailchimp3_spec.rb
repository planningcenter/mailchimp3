require_relative 'spec_helper'

describe MailChimp3 do
  describe '#config' do
    it 'returns configuration object' do
      subject.config.client_id = 'foo'
      subject.config.client_secret = 'bar'
      expect(subject.config.client_id).to eq('foo')
      expect(subject.config.client_secret).to eq('bar')
    end
  end

  describe '#oauth' do
    it 'returns a MailChimp3::OAuth instance' do
      expect(subject.oauth).to be_a(MailChimp3::OAuth)
    end
  end
end
