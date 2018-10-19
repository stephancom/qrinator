source 'https://rubygems.org'
ruby '2.5.1'

gem 'foreman'
gem 'redis'
gem 'sinatra'

gem 'rqrcode_png'

group :development, :test do
  # october 2018, master branch required for require_keys checking
  # https://github.com/bkeepers/dotenv/issues/359
  gem 'dotenv', '~> 2.5.0', github: 'bkeepers/dotenv', branch: :master
  # gem 'dotenv', '~> 2.5.1'
end

group :development do
  gem 'byebug'
  gem 'pry'
  gem 'pry-nav'
  gem 'pry-stack_explorer'
end
