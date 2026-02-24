# frozen_string_literal: true

module Types
  class RankingType < Types::BaseObject
    field :player_id, ID, null: false
    field :display_name, String, null: false
    field :net_worth, Integer, null: false
  end
end
