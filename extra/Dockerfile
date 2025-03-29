ARG RUBY_IMAGE=ruby:3
FROM ${RUBY_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive
ENV DEVEL=1
ENV LANG=C.UTF-8

RUN apt-get update -qq
RUN apt-get install -yqq --no-install-recommends build-essential nano netcat-traditional pkg-config
RUN apt-get install -yqq --no-install-recommends freetds-dev libmariadb-dev libpq-dev libvips42 libyaml-dev sqlite3

RUN gem install bundler -v 2.5.23
RUN echo 'gem: --no-document' > /etc/gemrc

ARG UID
RUN useradd -u $UID --shell /bin/bash app 

RUN mkdir -p /home/app
RUN chown -R app:app /home/app
RUN chown -R app /usr/local/bundle 

ARG RAILS_VERSION
ENV RAILS_VERSION=$RAILS_VERSION

WORKDIR /app
COPY . /app
RUN bundle install
RUN chown -R app:app /app/spec/dummy/db
