require 'open-uri'
require 'tmpdir'
require 'zipruby'
require 'fileutils'
require 'immutable_struct'


module Syene
  class Updater
    def initialize(options={})
      @downloader = options[:downloader] || Downloader.new
      @tmp_dir    = options[:tmp_dir] || Dir.tmpdir
      @url        = options[:url]
      @collection = options[:collection]
    end

    def update!
      @files = []
      
      download_archive
      extract_archive
      update_cities
    end
    
    def clean!
      @files.each do |path|
        FileUtils.rm_rf(path)
      end
    end
    
  private
  
    def archive_path
      @archive_path ||= File.join(@tmp_dir, File.basename(@url))
    end
    
    def cities_db_path
      @cities_db_path ||= archive_path.sub('.zip', '.txt')
    end
  
    def download_archive
      @downloader.open(@url) do |input|
        File.open(archive_path, 'w') do |output|
          while bytes = input.read(2**16)
            output.write(bytes)
          end
        end
      end
      
      @files << archive_path
    end
    
    def extract_archive
      Zip::Archive.open(archive_path) do |archive|
        archive.each do |entry|
          if entry.directory?
            dirname = File.join(@tmp_dir, entry.name)
            FileUtils.mkdir_p(dirname)
            @files << dirname
          else
            dirname = File.join(@tmp_dir, File.dirname(entry.name))
            filename = File.join(dirname, entry.name)
            FileUtils.mkdir_p(dirname)
            File.open(filename, 'wb') do |f|
              f.write(entry.read)
            end
            @files << filename
          end
        end
      end
    end
    
    def each_city(io)
      io.each_line do |line|
        yield GeoNamesRow.new(*line.chomp.split("\t")).to_city
      end
    end
    
    def update_cities
      File.open(cities_db_path, 'r') do |cities_file|
        each_city(cities_file) do |city|
          @collection.save(city.to_h)
        end
      end
    end
  end
  
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
  end

  class City < ImmutableStruct.new(
    :_id,
    :name,
    :ascii_name,
    :location,
    :population,
    :country_code
  )
  end
  
  class Downloader
    def open(url)
      yield Kernel.open(url)
    end
  end
end