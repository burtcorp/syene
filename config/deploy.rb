# Application
set :application, 'syene'

# Settings
default_run_options[:pty] = true
set :use_sudo, false

# SSH Options
ssh_options[:forward_agent] = true

# SCM
set :scm, 'git'
set :repository, "git@github.com:burtcorp/#{application}.git"
set :deploy_via, :remote_cache
set :deploy_to, "/mnt/data/apps/#{application}"

after 'deploy:update_code', 'custom:symlinks'
after 'deploy:update_code', 'custom:bundle'
after 'deploy:update_code', 'custom:service_config'

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

    # create and link in a shared directory for bundled gems
    run "mkdir -p #{shared_path}/bundle #{release_path}/vendor && ln -nfs #{shared_path}/bundle #{release_path}/.bundle && ln -nfs #{shared_path}/bundle #{release_path}/vendor/bundle"
    
    run "ln -nfs /mnt/data/geoip/GeoIPCity.dat #{release_path}/tmp/GeoIPCity.dat"
  end
  
  desc 'Run "bundle install"'
  task :bundle, :roles => [:app] do
    run "cd #{release_path} && bundle install vendor/bundle --without test development"
  end
  
  desc 'Runs "rake update"'
  task :update_cities, :roles => [:app] do
    run "cd #{release_path} && rake update"
  end
end