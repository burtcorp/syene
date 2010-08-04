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
        symbolize_keys(@collection.find_one(:location => {'$near' => [geo_ip_result[:latitude], geo_ip_result[:longitude]]}))
      else
        nil
      end
    end
  end
end