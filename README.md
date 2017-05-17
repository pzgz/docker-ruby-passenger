# Docker image with Ruby and Passenger, specialized for capistrano target

**NOITCE: I mainly used this in my own project, so use on your own risk, this might contained some opinionated settings.**

Based on [phusion/passenger-docker](https://github.com/phusion/passenger-docker), with following settings:

* Nginx enabled and Exposed 80 for nginx
* Passenger enabled
* Set to use `capistrano` as deployment tools
* `/home/app` as the root directory for `capistrano` deploy target
* Expose 22 for SSH access, so that capistrano can do the the deploy
* Following env variables will be passed to nginx and Rails app: `SECRET_KEY_BASE`,  `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`
* Set timezone to China timezone

