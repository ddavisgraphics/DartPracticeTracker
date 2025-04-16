# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @player = users(:player_user)
    @admin = users(:admin_user)
  end

  test 'should have valid fixtures' do
    assert @player.valid?
    assert @admin.valid?
  end

  test 'should have correct roles' do
    assert_equal 'player', @player.role
    assert_equal 'admin', @admin.role
  end

  test 'should impersonate correctly' do
    Thread.current[:impersonator] = @admin
    assert_equal @admin, @player.impersonated_by
  ensure
    Thread.current[:impersonator] = nil
  end
end
