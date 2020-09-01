# typed: true
require 'net/http'

#   ____  _____  _             _
#  / __ \|  __ \(_)        by | | stephan.com
# | |  | | |__) |_ _ __   __ _| |_ ___  _ __
# | |  | |  _  /| | '_ \ / _` | __/ _ \| '__|
# | |__| | | \ \| | | | | (_| | || (_) | |
#  \___\_\_|  \_\_|_| |_|\__,_|\__\___/|_|
class Qrinator
  attr_reader :size
  def initialize(base_url, logo_url, size)
    @base_url = base_url
    @logo_url = logo_url
    @size = size.to_i
    @offset = @size / 3
    @inset = @size / 3
  end

  def redis_params
    return {} if ENV['REDISCLOUD_URL'].nil?

    uri = URI.parse(T.must(ENV['REDISCLOUD_URL']))
    { host: uri.host, port: uri.port, password: uri.password }
  end

  def redis
    @redis ||= Redis.new(redis_params)
  end

  def redis_set_unless_exists(key)
    if redis.exists(key)
      redis.get(key)
    else
      result = yield(key)
      redis.set(key, result)
      result
    end
  rescue Redis::CannotConnectError
    yield(key)
  end

  def raw_logo_data
    redis_set_unless_exists(@logo_url) do |lurl|
      Net::HTTP.get(URI(lurl))
    end
  end

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

  def headers
    { 'Content-Type' => 'image/png' }
  end

  def offset
    @size / 3
  end

  def inset
    @size / 3
  end

  def logo
    @logo ||= ChunkyPNG::Image.from_blob(raw_logo_data).resize(inset, inset)
  end

  def url(payload)
    URI.join(@base_url, CGI.unescape(payload)).to_s
  end

  def qr(payload)
    redis_set_unless_exists(payload) do
      RQRCode::QRCode.new(url(payload), level: :h).to_img
                     .resize(size, size)
                     .compose(logo, offset, offset)
                     .to_blob
    end
  end

  def call(env)
    if env['REQUEST_METHOD'] == 'DELETE'
      begin
        redis.flushall
        [202, {}, []]
      rescue Redis::CannotConnectError
        [405, {}, ['no redis']]
      end
    else
      [200, headers, StringIO.new(qr(env['PATH_INFO']))]
    end
  end
end
