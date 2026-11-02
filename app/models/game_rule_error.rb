# typed: strict
# frozen_string_literal: true

# Raised when a player action breaks a game rule. The message is safe to show to players.
class GameRuleError < RuntimeError; end
