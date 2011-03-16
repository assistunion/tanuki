$:.unshift File.expand_path('../lib', __FILE__)
require 'bundler'
Bundler.setup
require 'tanuki'
run Tanuki::Application.build(self)
