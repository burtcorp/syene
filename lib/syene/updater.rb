require 'open-uri'
require 'tmpdir'
require 'zipruby'
require 'fileutils'
require 'immutable_struct'
require 'syene/city'
require 'syene/airport'
require 'syene/geo_names_row'
require 'syene/utils'


module Syene
  class Updater
    include Utils
    def initialize(options={})
      @downloader = options[:downloader] || Downloader.new
      @tmp_dir    = options[:tmp_dir] || Dir.tmpdir
      @url        = options[:url]
      @collection = options[:collection]
      @target     = options[:target]
      @archive_path = File.join(@tmp_dir, File.basename(@url))
      @target_db_path = @archive_path.sub('.zip', '.txt')
    end

    def update!
      @files = []
      @files << download_archive(@downloader, @url, @archive_path)
      @files += extract_archive(@archive_path, @tmp_dir)
      
      self.send(@target)
    end
    
    def clean!
      @files.each do |path|
        FileUtils.rm_rf(path)
      end
    end
    
  private
    
    def cities
      GeoNamesRow.parse(@target_db_path) do |row|
        @collection.save(row.to_city.to_h) unless row.feature_code == 'PPLX'
      end
    end
    
    def airports
      GeoNamesRow.parse(@target_db_path) do |row|
        if row[:feature_class] == 'S' && row[:feature_code] == 'AIRP' then
          @collection.save(row.to_airport.to_h)
        end
      end
    end
  end
  
  class Downloader
    def open(url)
      yield Kernel.open(url)
    end
  end
end