source 'https://rubygems.org'
ruby '2.7.1'

gem 'bundler', '~> 2.1.4'
gem 'rack', '~> 2.2.6'
gem 'redis', '~> 4.0.0'
gem 'rqrcode_png', '~> 0.1.0'
gem 'sorbet-runtime', '~> 0.5.0'

group :development do
  gem 'sorbet', '~> 0.5.0'
end

group :development, :test do
  gem 'dotenv', '~> 2.5.0'
  gem 'rubocop', '~> 0.64.0'
end

group :test do
  gem 'mock_redis', '~> 0.19.0'
  gem 'rake', '~> 12.3.3'
  gem 'rspec', '~> 3.8.0'
  gem 'rspec_junit_formatter', '~> 0.4.1'
  gem 'simplecov', '~> 0.16.0', require: false
  gem 'rspec-sorbet'
  gem 'vcr', '~> 4.0.0'
  gem 'webmock', '~> 3.5.0'
end
