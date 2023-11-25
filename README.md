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
`docker-compose build`<br>
`docker-compose up -d`<br>

### コンテナ起動の確認

以下の URL に飛んで画像のように表示されたらコンテナ起動の成功です。<br>
http://localhost:4000/ <br>
<img width="1437" alt="スクリーンショット 2023-11-25 14 48 54" src="https://github.com/NishimuraShiro/rails_Login_using_devise/assets/73762800/42f8a05c-bdd7-435b-b70c-aa3da53c5d10">

## ⑤devise の導入

### Gemfile に以下の 1 行を追加

`gem 'devise'`<br>

### User モデルの作成

`rails generate devise User`<br>
このコマンドを実行すると、以下のファイルが作成されます。

- app/models/user.rb
- config/routes.rb
- db/migrate/20231124150526_devise_create_users.rb
- test/fixtures/users.yml
- test/models/user_test.rb

### devise の取り込み

以下のコードを順に実行します。<br>
`docker-compose exec rails bash`<br>
`bundle install`

## ⑥ データベース関連の設定

### postgresql の導入

今回は postgresql を使用するので以下の行を Gemfile に追加します。<br>
`gem "pg", "~> 1.1"`<br><br>
以下のコードを順に実行します。<br>
`docker-compose exec rails bash`<br>
`bundle install`

### database.yml の修正

データベースの名前を「rails_development」とすることにします。

```
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: postgresql
  username: postgres
  password: password

development:
  <<: *default
  adapter: postgresql
  encoding: unicode
  database: rails_development
  username: postgres
  password: password
  host: postgresql
```

### マイグレーションファイルの実行

以下のコードを順に実行します。<br>
`docker-compose exec rails bash`<br>
`bundle install`<br>
`rails db:migrate`<br>

### データベースの確認

![スクリーンショット 2023-11-25 14 57 46](https://github.com/NishimuraShiro/rails_Login_using_devise/assets/73762800/a7cd0d4f-3d9f-4321-a42f-2c3e10d160d2)
画像を参考にしています。<br><br>
コンテナ内のコマンドに移動<br>
`docker-compose exec postgresql bash`<br><br>
postgresql ログイン<br>
`psql -h postgresql -U postgres`<br>
パスワード：「password」<br><br>
データベース一覧表示`\l`<br>
データベースの切り替え`\c rails_development`<br>
テーブル一覧の表示`\dt`<br>
users テーブルのカラム表示`\d users`<br>
users テーブルのデータ表示`select * from users;`
