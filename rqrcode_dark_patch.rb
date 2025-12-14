# rqrcode_png 0.1.5 expects RQRCode::QRCode#dark?(x, y)
# Newer rqrcode exposes a modules matrix instead.
module RQRCode
  class QRCode
    def dark?(x, y)
      modules[y][x]
    end
  end
end
