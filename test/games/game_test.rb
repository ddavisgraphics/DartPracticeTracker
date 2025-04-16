require "test_helper"

class GameTest < ActiveSupport::TestCase
  setup do
    @user = users(:player_user)
    @game = Game.new(@user)
  end

  test "initializes with default values" do
    assert_equal @user, @game.user
    assert_equal 501, @game.start_game_score
    assert_equal [], @game.turns
  end

  test "#game_score returns difference between start_game_score and sum of turns" do
    @game.send(:instance_variable_set, :@turns, [{score: 60, darts: 3}, {score: 60, darts: 3}])
    assert_equal 381, @game.game_score # 501 - 120
  end

  test "#game_score returns start_game_score when no turns recorded" do
    assert_equal 501, @game.game_score
  end

  test "#record_turn with valid score adds to turns" do
    result = @game.record_turn(60)
    assert_equal [{score: 60, darts: 3}], @game.turns
    assert_equal :OK, result[:status]
  end

  test "#record_turn with custom dart count" do
    @game.record_turn(60, number_of_darts: 2)
    assert_equal [{score: 60, darts: 2}], @game.turns
  end

  test "#record_turn with invalid score doesn't add to turns" do
    @game.record_turn(181) # Too high
    assert_equal [], @game.turns

    @game.record_turn(-1) # Negative
    assert_equal [], @game.turns

    @game.record_turn("not a number") # Not an integer
    assert_equal [], @game.turns
  end

  test "#record_turn with bust score adds 0 to turns" do
    @game.send(:instance_variable_set, :@turns, [{score: 180, darts: 3}, {score: 180, darts: 3}])
    @game.record_turn(180) # Bust - more than remaining
    assert_equal [{score: 180, darts: 3}, {score: 180, darts: 3}, {score: 0, darts: 3}], @game.turns
  end

  test "#record_turn returns correct feedback for valid score" do
    result = @game.record_turn(60)
    assert_equal :OK, result[:status]
    assert_equal "441 left", result[:message]
  end

  test "#record_turn invalid for single turn score" do
    @game.send(:instance_variable_set, :@turns, [{score: 100, darts: 3}])
    result = @game.record_turn(400) # invalid score max score is 180
    assert_equal :INVALID, result[:status]
    assert_match /Invalid score/, result[:message]
  end

  test "#record_turn handles bust" do
    @game.send(:instance_variable_set, :@turns, [{score: 180, darts: 3}, {score: 180, darts: 3}])
    result = @game.record_turn(144)
    assert_equal :BUST, result[:status]
    assert_match /You busted! 141 left/, result[:message]
  end

  test "#record_turn handles potential checkout scores" do
    # Set up game with 40 remaining (can checkout)
    @game.send(:instance_variable_set, :@turns, [{score: 461, darts: 3}])
    result = @game.record_turn(10)
    assert_equal :CHECKOUT, result[:status]
  end

  test "perfect game - nine dart finish" do
    # A perfect 501 game is completed in 9 darts - 180, 180, 141
    result1 = @game.record_turn(180, number_of_darts: 3)
    assert_equal :OK, result1[:status]
    assert_equal 321, @game.game_score

    result2 = @game.record_turn(180, number_of_darts: 3)
    assert_equal :CHECKOUT, result2[:status]
    assert_equal 141, @game.game_score

    result3 = @game.record_turn(141, number_of_darts: 3)
    assert_equal :COMPLETED, result3[:status]
    assert_equal 0, @game.game_score

    # Verify all turns were recorded correctly
    assert_equal 3, @game.turns.size
    assert_equal 501, @game.total_score

    # Test the three dart average is a perfect 167 (501 ÷ 3)
    assert_in_delta 55.7, @game.send(:points_per_dart), 0.1
    assert_equal 167.1, @game.send(:three_dart_average)
  end

  test "three_dart_average calculates correctly with varying dart counts" do
    @game.record_turn(60, number_of_darts: 3)
    @game.record_turn(100, number_of_darts: 2)
    @game.record_turn(45, number_of_darts: 1)

    # Total points: 205, Total darts: 6
    # Normalized to 3-dart average: 205 / 6 * 3 = 102.5
    assert_in_delta 102.5, @game.send(:three_dart_average), 0.1
  end

  test "points_per_dart calculates correctly" do
    @game.record_turn(60, number_of_darts: 3)
    @game.record_turn(100, number_of_darts: 2)
    # Total: 160 points from 5 darts = 32 points/dart
    assert_in_delta 32.0, @game.send(:points_per_dart), 0.1
  end

  test "three_dart_average handles empty turns" do
    assert_equal 0.0, @game.send(:three_dart_average)
  end

  test "points_per_dart handles empty turns" do
    assert_equal 0.0, @game.send(:points_per_dart)
  end

  test "valid_score? validates correctly" do
    assert @game.send(:valid_score?, 0)
    assert @game.send(:valid_score?, 60)
    assert @game.send(:valid_score?, 180)

    refute @game.send(:valid_score?, -1)
    refute @game.send(:valid_score?, 181)
    refute @game.send(:valid_score?, "60")
  end

  test "bust? detects bust correctly" do
    @game.send(:instance_variable_set, :@turns, [{score: 450, darts: 3}]) # 51 remaining

    refute @game.send(:bust?, 51) # Not a bust
    assert @game.send(:bust?, 52) # Bust
  end

  test "game_completed? detects completion correctly" do
    @game.send(:instance_variable_set, :@turns, [{score: 450, darts: 3}]) # 51 remaining

    refute @game.send(:game_completed?, 50) # Not complete
    refute @game.send(:game_completed?, 52) # Not complete (bust)
    assert @game.send(:game_completed?, 51) # Complete
  end

  test "checkout? validates possible checkout scores" do
    # Possible checkout scores
    assert @game.send(:checkout?, 40)
    assert @game.send(:checkout?, 36)
    assert @game.send(:checkout?, 170) # Highest possible checkout

    # Impossible checkout scores
    refute @game.send(:checkout?, 1)
    refute @game.send(:checkout?, 159)
    refute @game.send(:checkout?, 169)
    refute @game.send(:checkout?, 171) # Too high
  end

  test "handles typo in initialize method name" do
    # The method is misspelled as "initalize" instead of "initialize"
    # This test ensures that despite the typo, objects are created properly
    assert_nothing_raised do
      Game.new(@user)
    end
  end

  test "edge case - exactly 501 points scored in one turn" do
    # This should be invalid as it exceeds maximum score of 180
    result = @game.record_turn(501)
    assert_equal :INVALID, result[:status]
    assert_equal [], @game.turns
  end

  test "edge case - exactly 180 points scored" do
    result = @game.record_turn(180)
    assert_equal :OK, result[:status]
    assert_equal 321, @game.game_score
    assert_equal [{score: 180, darts: 3}], @game.turns
  end

  test "edge case - one remaining point (impossible checkout)" do
    @game.send(:instance_variable_set, :@turns, [{score: 500, darts: 3}]) # 1 remaining
    result = @game.record_turn(1)

    assert_equal :INVALID_CHECKOUT, result[:status]
  end

  test "edge case - 159 remaining point (impossible checkout)" do
    @game.send(:instance_variable_set, :@turns, [{score: 342, darts: 3}]) # 1 remaining
    result = @game.record_turn(159)

    assert_equal :INVALID_CHECKOUT, result[:status]
    assert_match /You must finish with a double out!/, result[:message]
    assert_match /Score reset to 159./, result[:message]
  end

  test 'edge case - scores can not leave one' do
    @game.send(:instance_variable_set, :@turns, [{score: 401, darts: 3}]) # 1 remaining
    result = @game.record_turn(99)

    assert_equal :BUST, result[:status]
    assert_match /You busted! 100 left/, result[:message]
  end

  test "edge case - impossible checkout scores" do
    Game::IMPOSSIBLE_CHECKOUTS.each do |score|
      refute @game.send(:checkout?, score), "Score #{score} should not be a valid checkout"
    end
  end

  test "edge case - zero score turn" do
    result = @game.record_turn(0)
    assert_equal :OK, result[:status]
    assert_equal [{score: 0, darts: 3}], @game.turns
    assert_equal 501, @game.game_score
  end

  test "edge case - tracking darts when finishing game" do
    # Get to 2 remaining (a valid checkout)
    @game.send(:instance_variable_set, :@turns, [{score: 499, darts: 3}])

    # Finish with 2, using only 1 dart for the double 1
    result = @game.record_turn(2, number_of_darts: 1)
    assert_equal :COMPLETED, result[:status]
    assert_equal 0, @game.game_score

    # Check the dart count was preserved
    assert_equal 1, @game.turns.last[:darts]
  end
end