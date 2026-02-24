# frozen_string_literal: true

class SessionsController < ApplicationController
  def create
    display_name = params[:display_name].to_s.strip
    if display_name.blank? || display_name.length > 20
      redirect_to root_path, alert: "Please enter a name (1-20 characters)"
      return
    end

    user = User.find_or_create_by!(display_name: display_name)
    session[:user_id] = user.id
    redirect_to root_path
  end
end
