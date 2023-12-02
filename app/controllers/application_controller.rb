class ApplicationController < ActionController::Base
  before_action :check_login, unless: :devise_controller?
  # ログインのリダイレクト先
  def after_sign_in_path_for(resource)
    # 以下のコードを外すと「ActionController::ActionControllerError in Users::SessionsController#new Cannot redirect to nil!」
    home_top_path
  end

  # ログアウトのリダイレクト先
  def after_sign_out_path_for(resource)
    new_user_session_path
  end

  private
  # ユーザーのログイン状態を確認し、未ログインの場合はログインページにリダイレクト
  def check_login
    unless user_signed_in?
      redirect_to new_user_session_path
    end
  end
end
