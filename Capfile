set :default_stage, 'staging'
set :stages, %w(production staging)

require 'capistrano/ext/multistage'

load 'deploy' if respond_to?(:namespace) # cap2 differentiator

load 'config/deploy'
