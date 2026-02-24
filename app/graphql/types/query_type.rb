# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, null: true], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ID], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    field :games, [Types::GameType], null: false, description: "List available and active games" do
      argument :status, String, required: false
    end

    def games(status: nil)
      scope = Game.includes(:host, players: :user)
      status ? scope.where(status: status) : scope.active
    end

    field :game, Types::GameType, null: true, description: "Fetch a single game by ID or invite code" do
      argument :id, ID, required: false
      argument :invite_code, String, required: false
    end

    def game(id: nil, invite_code: nil)
      if id
        Game.find_by(id: id)
      elsif invite_code
        Game.find_by(invite_code: invite_code.upcase)
      end
    end

    field :me, Types::PlayerType, null: true, description: "Current user's player record in a game" do
      argument :game_id, ID, required: true
    end

    def me(game_id:)
      return nil unless context[:current_user]
      Player.find_by(user: context[:current_user], game_id: game_id)
    end

    field :transactions, [Types::GameTransactionType], null: false, description: "Transaction history for a game" do
      argument :game_id, ID, required: true
      argument :limit, Integer, required: false
      argument :offset, Integer, required: false
    end

    def transactions(game_id:, limit: 50, offset: 0)
      GameTransaction
        .for_game(Game.find(game_id))
        .recent_first
        .limit([limit, 100].min)
        .offset(offset)
        .includes(:player, game_stock: :stock)
    end
  end
end
