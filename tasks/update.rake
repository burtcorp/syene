require 'syene/updater'
require 'mongo'

task :default => [:geo_cities, :geo_airports]

desc 'Download and import the latest city dump from GeoNames'
task :geo_cities do
  cities_url = 'http://download.geonames.org/export/dump/cities1000.zip'
  cities_collection = Mongo::Connection.new.db('geo').collection('cities')
  cities_collection.create_index([['location', Mongo::GEO2D]])
  
  Syene::Updater.new(:url => cities_url, :collection => cities_collection, :target => :cities).update!
end

desc 'Download and import the latest airport dump from GeoNames'
task :geo_airports do
  airports_url = 'http://download.geonames.org/export/dump/allCountries.zip'
  airports_collection = Mongo::Connection.new.db('geo').collection('airports')
  airports_collection.create_index([['location', Mongo::GEO2D]])
  
  Syene::Updater.new(:url => airports_url, :collection => airports_collection, :target => "airports").update!
end

desc 'Download the latest GeoIP lite database'
task :geoip do
  sh 'mkdir -p tmp'
  url = 'http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz'
  command = %(curl --silent #{url} | gzip -d > tmp/GeoLiteCity.dat)
  system command
end