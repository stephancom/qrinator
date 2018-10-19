#!/usr/bin/env rackup

ENV['RACK_ENV'] ||= 'development'

require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.require(:default, ENV['RACK_ENV'].to_sym)

unless settings.production?
  require 'dotenv'
  Dotenv.require_keys('BASE_URL')
  Dotenv.load
end

require './qrinator.rb'

run Sinatra::Application
