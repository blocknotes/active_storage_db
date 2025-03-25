ARG RUBY_IMAGE=ruby:3
FROM ${RUBY_IMAGE}

ARG DB_TEST=sqlite
ARG RAILS_VERSION
ARG UID

ENV DB_TEST=$DB_TEST
ENV DEVEL=1
ENV PROJECT_PATH=/app
ENV RAILS_ENV=development
ENV RAILS_VERSION=$RAILS_VERSION

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

RUN apt-get update -qq
RUN apt-get install -yqq --no-install-recommends build-essential nano pkg-config
RUN apt-get install -yqq --no-install-recommends freetds-dev libmariadb-dev libpq-dev libvips42 libyaml-dev sqlite3

RUN gem install bundler -v 2.5.23
RUN echo 'gem: --no-document' > /etc/gemrc

RUN useradd -u $UID --shell /bin/bash app 
RUN mkdir /app_deps && mkdir -p /home/app
RUN chown -R app:app /home/app
RUN chown -R app /usr/local/bundle 

WORKDIR /app
COPY . /app
RUN bundle install
RUN bin/rails db:create db:migrate db:test:prepare
RUN chown -R app:app /app/spec/dummy/db

ENTRYPOINT ["extra/entrypoint.sh"]
