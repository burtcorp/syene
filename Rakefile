$: << File.expand_path('../lib', __FILE__)

unless defined?(Bundler)
  require 'rubygems'
  require 'bundler'
end

Bundler.setup(:default, :test)


task :default => :spec


# Import all .rake-files in the tasks directory
FileList['tasks/*.rake'].each do |rakefile|
  ns = rakefile.gsub(/^tasks\/([^\.]+)\.rake$/, '\1')

  task ns => "#{ns}:default"

  namespace ns do
    load rakefile
  end
end