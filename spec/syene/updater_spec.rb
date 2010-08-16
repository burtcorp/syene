# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)
require 'tmpdir'
require 'fileutils'
require 'zipruby'


module Syene
  describe Updater do
    before do
      @tmp_dir = File.join(Dir.tmpdir, 'syene-updater')
      FileUtils.rm_rf(@tmp_dir)
      FileUtils.mkdir_p(@tmp_dir)
      @downloader = mock()
      @collection = mock()
      @collection.stub(:save)
      @updater = Updater.new(
        :downloader => @downloader,
        :url => 'http://www.example.com/cities.zip',
        :tmp_dir => @tmp_dir,
        :collection => @collection,
        :target => :cities
      )
      @zip_buffer = Zip::Archive.open_buffer(Zip::CREATE) do |archive|
        archive.add_buffer('cities.txt', 'data!')
      end
      @zip_io = StringIO.new(@zip_buffer, 'r')
    end
    
    after do
      FileUtils.rm_rf(@tmp_dir)
    end
    
    describe '#update!' do
      it 'downloads the cities archive' do
        @downloader.should_receive(:open).with('http://www.example.com/cities.zip').and_yield(@zip_io)
        @updater.update!
        File.read(File.join(@tmp_dir, 'cities.zip')).should == @zip_buffer
      end
      
      it 'extracts the cities file from the archive' do
        @downloader.stub(:open).and_yield(@zip_io)
        @updater.update!
        File.read(File.join(@tmp_dir, 'cities.txt')).should == 'data!'
      end
      
      it 'saves all cities to the collection' do
        @zip_buffer = Zip::Archive.open_buffer(Zip::CREATE) do |archive|
          archive.add_buffer('cities.txt', <<-CITIES)
3039163	Sant Julià de Lòria	Sant Julia de Loria	San Julia,San Julià,San-Dzhulija-de-Lorija,San-Khulija-de-Lorija,Sant Julia de Loria,Sant Julià de Lòria,sheng hu li ya-de luo li ya,Сан-Джулия-де-Лория,Сан-Хулия-де-Лория,サン・ジュリア・デ・ロリア教区,圣胡利娅-德洛里亚,圣胡利娅－德洛里亚	42.46372	1.49129	P	PPLA	AD		06				8022		1045	Europe/Andorra	2008-10-15
3039604	Pas de la Casa	Pas de la Casa	Pas de la Kasa,Пас де ла Каса	42.54277	1.73361	P	PPL	AD		03				2363	2050	2230	Europe/Andorra	2008-06-09
3039678	Ordino	Ordino	Ordino,ao er di nuo,orudino jiao qu,Ордино,オルディノ教区,奥尔迪诺	42.55623	1.53319	P	PPLA	AD		05				3066		1340	Europe/Andorra	2009-12-11
          CITIES
        end
        @zip_io = StringIO.new(@zip_buffer, 'r')
        @downloader.stub(:open).and_yield(@zip_io)
        @collection.should_receive(:save).with({:_id => '3039163', :name => 'Sant Julià de Lòria', :ascii_name => 'Sant Julia de Loria', :location => [42.46372, 1.49129], :population => 8022, :country_code => 'AD', :country_name => nil, :region => nil})
        @collection.should_receive(:save).with({:_id => '3039604', :name => 'Pas de la Casa',      :ascii_name => 'Pas de la Casa',      :location => [42.54277, 1.73361], :population => 2363, :country_code => 'AD', :country_name => nil, :region => nil})
        @collection.should_receive(:save).with({:_id => '3039678', :name => 'Ordino',              :ascii_name => 'Ordino',              :location => [42.55623, 1.53319], :population => 3066, :country_code => 'AD', :country_name => nil, :region => nil})
        @updater.update!
      end
    end
    
    describe '#clean!' do
      it 'cleans up all temporary files' do
        @downloader.stub(:open).and_yield(@zip_io)
        @updater.update!
        @updater.clean!
        Dir[File.join(@tmp_dir, '*')].should == []
      end
    end
  end
end
