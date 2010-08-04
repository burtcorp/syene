$: << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

unless defined?(Bundler)
  require 'rubygems'
  require 'bundler'
end

Bundler.setup

require 'rack/test'
require 'syene/updater'
require 'syene/lookup'
require 'syene/server'


def make_app(klass)
  app = nil
  klass.new { |a| app = a }
  app
end

Spec::Runner.configure do |conf|
  conf.include(Rack::Test::Methods)
end
