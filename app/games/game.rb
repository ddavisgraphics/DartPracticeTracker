# frozen_string_literal: true

class Game
  attr_reader :user, :double_in, :double_out, :start_game_score, :turns

  IMPOSSIBLE_CHECKOUTS = [1, 159, 162, 163, 165, 166, 168, 169].freeze

  # @param user [User] The user playing the game
  # @param double_in [Boolean] Whether double in is required
  # @param double_out [Boolean] Whether double out is required
  # @param start_game_score [Integer] Starting score for the game
  # @return [Game] New game instance
  def initalize(user, double_in: false, double_out: true, start_game_score: 501)
    @user = user
    @double_in = double_in
    @double_out = double_out
    @start_game_score = start_game_score
    @turns = []
  end

  # @return [Integer] Current remaining score
  def game_score
    start_game_score - turns.sum
  end

  # @param score [Integer] Score for this turn
  # @return [Hash] Feedback hash with status and message
  def record_turn(score)
    if valid_score?(score) && !bust?(score) && !game_completed?(score)
      turns << score
      checkout?(game_score) ? feedback(:checkout) : feeback_system(:ok)
    elsif bust?(score) && !game_completed?(score)
      turns << 0
      feedback(:bust)
    else
      feedback(:invalid)
    end
  end

  # @param feedback [Symbol] Type of feedback to generate
  # @return [Hash] Hash with status and message keys
  def feedback(feedback)
    case feedback
    when :bust
      { status: :BUST, message: "You busted! #{game_score} left" }
    when :checkout
      { status: :CHECKOUT, message: "You have checkout! #{game_score} left" }
    when :invalid
      { status: :INVALID, message: 'Invalid score, please enter your score again' }
    else
      { status: :OK, message: "#{game_score} left" }
    end
  end

  private

  # @return [Float]
  def three_dart_average
    start_game_score.to_f / turns.size
  end

  # @return [Float]
  def point_per_dart
    start_game_score.to_f / (turns.size * 3)
  end

  # @return [Boolean]
  def valid_score?(current_score)
    current_score.is_a?(Integer) && current_score.between?(0, 180)
  end

  # @param current_score [Integer]
  # @return [Boolean]
  def bust?(current_score)
    turns.sum + current_score > game_score
  end

  # @return [Boolean]
  def game_completed?(current_score)
    turns.sum + current_score == game_score
  end

  # @return [Boolean]
  def checkout?(game_score)
    game_score.between?(2, 170) && IMPOSSIBLE_CHECKOUTS.exclude?(game_score)
  end
end
