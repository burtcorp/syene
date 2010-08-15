begin
  require 'spec/rake/spectask'
  

  Spec::Rake::SpecTask.new(:default) do |spec|
    spec.spec_opts << '--options' << 'spec/spec.opts'
    spec.pattern = 'spec/**/*_spec.rb'
  end
rescue LoadError
end