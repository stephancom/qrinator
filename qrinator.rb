# typed: strict
require 'net/http'

#   ____  _____  _             _
#  / __ \|  __ \(_)        by | | stephan.com
# | |  | | |__) |_ _ __   __ _| |_ ___  _ __
# | |  | |  _  /| | '_ \ / _` | __/ _ \| '__|
# | |__| | | \ \| | | | | (_| | || (_) | |
#  \___\_\_|  \_\_|_| |_|\__,_|\__\___/|_|
class Qrinator
  extend T::Sig

  sig {returns(Integer)}
  attr_reader :size

  sig {params(base_url: String, logo_url: String, size: Integer).void}
  def initialize(base_url, logo_url, size)
    @base_url = T.let(base_url, String)
    @logo_url = T.let(logo_url, String)
    @size = T.let(size.to_i, Integer)
    @offset = T.let(@size / 3, Integer)
    @inset = T.let(@size / 3, Integer)
  end

  sig {returns(T::Hash[Symbol, T.untyped])}
  def redis_params
    return {} if ENV['REDISCLOUD_URL'].nil?

    uri = URI.parse(T.must(ENV['REDISCLOUD_URL']))
    { host: uri.host, port: uri.port, password: uri.password }
  end

  sig {returns(T.nilable(Redis))}
  def redis
    @redis ||= T.let(Redis.new(redis_params), T.nilable(Redis))
  end

  sig {params(key: String, blk: T.proc.params(k: String).returns(T.untyped)).returns(String)}
  def redis_set_unless_exists(key, &blk)
    if T.must(redis).exists(key)
      T.must(redis).get(key)
    else
      result = yield(key)
      T.must(redis).set(key, result)
      result
    end
  rescue Redis::CannotConnectError
    yield(key)
  end

  sig {returns(String)}
  def raw_logo_data
    redis_set_unless_exists(@logo_url) do |lurl|
      Net::HTTP.get(URI(lurl))
    end
  end

  sig {returns(T::Hash[String, String])}
  def download_headers
    {
      'Pragma' => 'public',
      'Expires' => '0',
      'Cache-Control' => 'must-revalidate, post-check=0, pre-check=0',
      'Content-Type' => 'application/octet-stream',
      'Content-Disposition' => 'attachment;filename=qrcode.png',
      'Content-Transfer-Encoding' => 'binary'
    }
  end

  sig {returns(T::Hash[T.untyped, T.untyped])}
  def headers
    { 'Content-Type' => 'image/png' }
  end

  sig {returns(Integer)}
  def offset
    @size / 3
  end

  sig {returns(Integer)}
  def inset
    @size / 3
  end

  sig {returns(T.nilable(String))}
  def logo
    @logo ||= T.let(ChunkyPNG::Image.from_blob(raw_logo_data).resize(inset, inset), T.nilable(String))
  end

  sig {params(payload: String).returns(String)}
  def url(payload)
    URI.join(@base_url, CGI.unescape(payload)).to_s
  end

  sig {params(payload: String).returns(String)}
  def qr(payload)
    redis_set_unless_exists(payload) do
      RQRCode::QRCode.new(url(payload), level: :h).to_img
                     .resize(size, size)
                     .compose(logo, offset, offset)
                     .to_blob
    end
  end

  sig {params(env: T.untyped).returns(T::Array[T.untyped])}
  def call(env)
    if env['REQUEST_METHOD'] == 'DELETE'
      begin
        T.must(redis).flushall
        [202, {}, []]
      rescue Redis::CannotConnectError
        [405, {}, ['no redis']]
      end
    else
      [200, headers, StringIO.new(qr(env['PATH_INFO']))]
    end
  end
end
