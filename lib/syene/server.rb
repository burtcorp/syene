require 'sinatra'
require 'json'
require 'mongo'
require 'geoip'
require 'syene/lookup'


module Syene
  class Server < Sinatra::Base
    configure do
      enable :raise_errors
      set :app_file, __FILE__
      set :lookup, lambda { lookup }
    end

    configure do
      if defined?(PhusionPassenger)
        PhusionPassenger.on_event(:starting_worker_process) do |forked|
          reconnect if forked
        end
      end
    end

    helpers do
    end

    before do
      content_type :json
    end
    
    get '/cities' do
      if params[:ip]
        result = settings.lookup.ip_lookup(params[:ip])
        if result
          result.delete(:_id)
          result.to_json
        else
          status 404
        end
      else
        status 400
      end
    end
    
  private
  
    def self.lookup
      @lookup ||= begin
        cities_collection = Mongo::Connection.new.db('geo').collection('cities')
        geo_ip = GeoIP::City.new(File.expand_path('../../../tmp/GeoLiteCity.dat', __FILE__))
        Lookup.new(:collection => cities_collection, :geo_ip => geo_ip)
      end
    end
    
    def self.reconnect
      @lookup = nil
    end
  end
end