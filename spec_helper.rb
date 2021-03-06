# typed: strict
require 'simplecov'
SimpleCov.start

require 'rspec/sorbet'
RSpec::Sorbet.allow_doubles!

require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.require(:default, :test)

require 'webmock/rspec'
VCR.configure do |config|
  config.cassette_library_dir = 'vcr_cassettes'
  config.hook_into :webmock
end

require_relative 'qrinator'
