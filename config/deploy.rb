require "bundler"
Bundler.setup(:default, :deployment)

# deploy recipes - need to do `sudo gem install thunder_punch` - these should be required last
require 'thunder_punch'

# rvm support
set :rvm_ruby_string, 'ree-1.8.7-2012.02'
set :rvm_require_role, :rvm
set :rvm_type, :system
require "rvm/capistrano/selector_mixed"

#############################################################
# Set Basics
#############################################################
set :application, "federalregister-web"
set :user, "deploy"
set :current_path, "/var/www/apps/#{application}"

if File.exists?(File.join(ENV["HOME"], ".ssh", "fr_staging"))
  ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "fr_staging")]
else
  ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_rsa")]
end

# use these settings for making AMIs with thunderpunch
# set :user, "ubuntu"
#ssh_options[:keys] = [File.join('~/Documents/AWS/FR2', "gpoEC2.pem")]


ssh_options[:paranoid] = false
set :use_sudo, true
default_run_options[:pty] = true

set(:latest_release)  { fetch(:current_path) }
set(:release_path)    { fetch(:current_path) }
set(:current_release) { fetch(:current_path) }

set(:current_revision)  { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:latest_revision)   { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:previous_revision) { capture("cd #{current_path}; git rev-parse --short HEAD@{1}").strip }


set :finalize_deploy, false
# we don't need this because we have an asset server
# and we also use varnish as a cache server. Thus
# normalizing timestamps is detrimental.
set :normalize_asset_timestamps, false


set :migrate_target, :current


#############################################################
# General Settings
#############################################################

set :deploy_to,  "/var/www/apps/#{application}"

#############################################################
# Set Up for Production Environment
#############################################################

task :production do
  set :rails_env,  "production"
  set :branch, 'production'

  set :gateway, 'fr2_production'

  role :proxy,  "proxy.fr2.ec2.internal"
  role :app,    "web-1.fr2.ec2.internal", "web-2.fr2.ec2.internal", "web-3.fr2.ec2.internal", "web-4.fr2.ec2.internal", "web-5.fr2.ec2.internal"
  role :db,     "database.fr2.ec2.internal", {:primary => true}
  role :sphinx, "sphinx.fr2.ec2.internal"
  role :worker, "worker.fr2.ec2.internal", {:primary => true} #monster image

  role :rvm, "web-1.fr2.ec2.internal", "web-2.fr2.ec2.internal", "web-3.fr2.ec2.internal", "web-4.fr2.ec2.internal", "web-5.fr2.ec2.internal", "sphinx.fr2.ec2.internal", "worker.fr2.ec2.internal"

  set :github_user_repo, 'usnationalarchives'
  set :github_project_repo, 'my_fr2'
  set :github_username, 'usnationalarchives'
  set :repository, "git@github.com:#{github_user_repo}/#{github_project_repo}.git"
end


#############################################################
# Set Up for Staging Environment
#############################################################

task :staging do
  set :rails_env,  "staging"
  set :branch, `git branch`.match(/\* (.*)/)[1]
  set :gateway, 'fr2_staging'

  role :proxy,  "proxy.fr2.ec2.internal"
  role :app,    "web.fr2.ec2.internal"
  role :sphinx, "sphinx.fr2.ec2.internal"
  role :worker, "worker.fr2.ec2.internal", {:primary => true}

  role :rvm, "web.fr2.ec2.internal", "sphinx.fr2.ec2.internal", "worker.fr2.ec2.internal"

  set :github_username, 'criticaljuncture'
  set :github_user_repo, 'criticaljuncture'
  set :github_project_repo, 'federalregister-web'
  set :repository, "git@github.com:#{github_user_repo}/#{github_project_repo}.git"
end

#############################################################
# SCM Settings
#############################################################
set :scm,              :git
set :deploy_via,       :remote_cache


#############################################################
# Git
#############################################################

# This will execute the Git revision parsing on the *remote* server rather than locally
set :real_revision, lambda { source.query_revision(revision) { |cmd| capture(cmd) } }
set :git_enable_submodules, true


#############################################################
# Bundler
#############################################################
# this should list all groups in your Gemfile (except default)
set :gem_file_groups, [:deployment, :development, :test]


#############################################################
# Run Order
#############################################################

# Do not change below unless you know what you are doing!
# all deployment changes that affect app servers also must
# be put in the user-scripts files on s3!!!

after "deploy:update_code",      "deploy:set_rake_path"
after "deploy:set_rake_path",    "bundler:fix_bundle"
after "bundler:fix_bundle",      "deploy:migrate"
after "deploy:migrate",          "assets:precompile"
after "assets:precompile",       "passenger:restart"
after "passenger:restart",       "varnish:clear_cache"
after "varnish:clear_cache",     "honeybadger:notify_deploy"


#############################################################
#                                                           #
#                                                           #
#                         Recipes                           #
#                                                           #
#                                                           #
#############################################################

namespace :apache do
  desc "Restart Apache Servers"
  task :restart, :roles => [:app] do
    sudo '/etc/init.d/apache2 restart'
  end
end

namespace :assets do
  task :precompile, :roles => [:app, :worker] do
    run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec rake assets:precompile"
  end
end


#############################################################
# Airbrake Tasks
#############################################################

namespace :honeybadger do
  task :notify_deploy, :roles => [:worker] do
    run "cd #{current_path} && bundle exec rake honeybadger:deploy RAILS_ENV=#{rails_env} TO=#{branch} USER=#{`git config --global github.user`.chomp} REVISION=#{real_revision} REPO=#{repository}"
  end
end


#############################################################
# Varnish Tasks (Override Thunderpunch)
#############################################################

namespace :varnish do
  task :clear_cache, :roles => [:worker] do
    run "cd #{current_path} && cd ../federalregister-api-core && RAILS_ENV=#{rails_env} bundle exec rake varnish:expire:everything"
  end
end
