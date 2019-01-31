#   ____  _____  _             _
#  / __ \|  __ \(_)        by | | stephan.com
# | |  | | |__) |_ _ __   __ _| |_ ___  _ __
# | |  | |  _  /| | '_ \ / _` | __/ _ \| '__|
# | |__| | | \ \| | | | | (_| | || (_) | |
#  \___\_\_|  \_\_|_| |_|\__,_|\__\___/|_|

require 'net/http'

configure :development, :test do
  Dotenv.require_keys('BASE_URL')
  Dotenv.load
end

def redis_set_unless_exists(key)
  if settings.redis.exists(key)
    settings.redis.get(key)
  else
    result = yield(key)
    settings.redis.set(key, result)
    result
  end
end

configure do
  params = {}
  unless ENV['REDISCLOUD_URL'].nil?
    uri = URI.parse(ENV['REDISCLOUD_URL'])
    params = params.merge(
      host: uri.host,
      port: uri.port,
      password: uri.password
    )
  end
  set :redis, Redis.new(params)

  size = ENV['SIZE'].to_i
  size = 384 if size.zero?
  set :size, size
  set :offset, size / 3
  set :inset, size / 3
  set :base_url, ENV['BASE_URL']

  logo = redis_set_unless_exists(ENV['LOGO_URL']) do |url|
    Net::HTTP.get(URI(url))
  end
  set :logo, (proc { ChunkyPNG::Image.from_blob(logo).resize(inset, inset) })
end

get '/*' do
  payload = params[:splat].join
  url = settings.base_url + '/' + payload

  content_type 'image/png'
  # If you prefer the image to be downloadable vs included on the page
  # comment out the above content_type line and uncomment the following:
  #
  # headers \
  #   'Pragma' => 'public',
  #   'Expires' => '0',
  #   'Cache-Control' => 'must-revalidate, post-check=0, pre-check=0',
  #   'Content-Type' => 'application/octet-stream',
  #   'Content-Disposition' => 'attachment;filename=qrcode.png',
  #   'Content-Transfer-Encoding' => 'binary'

  redis_set_unless_exists(payload) do
    RQRCode::QRCode.new(url, level: :h).to_img
                   .resize(settings.size, settings.size)
                   .compose(settings.logo, settings.offset, settings.offset)
                   .to_blob
  end
end
