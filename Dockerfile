FROM phusion/passenger-customizable:3.0.2

# Set correct environment variables.
ENV HOME /root

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

RUN apt-get update --assume-yes && apt-get install --assume-yes build-essential

# Node.js support
# ADD buildconfig /tmp/buildconfig
# ADD nodejs.sh /tmp/nodejs.sh
# RUN /tmp/nodejs.sh 18
# RUN /tmp/nodejs.sh
# RUN rm /tmp/buildconfig
# RUN rm /tmp/nodejs.sh
# RUN /pd_build/nodejs.sh 18
RUN /pd_build/nodejs.sh 20

# Ruby support
# RUN /pd_build/ruby-3.2.3.sh
RUN /pd_build/ruby-3.3.0.sh

# Yarn support
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -  && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list  && \
    rm -r /var/lib/apt/lists/* && apt-get update && apt-get install yarn

# Resolve the issue might caused by node-sass installation issue
# ADD linux-x64-83_binding.node /opt/linux-x64-83_binding.node
# ADD linux-x64-93_binding.node /opt/linux-x64-93_binding.node
# ADD linux-x64-108_binding.node /opt/linux-x64-108_binding.node
ADD linux-x64-111_binding.node /opt/linux-x64-111_binding.node
ADD linux-x64-115_binding.node /opt/linux-x64-115_binding.node

# Use taobao NPM source for YARN
RUN yarn config set registry https://registry.npmmirror.com
RUN yarn config set sass_binary_site https://npmmirror.com/mirrors/node-sass/
# RUN yarn config set sass-binary-path /opt/linux-x64-83_binding.node
# RUN npm config set sass-binary-path /opt/linux-x64-83_binding.node
# Fixing the stupid missing node-sass vendor directory error
ENV SASS_BINARY_PATH=/opt/linux-x64-115_binding.node

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

# Fix issue: https://github.com/travis-ci/travis-ci/issues/8978
# RUN gem install bundler