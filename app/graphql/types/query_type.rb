# typed: true
# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    extend T::Sig
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [ Types::NodeType, null: true ], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ ID ], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :game, Types::GameType, null: true,
      description: "Fetch a single game by ID or invite code" do
      argument :id, ID, required: false
      argument :invite_code, String, required: false
    end
    sig { params(id: T.nilable(String), invite_code: T.nilable(String)).returns(T.nilable(Game)) }
    def game(id: nil, invite_code: nil)
      raise GraphQL::ExecutionError, "Provide id or invite_code" if id.nil? && invite_code.nil?

      if id
        Game.find_by(id: id)
      else
        Game.find_by(invite_code: invite_code)
      end
    end

    field :games, [ Types::GameType ], null: false,
      description: "List games in waiting or in_progress status"
    sig { returns(ActiveRecord::Relation) }
    def games
      Game.where(status: [ :waiting, :in_progress ]).order(created_at: :desc)
    end

    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    sig { returns(String) }
    def test_field
      "Hello World!"
    end
  end
end
