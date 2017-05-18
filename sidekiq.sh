#!/bin/sh
cd /home/app/current/
exec /sbin/setuser app bundle exec sidekiq -e $RAILS_ENV -C config/sidekiq.yml >>/home/app/current/log/sidekiq.log 2>&1