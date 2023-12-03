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
<br>画像を参考にしています。<br><br>
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

## ⑦ デフォルト URL の設定

「devise」では、ユーザー登録を行う際に入力したメールアドレスにメールを送り、本登録を完了させるという機能を追加することができ、その時、メールに記載する URL のドメイン名をあらかじめ設定しておく必要があります。<br><br>
config/environments/development.rb<br>

```
Rails.application.configure do
  # 以下を追記
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
end
```

## ⑧ フラッシュメッセージの表示

ログイン・ログアウトの成功時や失敗時などに出てくるアラートのようなフラッシュメッセージを設定します。<br><br>
app/views/layouts/application.html.erb<br>

```
<!DOCTYPE html>
<html>
  <head>
    <title>RailsDevise</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
    <%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>
  </head>

  <body>
    <%# 以下を追記 %>
    <p class="notice"><%= notice %></p>
    <p class="alert"><%= alert %></p>
    <%= yield %>
  </body>
</html>
```

## ⑨devise の日本語化

devise で作成されたフォームやフラッシュメッセージを日本語化するためには、application.rb に以下を追記します。<br>
config/application.rb<br>
`config.i18n.default_locale = :ja`<br><br>
次に、Gemfile に以下を追記してから`bundle install`を実行します。<br>
`gem 'devise-i18n'`<br><br>
次に、config/locales 直下に devise.ja.yml ファイルを用意して以下のコードを追記しましょう。<br>
config/locales/devise.ja.yml<br>

```
# Additional translations at https://github.com/plataformatec/devise/wiki/I18n

ja:
  devise:
    confirmations:
      confirmed: "アカウントを登録しました。"
      send_instructions: "アカウントの有効化について数分以内にメールでご連絡します。"
      send_paranoid_instructions: "あなたのメールアドレスが登録済みの場合、本人確認用のメールが数分以内に送信されます。"
    failure:
      already_authenticated: "すでにログインしています。"
      inactive: "アカウントが有効化されていません。メールに記載された手順にしたがって、アカウントを有効化してください。"
      invalid: "%{authentication_keys} もしくはパスワードが不正です。"
      locked: "あなたのアカウントは凍結されています。"
      last_attempt: "あなたのアカウントが凍結される前に、複数回の操作がおこなわれています。"
      not_found_in_database: "%{authentication_keys} もしくはパスワードが不正です。"
      timeout: "セッションがタイムアウトしました。もう一度ログインしてください。"
      unauthenticated: "アカウント登録もしくはログインしてください。"
      unconfirmed: "メールアドレスの本人確認が必要です。"
    mailer:
      confirmation_instructions:
        subject: "アカウントの有効化について"
      reset_password_instructions:
        subject: "パスワードの再設定について"
      unlock_instructions:
        subject: "アカウントの凍結解除について"
    omniauth_callbacks:
      failure: "%{kind} アカウントによる認証に失敗しました。理由：（%{reason}）"
      success: "%{kind} アカウントによる認証に成功しました。"
    passwords:
      no_token: "このページにはアクセスできません。パスワード再設定メールのリンクからアクセスされた場合には、URL をご確認ください。"
      send_instructions: "パスワードの再設定について数分以内にメールでご連絡いたします。"
      send_paranoid_instructions: "あなたのメールアドレスが登録済みの場合、パスワード再設定用のメールが数分以内に送信されます。"
      updated: "パスワードが正しく変更されました。"
      updated_not_active: "パスワードが正しく変更されました。"
    registrations:
      destroyed: "アカウントを削除しました。またのご利用をお待ちしております。"
      signed_up: "アカウント登録が完了しました。"
      signed_up_but_inactive: "ログインするためには、アカウントを有効化してください。"
      signed_up_but_locked: "アカウントが凍結されているためログインできません。"
      signed_up_but_unconfirmed: "本人確認用のメールを送信しました。メール内のリンクからアカウントを有効化させてください。"
      update_needs_confirmation: "アカウント情報を変更しました。変更されたメールアドレスの本人確認のため、本人確認用メールより確認処理をおこなってください。"
      updated: "アカウント情報を変更しました。"
    sessions:
      signed_in: "ログインしました。"
      signed_out: "ログアウトしました。"
      already_signed_out: "既にログアウト済みです。"
    unlocks:
      send_instructions: "アカウントの凍結解除方法を数分以内にメールでご連絡します。"
      send_paranoid_instructions: "アカウントが見つかった場合、アカウントの凍結解除方法を数分以内にメールでご連絡します。"
      unlocked: "アカウントを凍結解除しました。"
  errors:
    messages:
      already_confirmed: "は既に登録済みです。ログインしてください。"
      confirmation_period_expired: "の期限が切れました。%{period} までに確認する必要があります。 新しくリクエストしてください。"
      expired: "の有効期限が切れました。新しくリクエストしてください。"
      not_found: "は見つかりませんでした。"
      not_locked: "は凍結されていません。"
      not_saved:
        one: "エラーが発生したため %{resource} は保存されませんでした:"
        other: "%{count} 件のエラーが発生したため %{resource} は保存されませんでした:"
```

