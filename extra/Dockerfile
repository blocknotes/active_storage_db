ARG RUBY_IMAGE=ruby:3
FROM ${RUBY_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive
ENV DEVEL=1
ENV LANG=C.UTF-8

RUN apt-get update -qq
RUN apt-get install -yqq --no-install-recommends build-essential less nano netcat-traditional pkg-config
RUN apt-get install -yqq --no-install-recommends freetds-dev libmariadb-dev libpq-dev libvips42 libyaml-dev sqlite3

ARG BUNDLER_VERSION
RUN gem install bundler -v ${BUNDLER_VERSION}
RUN echo 'gem: --no-document' > /etc/gemrc

ARG UID
RUN useradd -u $UID --shell /bin/bash app 

RUN mkdir -p /home/app && chown -R app:app /home/app

ARG RAILS_VERSION
ENV RAILS_VERSION=$RAILS_VERSION

WORKDIR /app
COPY . /app
RUN bundle install
RUN chown -R app:app /app/spec/dummy/db /usr/local/bundle

RUN ln -s /app/extra/.bashrc /home/app/.bashrc
