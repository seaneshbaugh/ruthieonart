set :stages, %w(production)
set :default_stage, 'production'

require 'bundler/capistrano'
require 'capistrano/ext/multistage'

load 'config/recipes/base'
load 'config/recipes/check'
load 'config/recipes/db'
load 'config/recipes/mysql'
load 'config/recipes/smtp'
load 'config/recipes/uploads'

set :application, 'ruthieonart'
set :user, 'ruthart'
set :deploy_via, :remote_cache
set :use_sudo, false
set :scm, 'git'
set :repository, 'git@github.com:seaneshbaugh/ruthieonart.git'
set :scm_verbose, true
set :bundle_flags, '--deployment'

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after 'deploy', 'deploy:cleanup'
