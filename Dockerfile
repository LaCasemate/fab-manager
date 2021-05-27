FROM ruby:2.6.7-alpine
MAINTAINER contact@fab-manager.com

# Install upgrade system packages
RUN apk update && apk upgrade && \
# Install runtime apk dependencies
    apk add --update \
      bash \
      curl \
      nodejs \
      yarn \
      imagemagick \
      supervisor \
      tzdata \
      libc-dev \
      ruby-dev \
      zlib-dev \
      xz-dev \
      postgresql-dev \
      postgresql-client \
      libxml2-dev \
      libxslt-dev \
      libidn-dev && \
# Install buildtime apk dependencies
    apk add --update --no-cache --virtual .build-deps \
      alpine-sdk \
      build-base \
      linux-headers \
      git \
      patch

RUN gem install bundler

# Throw error if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

# Install gems in a cache efficient way
WORKDIR /tmp
COPY Gemfile /tmp/
COPY Gemfile.lock /tmp/
RUN bundle install --binstubs --without development test doc

# Install Javascript packages
WORKDIR /usr/src/app
COPY package.json /usr/src/app/package.json
COPY yarn.lock /usr/src/app/yarn.lock
RUN yarn install

# Clean up build deps, cached packages and temp files
RUN apk del .build-deps && \
    yarn cache clean && \
    rm -rf /tmp/* \
           /var/tmp/* \
           /var/cache/apk/* \
           /usr/lib/ruby/gems/*/cache/*

# Web app
RUN mkdir -p /usr/src/app && \
    mkdir -p /usr/src/app/config && \
    mkdir -p /usr/src/app/invoices && \
    mkdir -p /usr/src/app/payment_schedules && \
    mkdir -p /usr/src/app/exports && \
    mkdir -p /usr/src/app/imports && \
    mkdir -p /usr/src/app/log && \
    mkdir -p /usr/src/app/public/uploads && \
    mkdir -p /usr/src/app/public/packs && \
    mkdir -p /usr/src/app/accounting && \
    mkdir -p /usr/src/app/tmp/sockets && \
    mkdir -p /usr/src/app/tmp/pids

COPY docker/database.yml /usr/src/app/config/database.yml
COPY . /usr/src/app

# Volumes
VOLUME /usr/src/app/invoices
VOLUME /usr/src/app/payment_schedules
VOLUME /usr/src/app/exports
VOLUME /usr/src/app/imports
VOLUME /usr/src/app/public
VOLUME /usr/src/app/public/uploads
VOLUME /usr/src/app/public/packs
VOLUME /usr/src/app/accounting
VOLUME /var/log/supervisor

# Expose port 3000 to the Docker host, so we can access it from the outside
EXPOSE 3000

# The main command to run when the container starts. Also tell the Rails server
# to bind to all interfaces by default.
COPY docker/supervisor.conf /etc/supervisor/conf.d/fablab.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/fablab.conf"]
