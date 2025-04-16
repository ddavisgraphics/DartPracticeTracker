# frozen_string_literal: true

class FiveZeroOne
  attr_reader :user, :double_in, :double_out, :start_game_score

  def initalize(user:, double_in: false, double_out: true, start_game_score: 501)
    @user = user
    @double_in = double_in
    @double_out = double_out
    @start_game_score = start_game_score
    @turns = []
  end

  def record_turn(_score)
    'FINISHED' if game_completed?
  end

  private

  # @return [Boolean]
  def game_completed?
    turns.sum(&:score) == start_game_score
  end

  # @return [Boolean]
  def valid_score?(current_score)
    current_score.is_a?(Integer) && current_score.between?(0, 180)
  end
end
