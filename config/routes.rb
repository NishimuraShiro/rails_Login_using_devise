Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  # ログイン後のルートパス(以下の1行を外すとルートエラー発生)
  get 'home/top', to: 'home#top', as: 'home_top'
  
  # RESTful(Webサービスのデザインアーキテクチャの一種)なルート定義
  resources :users

  # 以下のコードにより、パスを変えることができるようになる。http://localhost:4000/sign_in
  # devise_scope :user do
  #   get '/sign_in', to: 'users/sessions#new'
  # end
end
