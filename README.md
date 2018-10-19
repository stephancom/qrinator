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

This implements a simple standalone service in Sinatra to generate QR-codes with a logo in the center.

It is designed to be easily deployed to Heroku, whose free hobby plan will suffice for many uses.  Many improvements and extensions could be made, such as configuration through a UI, etc, but the intent is to keep this simple.  Feel free to fork away.

All text after the root URL is simply copied onto a destination URL, which can be configured in an environment variable.  The logo image is customized in the repo, which seemed to be the most efficient and simplest way to do it.  This image is expected to be a PNG with an alpha channel for transparency, ideally resized to the target size.  In this case, that's 128x128 pixels, to go on top of a 384x384 QR-code (3 * 128) - this can be customized in qrinator.rb.

By way of example, let's say you have this deployed to a heroku server at http://stephancom-qrinator.herokuapp.com/, configured with http://stephan.com/ as the root url.  If you then call this with http://stephancom-qrinator.herokuapp.com/blog/qrinator, you'll receive back a QR-code with the url http://stephan.com/blog/qrinator with my logo in the center.

Caveat
------

The fragment identifier (aka hash symbol or octothorpe `#`) and everything after it is not passed to the server, per [RFC 3986](https://tools.ietf.org/html/rfc3986).  For this reason, if you wish to use it in a QR code, eg to deep-link to something handled by a front-end framework, replace it with the url encoding `%23`.

For example, given the above configuration, if you wish the QR code the point to `http://stephan.com/qr/#/1234/all`, you might generate that with `http://stephancom-qrinator.herokuapp.com/qr/%23/1234/all`

Questionmark, similarly, does the same thing, its url encoding is `%3F`

... really, you should URL encode everything, and this document should be rewritten to reflect that.  Those are the big two, though.

Example
-------

![https://github.com/stephancom/qrinator](https://s3.amazonaws.com/share.stephan.com/github-stephancom-qrinator.png)

Installation
------------

* clone repository
* copy `example.env` to `.env` and configure as needed
* replace `qrlogo.png` with your own logo image
* `bundle`

Deployment
----------

* heroku apps:create your-name-here
* heroku config:set BASE_URL='http://your-url-here.com/'
* heroku addons:create rediscloud:30
* git push heroku master

Development
-----------

* foreman start

bonus: use rerun https://github.com/alexch/rerun
* `gem install rerun`
* install additional gems for your platform as recommended (rb-fsevent for OSX)
* `rerun foreman start`

References
----------
* https://tools.ietf.org/html/rfc3986
* https://github.com/daddz/sinatra-rspec-bundler-template/
* https://github.com/modernistik/parse-stack-example
