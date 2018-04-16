FROM phusion/passenger-ruby25:0.9.30

# Set correct environment variables.
ENV HOME /root

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

RUN apt-get update --assume-yes && apt-get install --assume-yes build-essential

# Node.js support
ADD buildconfig /tmp/buildconfig
ADD nodejs.sh /tmp/nodejs.sh
RUN /tmp/nodejs.sh
RUN rm /tmp/buildconfig
RUN rm /tmp/nodejs.sh

# Yarn support
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -  && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list  && \
    apt-get update && apt-get install yarn

# Resolve the issue might caused by node-sass installation issue
ADD linux-x64-59_binding.node /opt/linux-x64-59_binding.node

# Use taobao NPM source for YARN
RUN yarn config set registry https://registry.npm.taobao.org
# RUN yarn config set sass-binary-path /opt/linux-x64-59_binding.node
# RUN npm config set sass-binary-path /opt/linux-x64-59_binding.node
# Fixing the stupid missing node-sass vendor directory error
ENV SASS_BINARY_PATH=/opt/linux-x64-59_binding.node

# For Nokogiri gem
# http://www.nokogiri.org/tutorials/installing_nokogiri.html#ubuntu___debian
RUN apt-get install --assume-yes libxml2-dev libxslt1-dev

# For RMagick gem
# https://help.ubuntu.com/community/ImageMagick
RUN apt-get install --assume-yes libmagickwand-dev

# zh-cn locales
RUN apt-get install tzdata locales language-pack-zh-hans language-pack-zh-hans-base -y && \
    echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && \
    dpkg-reconfigure -f noninteractive locales && \
    echo "export LC_ALL=zh_CN.UTF-8" >> ~/.bashrc && \
    echo "export LANG=zh_CN.UTF-8" >> ~/.bashrc && \
    echo "export LANGUAGE=zh_CN.UTF-8" >> ~/.bashrc

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# timezone
#RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
#RUN echo "Asia/Shanghai" > /etc/timezone
#RUN dpkg-reconfigure --frontend noninteractive tzdata

# REF: https://stackoverflow.com/a/39275359/100072
## preesed tzdata, update package index, upgrade packages and install needed software
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
RUN echo "tzdata tzdata/Areas select Asia" > /tmp/preseed.txt; \
    echo "tzdata tzdata/Zones/Asia select Shanghai" >> /tmp/preseed.txt; \
    debconf-set-selections /tmp/preseed.txt && \
    rm /etc/timezone && \
    rm /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

RUN rm /etc/nginx/sites-enabled/default
ADD webapp.conf /etc/nginx/sites-enabled/webapp.conf
ADD webapp-env.conf /etc/nginx/main.d/webapp-env.conf

RUN rm -f /etc/service/nginx/down
EXPOSE 80
EXPOSE 22

# Enable ssh
RUN rm -f /etc/service/sshd/down

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /home/app

# Add sidekiq
RUN mkdir /etc/service/sidekiq
ADD sidekiq.sh /etc/service/sidekiq/run