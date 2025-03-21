FROM phusion/passenger-customizable:3.1.0

# Set correct environment variables.
ENV HOME /root

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

RUN apt-get update --assume-yes && apt-get install --assume-yes build-essential unzip

# Node.js support
# ADD buildconfig /tmp/buildconfig
# ADD nodejs.sh /tmp/nodejs.sh
# RUN /tmp/nodejs.sh 18
# RUN /tmp/nodejs.sh
# RUN rm /tmp/buildconfig
# RUN rm /tmp/nodejs.sh
# RUN /pd_build/nodejs.sh 18
RUN /pd_build/nodejs.sh 22

# Ruby support
RUN /pd_build/ruby-3.3.6.sh

# Yarn support
# RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -  && \
#     echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list  && \
#     rm -r /var/lib/apt/lists/* && apt-get update && apt-get install yarn

# Use taobao NPM source
RUN npm config set registry https://mirrors.tencent.com/npm/

# PNPM support
# https://github.com/nodejs/corepack/issues/612
ENV COREPACK_INTEGRITY_KEYS='{"npm":[{"expires":"2025-01-29T00:00:00.000Z","keyid":"SHA256:jl3bwswu80PjjokCgh0o2w5c2U4LhQAE57gj9cz1kzA","keytype":"ecdsa-sha2-nistp256","scheme":"ecdsa-sha2-nistp256","key":"MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE1Olb3zMAFFxXKHiIkQO5cJ3Yhl5i6UPp+IhuteBJbuHcA5UogKo0EWtlWwW6KSaKoTNEYL7JlCQiVnkhBktUgg=="},{"expires":null,"keyid":"SHA256:DhQ8wR5APBvFHLF/+Tc+AYvPOdTpcIDqOhxsBHRwC7U","keytype":"ecdsa-sha2-nistp256","scheme":"ecdsa-sha2-nistp256","key":"MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEY6Ya7W++7aUPzvMTrezH6Ycx3c+HOKYCcNGybJZSCJq/fd7Qa8uuAKtdIkUQtQiEKERhAmE5lMMJhP8OkDOa2g=="}]}'    
SHELL ["/bin/bash", "-c"]
RUN npm install -g --force pnpm@latest-10 \
    && SHELL=bash pnpm setup \
    && source /root/.bashrc

# Fixing the stupid missing node-sass vendor directory error
ENV SASS_BINARY_PATH=/opt/linux-x64-115_binding.node
# Resolve the issue might caused by node-sass installation issue
ADD linux-x64-115_binding.node /opt/linux-x64-115_binding.node

# For Nokogiri gem
# http://www.nokogiri.org/tutorials/installing_nokogiri.html#ubuntu___debian
RUN apt-get install --assume-yes libxml2-dev libxslt1-dev

# For RMagick gem
# https://help.ubuntu.com/community/ImageMagick
RUN apt-get install --assume-yes imagemagick

# Install vips
RUN apt-get install -y libvips-dev

# zh-cn locales
RUN apt-get install tzdata locales language-pack-zh-hans language-pack-zh-hans-base -y && \
    echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && \
    dpkg-reconfigure -f noninteractive locales && \
    echo "export LC_ALL=zh_CN.UTF-8" >> ~/.bashrc && \
    echo "export LANG=zh_CN.UTF-8" >> ~/.bashrc && \
    echo "export LANGUAGE=zh_CN.UTF-8" >> ~/.bashrc

# Install libgeos-dev for GEOS support in RGeo gem
RUN apt-get install --assume-yes libgeos-dev libproj-dev
# RUN ln -s /usr/lib/x86_64-linux-gnu/libgeos-3.8.0.so /usr/lib/x86_64-linux-gnu/libgeos.so

# Install ffmpeg
RUN apt-get install --assume-yes ffmpeg

# Install mupdf
# RUN add-apt-repository -y ppa:savoury1/backports && \
#     apt-get update && \
#     apt-get install --assume-yes mupdf mupdf-tools
# For mupdf, copy v 1.19.1 to /usr/local/bin, since the default version is too old and installed one has head/lib incompatible issue.
ADD mutool /usr/local/bin/mutool
ADD muraster /usr/local/bin/muraster
ADD libcrypto.so.1.1 /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1

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
# Add logrotation configuration file
ADD rails_logs /etc/logrotate.d/rails_logs

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

# Trust all git repositories to avoid errors might happen: `detected dubious ownership in repository at`
RUN git config --global --add safe.directory '*'

# Fix issue: https://github.com/travis-ci/travis-ci/issues/8978
# RUN gem install bundler