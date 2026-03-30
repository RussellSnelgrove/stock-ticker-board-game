# typed: true
# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    sig { void }
    def connect
      self.current_user = find_verified_user
    end

    private

    sig { returns(T.untyped) }
    def find_verified_user
      user_id = request.session[:user_id]
      User.find(user_id)
    rescue ActiveRecord::RecordNotFound
      reject_unauthorized_connection
    end
  end
end
