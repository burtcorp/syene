require 'syene/updater'
require 'mongo'


desc 'Download and import the latest city dump from GeoNames'
task :default do
  cities_url = 'http://download.geonames.org/export/dump/cities1000.zip'
  cities_collection = Mongo::Connection.new.db('geo').collection('cities')
  cities_collection.create_index([['location', Mongo::GEO2D]])
  
  Syene::Updater.new(:url => cities_url, :collection => cities_collection).update!
end

desc 'Download the latest GeoIP lite database'
task :geoip do
  url = 'http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz'
  command = %(curl --silent #{url} | gzip -d > tmp/GeoLiteCity.dat)
  system command
end