FROM phusion/passenger-ruby23:0.9.20

RUN apt-get update --assume-yes && apt-get install --assume-yes build-essential

# For a JS runtime
# http://nodejs.org/
RUN apt-get install --assume-yes nodejs

# For Nokogiri gem
# http://www.nokogiri.org/tutorials/installing_nokogiri.html#ubuntu___debian
RUN apt-get install --assume-yes libxml2-dev libxslt1-dev

# For RMagick gem
# https://help.ubuntu.com/community/ImageMagick
RUN apt-get install --assume-yes libmagickwand-dev

# zh-cn locales
RUN apt-get install locales language-pack-zh-hans language-pack-zh-hans-base -y && \
    echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && \
    dpkg-reconfigure -f noninteractive locales && \
    echo "export LC_ALL=zh_CN.UTF-8" >> ~/.bashrc && \
    echo "export LANG=zh_CN.UTF-8" >> ~/.bashrc && \
    echo "export LANGUAGE=zh_CN.UTF-8" >> ~/.bashrc

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime
RUN echo "Asia/Chongqing" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

# Set correct environment variables.
ENV HOME /root

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

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
