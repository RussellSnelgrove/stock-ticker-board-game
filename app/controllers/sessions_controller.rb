# typed: strict
# frozen_string_literal: true

# Players pick a display name instead of logging in. The name is tied to the browser session.
class SessionsController < ApplicationController
  extend T::Sig

  sig { void }
  def create
    user = User.new(display_name: params[:display_name].to_s.strip)
    if user.save
      reset_session
      session[:user_id] = user.id
      redirect_to root_path
    else
      redirect_to root_path, alert: user.errors.full_messages.to_sentence
    end
  end

  sig { void }
  def destroy
    reset_session
    redirect_to root_path
  end
end
