#!/bin/sh
cd /home/app/current/
bundle exec sidekiq -e $RAILS_ENV -L log/sidekiq.log -C config/sidekiq.yml