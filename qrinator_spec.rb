require 'simplecov'
SimpleCov.start

require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.require(:default, :test)

require 'rspec'
require 'rack'
require_relative 'qrinator'

describe 'Qrinator' do
  let(:base_url) { 'https://github.com' }
  let(:logo_url) { 'https://github.githubassets.com/images/modules/logos_page/Octocat.png' }
  let(:size) { 384 }
  let(:qrinator) { Qrinator.new(base_url, logo_url, size) }
  let(:server) { Rack::MockRequest.new(qrinator) }

  describe 'internals' do
    it 'should have offset size/3' do
      expect(qrinator.offset).to be 128
    end

    it 'should have inset size/3' do
      expect(qrinator.offset).to be 128
    end

    describe 'payload' do
      it 'should return the original url for empty payload' do
        expect(qrinator.url('')).to eq base_url
      end

      it 'should append the payload to the base url' do
        expect(qrinator.url('/stephancom/qrinator')).to eq 'https://github.com/stephancom/qrinator'
      end

      it 'should include a / if the payload lacks it' do
        expect(qrinator.url('stephancom/qrinator')).to eq 'https://github.com/stephancom/qrinator'
      end

      describe 'with / at end of base_url' do
        let(:base_url) { 'https://github.com/' }

        it 'should append the payload to the base url' do
          expect(qrinator.url('/stephancom/qrinator')).to eq 'https://github.com/stephancom/qrinator'
        end

        it 'should include a / if the payload lacks it' do
          expect(qrinator.url('stephancom/qrinator')).to eq 'https://github.com/stephancom/qrinator'
        end
      end
    end

    # note: these are unused by default, but can be easily enabled
    # this is a bit cargo-cult, these may not all be needed
    describe 'download headers' do
      subject(:headers) { qrinator.download_headers }

      it { is_expected.to match(a_hash_including('Content-Type' => 'application/octet-stream')) }
      it { is_expected.to match(a_hash_including('Pragma' => 'public')) }
      it { is_expected.to match(a_hash_including('Expires' => '0')) }
      it { is_expected.to match(a_hash_including('Cache-Control' => 'must-revalidate, post-check=0, pre-check=0')) }
      it { is_expected.to match(a_hash_including('Content-Type' => 'application/octet-stream')) }
      it { is_expected.to match(a_hash_including('Content-Disposition' => 'attachment;filename=qrcode.png')) }
      it { is_expected.to match(a_hash_including('Content-Transfer-Encoding' => 'binary')) }
    end

    describe 'redis_params' do
      let(:rediscloud_url) { 'redis://rediscloud:somerandomkey@some.redislabs.url.example.com:58008' }
      before do
        ENV['REDISCLOUD_URL'] = rediscloud_url
      end

      it 'should parse the host' do
        expect(qrinator.redis_params).to match(a_hash_including(host: 'some.redislabs.url.example.com'))
      end

      it 'should parse the port' do
        expect(qrinator.redis_params).to match(a_hash_including(port: 58008))
      end

      it 'should parse the password' do
        expect(qrinator.redis_params).to match(a_hash_including(password: 'somerandomkey'))
      end
    end
  end

  describe 'GET /*' do
    it 'should return a 200 code' do
      response = server.get('/')
      expect(response.status).to eq 200
    end

    it 'should return the right content-type' do
      response = server.get('/')
      expect(response.headers).to match(a_hash_including('Content-Type' => 'image/png'))
    end

    pending 'redis'
  end

  describe 'DELETE /*' do
    pending 'with redis'

    describe 'without redis' do
      it 'should return a 405 code' do
        response = server.delete('/')
        expect(response.status).to eq 405
      end
    end
  end
end
