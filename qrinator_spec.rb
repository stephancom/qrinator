# typed: false
describe 'Qrinator' do
  let(:base_url) { 'https://github.com' }
  let(:logo_url) { 'https://github.githubassets.com/images/modules/logos_page/Octocat.png' }
  let(:size) { 384 }
  let(:qrinator) { Qrinator.new(base_url, logo_url, size) }
  let(:server) { Rack::MockRequest.new(qrinator) }
  around(:each) do |example|
    VCR.use_cassette('octocat') do
      example.run
    end
  end

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

      it 'should handle url encoding' do
        decoded = 'https://github.com/search?q=qrinator&ref=simplesearch#extrastuff'
        encoded = 'search%3Fq%3Dqrinator%26ref%3Dsimplesearch%23extrastuff'
        expect(qrinator.url(encoded)).to eq(decoded)
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
      it { is_expected.to match(a_hash_including('Content-Disposition' => 'attachment;filename=qrcode.png')) }
      it { is_expected.to match(a_hash_including('Content-Transfer-Encoding' => 'binary')) }
    end

    describe 'redis_params' do
      let(:rediscloud_url) { 'redis://rediscloud:somerandomkey@some.redislabs.url.example.com:8008' }
      before do
        ENV['REDISCLOUD_URL'] = rediscloud_url
      end

      it 'should parse the url' do
        expect(qrinator.redis_params).to match(a_hash_including(host: 'some.redislabs.url.example.com', password: 'somerandomkey', port: 8008))
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

    describe 'QR generation' do
      let(:path) { '/some/desired/path.html' }
      let(:png) { instance_double('ChunkyPNG::Image') }
      let(:qrcoder) { instance_double('RQRCode::QRCode', to_img: png) }
      let(:payload) { base_url + path }
      let(:png_blob) { 'the_binary_png_data' }
      before do
        allow(qrinator).to receive(:logo).and_return('the_logo')
        allow(png).to receive(:resize).and_return(png)
        allow(png).to receive(:compose).and_return(png)
        allow(png).to receive(:to_blob).and_return(png_blob)
        allow(RQRCode::QRCode).to receive(:new).and_return(qrcoder)
      end

      it 'generates with the full desired url' do
        expect(RQRCode::QRCode).to receive(:new).with(payload, a_hash_including).and_return(qrcoder)
        server.get(path)
      end

      it 'converts the QR to png' do
        expect(qrcoder).to receive(:to_img).and_return(png)
        server.get(path)
      end

      it 'resizes the image' do
        expect(png).to receive(:resize).with(size, size).and_return(png)
        server.get(path)
      end

      it 'composites the logo' do
        expect(qrinator).to receive(:logo).and_return('the_logo')
        expect(png).to receive(:compose).with('the_logo', size / 3, size / 3).and_return(png)
        server.get(path)
      end

      it 'returns the composed QR code in the body' do
        response = server.get(path)
        expect(response.body).to eq(png_blob)
      end

      describe 'with redis' do
        let(:redis) { MockRedis.new }
        before do
          allow(qrinator).to receive(:redis).and_return(redis)
        end

        it 'should check the cache' do
          expect(redis).to receive(:exists).with(path).and_call_original
          server.get(path)
        end

        describe 'when not cached' do
          before do
            allow(redis).to receive(:exists).with(path).and_return(false)
          end

          it 'generates with the full desired url' do
            expect(RQRCode::QRCode).to receive(:new).with(payload, a_hash_including).and_return(qrcoder)
            server.get(path)
          end

          it 'stores the result in the cache' do
            expect(redis).to receive(:set).with(path, png_blob)
            server.get(path)
          end

          it 'returns the composed QR code in the body' do
            response = server.get(path)
            expect(response.body).to eq(png_blob)
          end
        end

        describe 'when cached' do
          before do
            allow(redis).to receive(:exists).with(path).and_return(true)
            allow(redis).to receive(:get).with(path).and_return(png_blob)
          end

          it 'does not generate a qrcode' do
            expect(RQRCode::QRCode).not_to receive(:new)
            server.get(path)
          end

          it 'fetches the result in the cache' do
            expect(redis).to receive(:get).with(path).and_return(png_blob)
            server.get(path)
          end

          it 'returns the cached image in the body' do
            allow(redis).to receive(:get).with(path).and_return('cached qr code')
            response = server.get(path)
            expect(response.body).to eq 'cached qr code'
          end
        end
      end
    end

    describe 'logo' do
      let(:logo_blob) { 'logo_png' }
      let!(:stub_get) { stub_request(:get, logo_url).to_return(body: logo_blob) }
      let(:logo_png) { instance_double('ChunkyPNG::Image') }

      before do
        allow(logo_png).to receive(:resize).and_return(logo_png)
        allow(ChunkyPNG::Image).to receive(:from_blob).and_return(logo_png)
      end

      it 'reads the logo from the internet' do
        qrinator.raw_logo_data
        assert_requested(stub_get)
      end

      it 'converts the raw data to a png' do
        expect(ChunkyPNG::Image).to receive(:from_blob).with(logo_blob).and_return(logo_png)
        expect(qrinator.logo).to be logo_png
      end

      it 'returns the resized logo' do
        resized_logo = instance_double('ChunkyPNG::Image')
        expect(logo_png).to receive(:resize).with(size / 3, size / 3).and_return(resized_logo)
        expect(qrinator.logo).to eq resized_logo
      end

      describe 'with redis' do
        let(:redis) { MockRedis.new }
        before do
          allow(qrinator).to receive(:redis).and_return(redis)
        end

        describe 'when not cached' do
          before do
            allow(redis).to receive(:exists).with(logo_url).and_return(false)
          end

          it 'reads the logo from the internet' do
            qrinator.raw_logo_data
            assert_requested(stub_get)
          end

          it 'stores the result in the cache' do
            expect(redis).to receive(:set).with(logo_url, logo_blob)
            qrinator.raw_logo_data
          end
        end

        describe 'when cached' do
          before do
            allow(redis).to receive(:exists).with(logo_url).and_return(true)
            allow(redis).to receive(:get).with(logo_url).and_return(logo_blob)
          end

          it 'does not read the logo from the internet' do
            qrinator.raw_logo_data
            assert_not_requested(stub_get)
          end

          it 'fetches the result in the cache' do
            expect(redis).to receive(:get).with(logo_url).and_return(logo_blob)
            qrinator.raw_logo_data
          end

          it 'uses the cached logo' do
            allow(redis).to receive(:get).with(logo_url).and_return('cached_logo')
            expect(qrinator.raw_logo_data).to eq 'cached_logo'
          end
        end
      end
    end
  end

  describe 'DELETE /*' do
    describe 'with redis' do
      let(:redis) { MockRedis.new }
      before do
        allow(qrinator).to receive(:redis).and_return(redis)
      end

      it 'should flush the cache' do
        expect(redis).to receive(:flushall)
        server.delete('/')
      end

      it 'returns an empty body and no headers' do
        response = server.delete('/')
        expect(response.body).to be_empty
        expect(response.headers).to be_empty
      end

      it 'returns status Accepted' do
        response = server.delete('/')
        expect(response.status).to eq 202
      end
    end

    describe 'without redis' do
      before do
        allow(Redis).to receive(:new).and_raise(Redis::CannotConnectError)
      end

      it 'returns status Method Not Allowed' do
        response = server.delete('/')
        expect(response.status).to eq 405
      end
    end
  end
end