<br>
最後に、コンテナを再起動したら日本語化が反映されます。

## devise に関連するビューファイル群の作成

`rails generate devise:views`<br>
このコマンドを実行すると、以下のファイルが作成されます。

- app/views/devise/confirmations/new.html.erb
- app/views/devise/mailer/confirmation_instructions.html.erb
- app/views/devise/mailer/email_changed.html.erb
- app/views/devise/mailer/password_change.html.erb
- app/views/devise/mailer/reset_password_instructions.html.erb
- app/views/devise/mailer/unlock_instructions.html.erb
- app/views/devise/passwords/edit.html.erb
- app/views/devise/passwords/new.html.erb
- app/views/devise/registrations/edit.html.erb
- app/views/devise/registrations/new.html.erb
- app/views/devise/sessions/new.html.erb
- app/views/devise/shared/\_error_messages.html.erb
- app/views/devise/shared/\_links.html.erb
- app/views/devise/unlocks/new.html.erb

## devise に関連するコントローラファイル群の作成

`rails generate devise:controllers users -c sessions registrations`<br>
このコマンドを実行すると、特定の session コントローラと registrations コントローラファイルが作成されます。

- app/controllers/users/registrations_controller.rb
- app/controllers/users/sessions_controller.rb

## ルートルーティングの設定

ユーザー登録後やログイン後に遷移するリダイレクト先を設定します。<br>
`rails generate controller home top`<br>
このコードによって、以下のファイルが生成されます。<br>

- app/controllers/home_controller.rb
- app/helpers/home_helper.rb
- app/views/home/top.html.erb
- test/controllers/home_controller_test.rb
  <br>
  app/controllers/application_controller.rb に以下のコードを追記(ログイン後に遷移されるリダイレクト先を指定)<br>
  追記しないと「ActionController::ActionControllerError in Users::SessionsController#new Cannot redirect to nil!」というエラーが発生します。<br>

```
  def after_sign_in_path_for(resource)
    home_top_path
  end
```

<br><br>ログアウト後のリダイレクト先も追記します。

```
  def after_sign_out_path_for(resource)
    new_user_session_path
  end
```

<br><br>アクション前にユーザーのログイン状態を確認し、未ログインの場合はログインページにリダイレクトし、ログイン済みの場合は devise コントローラが機能するように以下のコードも追記します。

```
before_action :check_login, unless: :devise_controller?
# 省略
  private

  def check_login
    unless user_signed_in?
      redirect_to new_user_session_path
    end
  end
```

<br><br>完成後の app/controllers/application_controller.rb はこちらになります。<br>
https://github.com/NishimuraShiro/rails_Login_using_devise/blob/main/app/controllers/application_controller.rb

<br><br>config/routes.rb にログイン後のルートパスを指定するために以下のコードを追記します。<br>

```
get 'home/top', to: 'home#top', as: 'home_top'
```

<br>RESTfull なルートを定義するために以下のコードも追記します。<br>
`resources :users`<br>
完成後の config/routes.rb はこちらになります。<br>
https://github.com/NishimuraShiro/rails_Login_using_devise/blob/main/config/routes.rb
<br><br>app/views/home/top.html.erb (ログイン後に表示されるファイル)を以下のように修正します。<br>

```
<h1>Home#top</h1>
<%= "こんにちは #{current_user.email} さん" if user_signed_in? %>
<br>
<%= link_to "ログアウト", destroy_user_session_path, data: { turbo_method: :delete } %>
```

## ユーザー認証に必要な設定

config/initializers/devise.rb ファイルにある以下の一行をコメントアウトします。<br>

```
config.authentication_keys = [:email]
```

<br>この設定を行うことで、ユーザーの認証に使用されるキーを[:email] というパラメータとして使用できるようにしています。

## 参考文献

- https://autovice.jp/articles/169
- https://gist.github.com/satour/6c15f27211fdc0de58b4
- https://qiita.com/yuta-nos/items/3dbe8b453ab79a92b6d9
- https://qiita.com/newburu/items/64f214d2f0fbc7a05d42
