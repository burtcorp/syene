require 'syene/utils'


module Syene
  class Lookup
    include Utils
    
    def initialize(options={})
      @collection = options[:collection]
      @geo_ip     = options[:geo_ip]
    end
    
    def ip_lookup(ip)
      geo_ip_result = @geo_ip.look_up(ip)
      
      if geo_ip_result
        location = [geo_ip_result[:latitude], geo_ip_result[:longitude]]
        
        city = symbolize_keys(@collection.find_one(:location => {'$near' => location}))
        
        if city
          # the GeoIP lat/lng is more accurate
          city[:location] = location

          # fall back on the GeoIP region and country name if necessary
          city[:region]       ||= geo_ip_result[:region]
          city[:country_name] ||= geo_ip_result[:country_name]
        end
        
        city
      else
        nil
      end
    end
  end
end