# typed: strict
# frozen_string_literal: true

class ApplicationController < ActionController::Base
  extend T::Sig

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  sig { returns(T.nilable(User)) }
  def current_user
    return nil unless session[:user_id]

    User.find_by(id: session[:user_id])
  end
end
