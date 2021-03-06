#!/usr/bin/env rackup

ENV['RACK_ENV'] ||= 'development'

require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.require(:default, ENV['RACK_ENV'].to_sym)

require './qrinator.rb'

run Qrinator.new(ENV['BASE_URL'], ENV['LOGO_URL'], ENV['SIZE'])
