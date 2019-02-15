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
  end

  context 'GET /*' do
    it 'should return a 200 code' do
      response = server.get('/')
      expect(response.status).to be 200
    end
  end
end
