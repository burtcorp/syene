# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)


module Syene
  describe Lookup do
    before do
      @collection = mock()
      @geo_ip = mock()
      @lookup = Lookup.new(:collection => @collection, :geo_ip => @geo_ip)
    end

    describe '#ip_lookup' do
      it 'looks up the IP in the GeoIP database' do
        @geo_ip.should_receive(:look_up)
        @lookup.ip_lookup('8.8.8.8')
      end
      
      it 'looks up the position in the cities collection' do
        @geo_ip.stub(:look_up).and_return(:latitude => 1, :longitude => 2)
        @collection.should_receive(:find_one).with(:location => {'$near' => [1, 2]})
        @lookup.ip_lookup('8.8.8.8')
      end
      
      it 'returns nil if the IP is not found in the GeoIP database' do
        @geo_ip.stub(:look_up).and_return(nil)
        @lookup.ip_lookup('8.8.8.8').should be_nil
      end
      
      it 'returns a hash with symbol keys' do
        @geo_ip.stub(:look_up).and_return({:latitude => 3, :longitude => 5})
        @collection.stub(:find_one).and_return({'name' => 'Macondo'})
        city = @lookup.ip_lookup('8.8.8.8')
        city.should have_key(:name)
      end
      
      it 'returns the latitude and longitude from the GeoIP database' do
        @geo_ip.stub(:look_up).and_return(:latitude => 1, :longitude => 2)
        @collection.stub(:find_one).with(:location => {'$near' => [1, 2]}).and_return(:name => 'Gotham City', :location => [-1, -2])
        city = @lookup.ip_lookup('8.8.8.8')
        city[:location].should == [1, 2]
      end

      it 'returns the region from the GeoIP database if none exist in the city data' do
        @geo_ip.stub(:look_up).and_return(:region => 'Far, far away', :latitude => 3, :longitude => 5)
        @collection.stub(:find_one).and_return(:name => 'Gotham City')
        city = @lookup.ip_lookup('8.8.8.8')
        city[:region].should == 'Far, far away'
        @collection.stub(:find_one).and_return(:name => 'Gotham City', :region => 'Very far away')
        city = @lookup.ip_lookup('8.8.8.8')
        city[:region].should == 'Very far away'
      end

      it 'returns the country name from the GeoIP database if none exist in the city data' do
        @geo_ip.stub(:look_up).and_return(:country_name => 'Far, far away', :latitude => 3, :longitude => 5)
        @collection.stub(:find_one).and_return(:name => 'Gotham City')
        city = @lookup.ip_lookup('8.8.8.8')
        city[:country_name].should == 'Far, far away'
        @collection.stub(:find_one).and_return(:name => 'Gotham City', :country_name => 'Very far away')
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
      end
    end
    
    describe '#position_lookup' do
      it 'looks up the closest city to the given latitude/longitude' do
        @collection.stub(:find_one).with(:location => {'$near' => [1, 2]}).and_return(:name => 'Gotham City')
        city = @lookup.position_lookup(1, 2)
        city[:name].should == 'Gotham City'
      end
      
      it 'returns the given latitude/longitude, not the city\'s' do
        @collection.stub(:find_one).with(:location => {'$near' => [1, 2]}).and_return(:name => 'Gotham City', :location => [-1, -2])
        city = @lookup.position_lookup(1, 2)
        city[:location].should == [1, 2]
      end
      
      it 'complains if the latitude or longitude is not numeric' do
        expect { @lookup.position_lookup('1', 'apa') }.to raise_error(ArgumentError)
      end
    end
  end
end
