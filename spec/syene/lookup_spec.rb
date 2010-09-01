# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)


module Syene
  describe Lookup do
    before do
      @db = double()
      @geo_ip = double()
      @lookup = Lookup.new(:db => @db, :geo_ip => @geo_ip)
      @dummy_results = [{'obj' => {:name => 'Gotham City', :location => [1, 2]}}]
    end

    describe '#ip_lookup' do
      it 'looks up the IP in the GeoIP database' do
        @geo_ip.should_receive(:look_up)
        @lookup.ip_lookup('8.8.8.8')
      end
      
      it 'looks up the position in the cities collection' do
        @geo_ip.stub(:look_up).and_return(:latitude => 1, :longitude => 2)
        @db.should_receive(:command).with(hash_including(:geoNear => 'cities', :near => [1, 2])).and_return('results' => @dummy_results)
        @lookup.ip_lookup('8.8.8.8')
      end
      
      it 'returns nil if the IP is not found in the GeoIP database' do
        @geo_ip.stub(:look_up).and_return(nil)
        @lookup.ip_lookup('8.8.8.8').should be_nil
      end
      
      it 'returns nil if no city is found' do
        @geo_ip.stub(:look_up).and_return(:latitude => 1, :longitude => 2)
        @db.should_receive(:command).with(hash_including(:geoNear => 'cities', :near => [1, 2])).and_return('results' => [])
        @lookup.ip_lookup('8.8.8.8').should be_nil
      end
      
      it 'returns a hash with symbol keys' do
        @geo_ip.stub(:look_up).and_return({:latitude => 3, :longitude => 5})
        @db.should_receive(:command).and_return('results' => [{'obj' => {'name' => 'Macondo'}}])
        city = @lookup.ip_lookup('8.8.8.8')
        city.should have_key(:name)
      end
      
      it 'returns the latitude and longitude from the GeoIP database' do
        @geo_ip.stub(:look_up).and_return(:latitude => 1, :longitude => 2)
        @db.should_receive(:command).with(hash_including(:near => [1, 2])).and_return('results' => [{:obj => {:name => 'Gotham City', :location => [-1, -2]}}])
        city = @lookup.ip_lookup('8.8.8.8')
        city[:location].should == [1, 2]
      end

      it 'returns the region from the GeoIP database if none exist in the city data' do
        @geo_ip.stub(:look_up).and_return(:region => 'Far, far away', :latitude => 3, :longitude => 5)
        @db.should_receive(:command).and_return('results' => @dummy_results)
        city = @lookup.ip_lookup('8.8.8.8')
        city[:region].should == 'Far, far away'
        @db.should_receive(:command).and_return('results' => [{:obj => {:name => 'Gotham City', :region => 'Very far away'}}])
        city = @lookup.ip_lookup('8.8.8.8')
        city[:region].should == 'Very far away'
      end

      it 'returns the country name from the GeoIP database if none exist in the city data' do
        @geo_ip.stub(:look_up).and_return(:country_name => 'Far, far away', :latitude => 3, :longitude => 5)
        @db.should_receive(:command).and_return('results' => @dummy_results)
        city = @lookup.ip_lookup('8.8.8.8')
        city[:country_name].should == 'Far, far away'
        @db.should_receive(:command).and_return('results' => [{:obj => {:name => 'Gotham City', :country_name => 'Very far away'}}])
        city = @lookup.ip_lookup('8.8.8.8')
        city[:country_name].should == 'Very far away'
      end
      
      it 'complains if the IP is malformed' do
        expect { @lookup.ip_lookup('8.8.8') }.to raise_error(ArgumentError)
        expect { @lookup.ip_lookup('apa') }.to raise_error(ArgumentError)
      end
      
      it 'complains if the IP is internal or private' do
        expect { @lookup.ip_lookup('127.0.0.1') }.to raise_error(ArgumentError)
        expect { @lookup.ip_lookup('192.168.3.5') }.to raise_error(ArgumentError)
        expect { @lookup.ip_lookup('169.254.3.4') }.to raise_error(ArgumentError)
        expect { @lookup.ip_lookup('192.1.3.5') }.to_not raise_error(ArgumentError)
        expect { @lookup.ip_lookup('169.254.255.4') }.to_not raise_error(ArgumentError)
      end
    end
    
    describe '#position_lookup' do
      it 'looks up the closest city to the given latitude/longitude' do
        @db.should_receive(:command).with(hash_including(:geoNear => 'cities', :near => [1, 2])).and_return('results' => @dummy_results)
        city = @lookup.position_lookup(1, 2)
        city[:name].should == 'Gotham City'
      end
      
      it 'returns the given latitude/longitude, not the city\'s' do
        @db.should_receive(:command).with(hash_including(:geoNear => 'cities', :near => [1, 2])).and_return('results' => [{:obj => {:name => 'Gotham City', :location => [-1, -2]}}])
        city = @lookup.position_lookup(1, 2)
        city[:location].should == [1, 2]
      end
      
      it 'complains if the latitude or longitude is not numeric' do
        expect { @lookup.position_lookup('1', 'apa') }.to raise_error(ArgumentError)
      end

      it 'handles negative longitudes' do
        expect { @lookup.position_lookup('1', '-3') }.to_not raise_error(ArgumentError)
      end
      
      it 'returns the largest city within 0.1 points of the closest city' do
        cities = [
          {:dis => 0.001, :obj => {:name => 'A', :population => 1}},
          {:dis => 0.002, :obj => {:name => 'B', :population => 2}},
          {:dis => 0.103, :obj => {:name => 'C', :population => 3}}
        ]
        @db.should_receive(:command).and_return('results' => cities)
        city = @lookup.position_lookup(1, 2)
        city[:name].should == 'B'
      end
    end
  end
end
