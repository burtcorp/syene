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
      case city_request_type(params)
      when :ip
        result = settings.lookup.ip_lookup(params[:ip])
      when :position
        begin
          result = settings.lookup.position_lookup(params[:latitude], params[:longitude])
        rescue ArgumentError => e
          throw :halt, [400, {:error => 'Bad Request', :message => e.message}.to_json]
        end
      else
        throw :halt, [400, {:error => 'Bad Request', :message => 'Neither position or IP given'}.to_json]
      end
      
      if result
        result.delete(:_id)
        result.to_json
      else
        status 404
        {:error => 'Not Found', :message => 'No city found'}.to_json
      end
    end
    
  private
  
    def city_request_type(params)
      if params[:latitude] && params[:longitude]
        :position
      elsif params[:ip]
        :ip
      else
        nil
      end
    end
  
    def self.lookup
      @lookup ||= begin
        cities_collection = Mongo::Connection.new.db('geo').collection('cities')
        geo_ip = GeoIP::City.new(File.expand_path('../../../tmp/GeoIPCity.dat', __FILE__))
        Lookup.new(:collection => cities_collection, :geo_ip => geo_ip)
      end
    end
    
    def self.reconnect
      @lookup = nil
    end
  end
end