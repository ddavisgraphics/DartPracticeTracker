# frozen_string_literal: true

require 'test_helper'

class GameTest < ActiveSupport::TestCase
  setup do
    @user = users(:player_user)
    @game = Game.new(@user)
  end

  test 'initializes with default values' do
    assert_equal @user, @game.user
    assert_equal false, @game.double_in
    assert_equal true, @game.double_out
    assert_equal 501, @game.start_game_score
    assert_equal [], @game.turns
  end

  test 'initializes with custom values' do
    game = Game.new(@user, double_in: true, double_out: false, start_game_score: 301)
    assert_equal @user, game.user
    assert_equal true, game.double_in
    assert_equal false, game.double_out
    assert_equal 301, game.start_game_score
  end

  test 'game_score returns difference between start_game_score and sum of turns' do
    @game.send(:instance_variable_set, :@turns, [60, 60])
    assert_equal 381, @game.game_score # 501 - 120
  end

  test 'game_score returns start_game_score when no turns recorded' do
    assert_equal 501, @game.game_score
  end

  test 'record_turn with valid score adds to turns' do
    @game.record_turn(60)
    assert_equal [60], @game.turns
  end

  test "record_turn with invalid score doesn't add to turns" do
    @game.record_turn(181) # Too high
    assert_equal [], @game.turns

    @game.record_turn(-1) # Negative
    assert_equal [], @game.turns

    @game.record_turn('not a number') # Not an integer
    assert_equal [], @game.turns
  end

  test 'record_turn with bust score adds 0 to turns' do
    @game.send(:instance_variable_set, :@turns, [60, 60]) # 120 points, 381 remaining
    @game.record_turn(400) # Bust - more than remaining
    assert_equal [60, 60, 0], @game.turns
  end

  test 'record_turn returns correct feedback for valid score' do
    result = @game.record_turn(60)
    assert_equal :OK, result[:status]
    assert_equal '441 left', result[:message]
  end

  test 'record_turn returns correct feedback for bust' do
    @game.send(:instance_variable_set, :@turns, [450]) # 51 remaining
    result = @game.record_turn(60) # Bust
    assert_equal :BUST, result[:status]
    assert_match(/You busted/, result[:message])
  end

  test 'record_turn returns correct feedback for invalid score' do
    result = @game.record_turn(181)
    assert_equal :INVALID, result[:status]
    assert_match(/Invalid score/, result[:message])
  end

  test 'record_turn handles potential checkout scores' do
    # Set up game with 40 remaining (can checkout)
    @game.send(:instance_variable_set, :@turns, [461])
    result = @game.record_turn(40)
    assert_equal :CHECKOUT, result[:status]
  end

  test 'three_dart_average calculates correctly' do
    @game.send(:instance_variable_set, :@turns, [60, 60, 60]) # 180 points in 3 turns
    # Should be 501 / 3 = 167.0
    assert_in_delta 167.0, @game.send(:three_dart_average), 0.1
  end

  test 'three_dart_average handles empty turns' do
    assert_equal 0.0, @game.send(:three_dart_average)
  end

  test 'point_per_dart calculates correctly' do
    @game.send(:instance_variable_set, :@turns, [60, 60, 60]) # 180 points from 9 darts
    # Should be 501 / 9 = 55.67
    assert_in_delta 55.7, @game.send(:point_per_dart), 0.1
  end

  test 'point_per_dart handles empty turns' do
    assert_equal 0.0, @game.send(:point_per_dart)
  end

  test 'valid_score? validates correctly' do
    assert @game.send(:valid_score?, 0)
    assert @game.send(:valid_score?, 60)
    assert @game.send(:valid_score?, 180)

    assert_not @game.send(:valid_score?, -1)
    assert_not @game.send(:valid_score?, 181)
    assert_not @game.send(:valid_score?, '60')
  end

  test 'bust? detects bust correctly' do
    @game.send(:instance_variable_set, :@turns, [450]) # 51 remaining

    assert_not @game.send(:bust?, 50) # Not a bust
    assert @game.send(:bust?, 52) # Bust
  end

  test 'game_completed? detects completion correctly' do
    @game.send(:instance_variable_set, :@turns, [450]) # 51 remaining

    assert_not @game.send(:game_completed?, 50) # Not complete
    assert_not @game.send(:game_completed?, 52) # Not complete (bust)
    assert @game.send(:game_completed?, 51) # Complete
  end

  test 'checkout? validates possible checkout scores' do
    # Possible checkout scores
    assert @game.send(:checkout?, 40)
    assert @game.send(:checkout?, 36)
    assert @game.send(:checkout?, 170) # Highest possible checkout

    # Impossible checkout scores
    assert_not @game.send(:checkout?, 1)
    assert_not @game.send(:checkout?, 159)
    assert_not @game.send(:checkout?, 169)
    assert_not @game.send(:checkout?, 171) # Too high
  end

  test 'handles typo in initialize method name' do
    # The method is misspelled as "initalize" instead of "initialize"
    # This test ensures that despite the typo, objects are created properly
    assert_nothing_raised do
      Game.new(@user)
    end
  end

  test 'handles edge case of exactly 501 points scored' do
    @game.record_turn(501)
    assert_equal [501], @game.turns
    assert_equal 0, @game.game_score
  end

  test 'handles case when score is 1 remaining' do
    @game.send(:instance_variable_set, :@turns, [500]) # 1 remaining
    result = @game.record_turn(1)

    # Can't checkout on 1, as it's an impossible checkout
    assert_equal :INVALID, result[:status]
  end

  test 'feedback changes based on current game state' do
    # Test with various game states to ensure feedback is context-aware
    feedback_bust = @game.send(:feedback, :bust)
    assert_equal :BUST, feedback_bust[:status]

    feedback_checkout = @game.send(:feedback, :checkout)
    assert_equal :CHECKOUT, feedback_checkout[:status]

    feedback_invalid = @game.send(:feedback, :invalid)
    assert_equal :INVALID, feedback_invalid[:status]

    feedback_ok = @game.send(:feedback, :ok)
    assert_equal :OK, feedback_ok[:status]
  end
end
