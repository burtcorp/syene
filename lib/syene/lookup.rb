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
        
        city = position_lookup(*location)
        
        if city
          # fall back on the GeoIP region and country name if necessary
          city[:region]       ||= geo_ip_result[:region]
          city[:country_name] ||= geo_ip_result[:country_name]
        end
        
        city
      else
        nil
      end
    end

    def position_lookup(*location)
      city = symbolize_keys(@collection.find_one(:location => {'$near' => clean_position(*location)}))
      city[:location] = location if city
      city
    end
    
  private
    
    def clean_position(lat, lng)
      [clean_numeric(lat), clean_numeric(lng)]
    end
    
    def clean_numeric(n)
      if Numeric === n
        n
      elsif /^([\d.]+)$/ === n.to_s.strip
        n.to_f
      else
        raise ArgumentError, "Not numeric: #{n}"
      end
    end
  end
end