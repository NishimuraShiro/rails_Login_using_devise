# Devise を使ったログイン機能の実装

## ① アプリの立ち上げ

`rails new アプリ名`

## ②Gemfile に「gem 'devise'」を追加

コマンドで`bundle install`を実行

## ③Docker 環境の導入

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
