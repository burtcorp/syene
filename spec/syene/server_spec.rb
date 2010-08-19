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
      get '/city', :ip => '8.8.8.8'
      last_response.should be_ok
    end
    
    it 'responds with Bad Request if the right parameters aren\'t given' do
      get '/city'
      last_response.status.should == 400
    end

    it 'responds with JSON' do
      get '/city', :ip => '8.8.8.8'
      last_response.content_type.should == 'application/json'
    end
    
    it 'responds with Not Found if no city can be found' do
      @lookup.stub(:ip_lookup).with('8.8.8.8').and_return(nil)
      get '/city', :ip => '8.8.8.8'
      last_response.status.should == 404
    end
    
    it 'responds with a city when given an IP' do
      @lookup.stub(:ip_lookup).with('8.8.8.8').and_return(:name => 'Metropolis')
      get '/city', :ip => '8.8.8.8'
      last_response.body.should == '{"name":"Metropolis"}'
    end

    it 'responds with a city when given a latitude and longitude' do
      @lookup.stub(:position_lookup).with('22.33', '44.55').and_return(:name => 'Metropolis')
      get '/city', :latitude => '22.33', :longitude => '44.55'
      last_response.body.should == '{"name":"Metropolis"}'
    end
    
    it 'responds with Bad Request if a malformed latitude or longitude is given' do
      @lookup.stub(:position_lookup).with('apa', '3.2').and_raise(ArgumentError.new('Bad!'))
      get '/city', :latitude => 'apa', :longitude => '3.2'
      last_response.status.should == 400
    end
  end
end
