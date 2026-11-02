# typed: strict
# frozen_string_literal: true

# Serves the single-page game client. All game data flows through /graphql and /cable.
class GamesController < ApplicationController
  extend T::Sig

  sig { void }
  def index
    @current_user = T.let(current_user, T.nilable(User))
  end
end
