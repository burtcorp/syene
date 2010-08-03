$: << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

unless defined?(Bundler)
  require 'rubygems'
  require 'bundler'
end

Bundler.setup

require 'syene/updater'