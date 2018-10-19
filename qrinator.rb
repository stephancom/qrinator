#   ____  _____  _             _
#  / __ \|  __ \(_)        by | | stephan.com
# | |  | | |__) |_ _ __   __ _| |_ ___  _ __
# | |  | |  _  /| | '_ \ / _` | __/ _ \| '__|
# | |__| | | \ \| | | | | (_| | || (_) | |
#  \___\_\_|  \_\_|_| |_|\__,_|\__\___/|_|

require 'sinatra'

SIZE = 384
OFFSET = SIZE / 3
INSET = SIZE / 3
LOGO = ChunkyPNG::Image.from_file('qrlogo.png').resize(INSET, INSET)
BASE_URL = ENV['BASE_URL']

get '/*' do
  content_type 'image/png'
  # If you prefer the image to be downloadable to included on the page
  # comment out the above content_type line and uncomment the following:
  #
  # headers \
  #   'Pragma' => 'public',
  #   'Expires' => '0',
  #   'Cache-Control' => 'must-revalidate, post-check=0, pre-check=0',
  #   'Content-Type' => 'application/octet-stream',
  #   'Content-Disposition' => 'attachment;filename=qrcode.png',
  #   'Content-Transfer-Encoding' => 'binary'

  RQRCode::QRCode.new(BASE_URL + '/' + params[:splat].join, level: :h).to_img
                 .resize(SIZE, SIZE)
                 .compose(LOGO, OFFSET, OFFSET)
                 .to_blob
end
