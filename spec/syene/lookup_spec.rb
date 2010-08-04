# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


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
        @geo_ip.stub(:look_up).and_return({})
        @collection.stub(:find_one).and_return({'name' => 'Macondo'})
        city = @lookup.ip_lookup('8.8.8.8')
        city.should have_key(:name)
      end
    end
  end
end
