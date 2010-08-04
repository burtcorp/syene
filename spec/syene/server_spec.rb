# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)


module Syene
  class Server
    def self.lookup_factory
      @lookup_factory ||= Object.new
    end
  end
  
  describe Server do
    def app
      @app ||= make_app(Server)
    end
    
    before do
      @lookup = mock()
      @lookup.stub(:ip_lookup).and_return({})
      
      Server.set(:lookup, @lookup)
      
      app.stub(:call).and_return { |env| app.call!(env) } # required for stubbing to work
      
      set :environment, :test
      set :run, false
      set :raise_errors, true
      set :logging, false
    end

    it 'responds with OK' do
      get '/cities', :ip => '8.8.8.8'
      last_response.should be_ok
    end
    
    it 'responds with Bad Request if no ip parameter is given' do
      get '/cities'
      last_response.status.should == 400
    end
    
    it 'responds with JSON' do
      get '/cities', :ip => '8.8.8.8'
      last_response.content_type.should == 'application/json'
    end
    
    it 'responds with Not Found if no city can be found' do
      @lookup.stub(:ip_lookup).with('8.8.8.8').and_return(nil)
      get '/cities', :ip => '8.8.8.8'
      last_response.status.should == 404
    end
    
    it 'responds with a city' do
      @lookup.stub(:ip_lookup).with('8.8.8.8').and_return(:name => 'Metropolis')
      get '/cities', :ip => '8.8.8.8'
      last_response.body.should == '{"name":"Metropolis"}'
    end
  end
end
