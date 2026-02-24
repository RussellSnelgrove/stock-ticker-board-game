# frozen_string_literal: true

class GamesController < ApplicationController
  def index
    if current_user
      @games = Game.active.includes(:host, :players).order(created_at: :desc)
    end
  end
end
