$: << File.expand_path('../lib', __FILE__)


ENV['RACK_ENV'] ||= 'development'


unless defined?(Bundler)
  require 'rubygems'
  require 'bundler'
end

Bundler.setup(:default)

require 'fileutils'
require 'syene/server'


unless ENV['RACK_ENV'] == 'development'
  log_path = File.expand_path('../tmp/log/' + ENV['RACK_ENV'] + '.log', __FILE__)
  FileUtils.mkdir_p(File.dirname(log_path))
  log = File.open(log_path, 'a')
  STDOUT.reopen(log)
  STDERR.reopen(log)
end


use Syene::Server
run Sinatra::Application
