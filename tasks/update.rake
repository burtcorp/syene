require 'syene/updater'
require 'mongo'


task :default do
  cities_url = 'http://download.geonames.org/export/dump/cities1000.zip'
  cities_collection = Mongo::Connection.new.db('geo').collection('cities')
  cities_collection.create_index([['location', Mongo::GEO2D]])
  
  Syene::Importer.new(:url => cities_url, :collection => cities_collection).import!
end