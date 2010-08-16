
module Syene
  class GeoNamesRow < ImmutableStruct.new(
    :geonameid,        # integer id of record in geonames database
    :name,             # name of geographical point (utf8) varchar(200)
    :asciiname,        # name of geographical point in plain ascii characters, varchar(200)
    :alternatenames,   # alternatenames, comma separated varchar(5000)
    :latitude,         # latitude in decimal degrees (wgs84)
    :longitude,        # longitude in decimal degrees (wgs84)
    :feature_class,    # see http://www.geonames.org/export/codes.html, char(1)
    :feature_code,     # see http://www.geonames.org/export/codes.html, varchar(10)
    :country_code,     # ISO-3166 2-letter country code, 2 characters
    :cc2,              # alternate country codes, comma separated, ISO-3166 2-letter country code, 60 characters
    :admin1_code,      # fipscode (subject to change to iso code), see exceptions below, see file admin1Codes.txt for display names of this code; varchar(20)
    :admin2_code,      # code for the second administrative division, a county in the US, see file admin2Codes.txt; varchar(80) 
    :admin3_code,      # code for third level administrative division, varchar(20)
    :admin4_code,      # code for fourth level administrative division, varchar(20)
    :population,       # bigint (8 byte int) 
    :elevation,        # in meters, integer
    :gtopo30,          # average elevation of 30'x30' (ca 900mx900m) area in meters, integer
    :timezone,         # the timezone id (see file timeZone.txt)
    :modification_date # date of last modification in yyyy-MM-dd format
  )

    def location
      [self[:latitude].to_f, self[:longitude].to_f]
    end

    def population
      self[:population].to_i
    end

    def to_city
      City.new(self.to_h.merge(
        :_id        => self[:geonameid],
        :location   => location, 
        :population => population,
        :ascii_name => self[:asciiname]
      ))
    end
    
    def to_airport
      Airport.new(self.to_h.merge(
        :_id        => self[:geonameid],
        :location   => location,
        :ascii_name => self[:asciiname]
      ))
    end
    
    def self.parse(filename)
      File.open(filename, 'r') do |geo_file|
        geo_file.each_line do |line|
          yield GeoNamesRow.new(*line.chomp.split("\t"))
        end
      end
    end
  end
end