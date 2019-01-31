<pre>
  ____  _____  _             _             
 / __ \|  __ \(_)        by | | stephan.com           
| |  | | |__) |_ _ __   __ _| |_ ___  _ __ 
| |  | |  _  /| | '_ \ / _` | __/ _ \| '__|
| |__| | | \ \| | | | | (_| | || (_) | |   
 \___\_\_|  \_\_|_| |_|\__,_|\__\___/|_|   
</pre>

# QRinator
> simple branded QR-codes

This implements a simple standalone service in rack to generate QR-codes with a logo in the center.

It is designed to be easily deployed to Heroku, whose free hobby plan will suffice for many uses.  Many improvements and extensions could be made, such as configuration through a UI, etc, but the intent is to keep this simple.  Feel free to fork away.

All text after the root URL is simply copied onto a destination URL, which can be configured in the BASE_URL environment variable; text should be URL encoded.  The logo image is similarly configured with the LOGO_URL environment variable pointing to an url returning a png file.  This image is expected to be a PNG with an alpha channel for transparency, ideally resized to 1/3 the target size.  By default, the SIZE=384 pixels, so the image should be 128x128 pixels, to go on top of a 384x384 QR-code (3 * 128) - but if you set SIZE=192, you would want a 64x64 logo.  It'll work fine if the size is wrong, it just won't look as good.

By way of example, let's say you have this deployed to a heroku server at http://qrinator.stephan.com/, configured with http://stephan.com/ as the root url.  If you then call this with http://qrinator.stephan.com/blog/qrinator, you'll receive back a QR-code with the url http://stephan.com/blog/qrinator with my logo in the center.

If you wish clear the redis cache, send a DELETE request to /

Caveat
------

The fragment identifier (aka hash symbol or octothorpe `#`) and everything after it is not passed to the server, per [RFC 3986](https://tools.ietf.org/html/rfc3986).  For this reason, if you wish to use it in a QR code, eg to deep-link to something handled by a front-end framework, replace it with the url encoding `%23`.

For example, given the above configuration, if you wish the QR code the point to `http://stephan.com/software#examples`, you might generate that with `http://qrinator.stephan.com/software%23examples`

Questionmark, similarly, does the same thing, its url encoding is `%3F`

Example
-------

![https://github.com/stephancom/qrinator](https://s3.amazonaws.com/share.stephan.com/github-stephancom-qrinator.png)

Installation
------------

* clone repository
* copy `example.env` to `.env` and configure as needed
  * BASE_URL
  * LOGO_URL
  * SIZE (optional)
* `bundle`

Deployment
----------

* heroku apps:create your-name-here
* heroku config:set BASE_URL='http://your-url-here.com/'
* heroku config:set LOGO_URL='http://your-url-here.com/path/to/your/logo.png'
* heroku config:set SIZE='384'
* heroku addons:create rediscloud:30
* git push heroku master

Development
-----------

* dotenv start

bonus: use rerun https://github.com/alexch/rerun
* `gem install rerun`
* install additional gems for your platform as recommended (rb-fsevent for OSX)
* `rerun dotenv start`

References
----------
* https://rack.github.io
* https://tools.ietf.org/html/rfc3986
* https://github.com/daddz/sinatra-rspec-bundler-template/
* https://github.com/modernistik/parse-stack-example
