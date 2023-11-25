# Devise を使ったログイン機能の実装

## ① アプリの立ち上げ

`rails new アプリ名`

## ②Docker 環境の導入

Dockerfile<br>

```
FROM ruby:3.2.1

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN gem install bundler

RUN bundle install

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]

COPY . .
```

<br><br>
docker-compose.yml<br>

```
version: "3"
services:
  rails:
    build:
      context: ./
      dockerfile: Dockerfile
    ports:
      - "4000:4000"
    volumes:
      - ./:/app
    depends_on:
      - postgresql
    command: bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -p 4000 -b '0.0.0.0'"

  postgresql:
    image: postgres:14.9
    volumes:
      - postgres_volume:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    restart: always
    ports:
      - "5432:5432"
volumes:
  postgres_volume:

```

## ③entrypoint.sh ファイルの用意

```
#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
```

## ④Docker の実行

はじめに docker エンジンを起動します。<br>
次に以下のコマンドを順に叩きます。<br>
`docker-compose build`
`docker-compose up -d`
