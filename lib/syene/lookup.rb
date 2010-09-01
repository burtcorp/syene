require 'syene/utils'


module Syene
  class Lookup
    include Utils
    
    CITIES_COLLECTION_NAME = 'cities'
    MAX_OVERRIDE_DISTANCE  = 0.06 # more or less arbitrary, it makes Majorna resolve to Göteborg
    
    def initialize(options={})
      @geo_ip = options[:geo_ip]
      @db     = options[:db]
    end
    
    def ip_lookup(ip)
      geo_ip_result = @geo_ip.look_up(clean_ip(ip))
      
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
      location = clean_position(*location)
      
      command_selector = BSON::OrderedHash[:geoNear,CITIES_COLLECTION_NAME,:near,location,:num,3]
      
      response = @db.command(command_selector)
      
      results = if response then response.fetch('results', []) else [] end
      
      if results.empty?
        nil
      else
        if results.size > 1
          results  = results.map { |r| symbolize_keys(r) }
          closest  = results.first
          results  = results.select { |r| (r[:dis] - closest[:dis]).abs < MAX_OVERRIDE_DISTANCE }
          selected = results.sort { |a, b| a[:obj][:population] <=> b[:obj][:population] }.last
        else
          selected = symbolize_keys(results.first)
        end
        city = selected[:obj]
        city[:location] = location
        city
      end
    end
    
  private
  
    def clean_ip(ip)
      ip = ip.strip
      parts = ip.split('.')
      if parts.size == 4
        if private_ip?(*parts)
          raise ArgumentError, "Private or internal IP: #{ip}"
        else
          ip
        end
      else
        raise ArgumentError, "Malformed IP: #{ip}"
      end
    end
    
    def private_ip?(*ip)
      %w(0 10 127).include?(ip.first) ||
      ip[0..1] == %w(192 168) ||
      (ip[0] == '172' && (16..31).include?(ip[1].to_i)) ||
      (ip[0..1] == %w(169 254) && (1..254).include?(ip[2].to_i))
    end
    
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