set :application, 'syene'
set :stages, %w(staging production)

require 'bundler/setup'; Bundler.setup(:development)
require 'capistrano/ext/multistage'
require 'burt/capistrano/git_check'
require 'burt/capistrano/defaults'

after 'deploy:update_code', 'custom:symlinks'
after 'deploy:update_code', 'custom:service_config'
after 'deploy:update_code', 'custom:fix_permissions'

namespace :deploy do
  task :start, :roles => [:app] do
    run "sudo service #{application} start"
  end

  task :stop, :roles => [:app] do
    # silently ignore if the service is not running
    run "service #{application} status | grep running && sudo service #{application} stop || :"
  end

  task :restart, :roles => [:app] do
    deploy.stop
    deploy.start
  end

  # This will make sure that Capistrano doesn't try to run rake:migrate (this is not a Rails project!)
  task :cold do
    deploy.update
    deploy.start
  end
end

namespace :custom do
  desc 'Create upstart config, etc.'
  task :service_config, :roles => [:app] do
    run [
      "sudo cp -f #{release_path}/config/etc/init/#{application}.conf /etc/init/#{application}.conf",
      "sudo chown root:root /etc/init/#{application}.conf",
      "sudo ln -nfs /lib/init/upstart-job /etc/init.d/#{application}"
    ].join(' && ')
  end
  
  desc 'Create symlinks from shared/public to current/public'
  task :symlinks, :roles => [:app] do
    # create and link a shared log directory
    run "mkdir -p #{shared_path}/log && mkdir -p #{release_path}/tmp && ln -nfs #{shared_path}/log #{release_path}/tmp/log"

    run "ln -nfs /usr/share/GeoIP/GeoIP.dat #{release_path}/tmp/GeoIPCity.dat"
  end
  
  desc 'Runs "rake update"'
  task :update_cities, :roles => [:app] do
    run "cd #{current_path} && rvm default rake update"
  end
  
  desc 'Makes sure the burt & ubuntu users can read & write the right files'
  task :fix_permissions, :roles => [:app] do
    run "sudo chown -R burt:burt #{deploy_to}"
    run "sudo chmod g+rw #{deploy_to}/releases"
    run "sudo chmod -R g+rw #{shared_path} #{shared_path}/cached-copy/.git"
  end
end