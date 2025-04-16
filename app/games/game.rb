# frozen_string_literal: true

class Game
  attr_reader :user, :start_game_score, :turns

  IMPOSSIBLE_CHECKOUTS = [1, 159, 162, 163, 165, 166, 168, 169].freeze

  # @param user [User] The user playing the game
  # @param start_game_score [Integer] Starting score for the game
  # @return [Game] New game instance
  def initialize(user, start_game_score: 501)
    @user = user
    @start_game_score = start_game_score
    @turns = []
  end

  # @return [Integer] Current remaining score
  def game_score
    start_game_score - total_score
  end

  # @return [Integer] Total score from all turns
  def total_score
    turns.sum { |turn| turn[:score] }
  end

  # @param score [Integer] Score for this turn
  # @return [Hash] Feedback hash with status and message
  def record_turn(score, number_of_darts: 3)
    return feedback(:invalid) unless valid_score?(score)

    if !bust?(score) && !game_completed?(score)
      turns << { score: score, darts: number_of_darts }
      checkout?(game_score) ? feedback(:checkout) : feedback(:ok)
    elsif bust?(score) && !game_completed?(score)
      turns << { score: 0, darts: number_of_darts }
      feedback(:bust)
    elsif game_completed?(score) && checkout?(score)
      turns << { score: score, darts: number_of_darts}
      feedback(:completed)
    else
      turns << { score: 0, darts: number_of_darts }
      feedback(:invalid_checkout)
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
      { status: :INVALID, message: 'Invalid score, please enter your score again.' }
    when :invalid_checkout
      { status: :INVALID_CHECKOUT, message: "You must finish with a double out! Score reset to #{game_score}." }
    when :completed
      { status: :COMPLETED, message: 'Game completed! Saving your scores!' }
    else
      { status: :OK, message: "#{game_score} left" }
    end
  end

  private

  # @return [Float]
  def three_dart_average
    (points_per_dart * 3).round(1)
  end

  # @return [Float]
  def points_per_dart
    return 0.0 if turns.empty?

    total_darts = turns.sum { |turn| turn[:darts] }
    (total_score.to_f / total_darts).round(1)
  end

  # @return [Boolean]
  def valid_score?(current_score)
    return false unless current_score.is_a?(Integer)

    current_score.between?(0, 180)
  end

  # @param current_score [Integer]
  # @return [Boolean]
  def bust?(current_score)
    return false unless valid_score?(current_score)
    return true if one_left?(current_score)

    total_score + current_score > start_game_score
  end

  # @param current_score [Integer]
  # @return [Boolean]
  def one_left?(current_score)
    (start_game_score - (total_score + current_score)) == 1
  end

  # @return [Boolean]
  def game_completed?(current_score)
    return false unless valid_score?(current_score)

    total_score + current_score == start_game_score
  end

  # @return [Boolean]
  def checkout?(current_score)
    return false unless valid_score?(current_score)

    current_score.between?(2, 170) && IMPOSSIBLE_CHECKOUTS.exclude?(current_score)
  end
end
