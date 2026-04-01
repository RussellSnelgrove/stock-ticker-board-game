# typed: strict
# frozen_string_literal: true

class User < ApplicationRecord
  validates :display_name, presence: true
end
