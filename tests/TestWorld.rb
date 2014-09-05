#!/usr/bin/ruby

require 'test/unit'
require './model/World'

class TestWorld < Test::Unit::TestCase

  def testTime
    World.reset
    assert_equal(0, World.time)
    World.tick
    assert_equal(1, World.time)
    World.tick
    assert_equal(2, World.time)
  end
end
