module Syene
  class Lookup
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
    
  private
  
    def symbolize_keys(h)
      return h unless h.is_a?(Hash)
      h.keys.inject({}) do |acc, k|
        acc[k.to_sym] = symbolize_keys(h[k])
        acc
      end
    end
  end
end