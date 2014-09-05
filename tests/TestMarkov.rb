#!/usr/bin/ruby -w

require 'test/unit'
require './math/Markov'
require './math/Constants'

class TestMarkov < Test::Unit::TestCase

  def testConstruction
    assert_raise ArgumentError do
      a = Markov.new Matrix[[1, 0, 0], [0, 1, 0]]
      a.nextState()
    end

    assert_raise ArgumentError do
      a = Markov.new Matrix[[1, 0, 0.5], [0, 1, 0], [1, 0, 0.5]]
      a.nextState()
    end

    a = Markov.new Matrix[[1.0, 0.0, 0.5], [0.0, 1.0, 0.0], [0.0, 0.0, 0.5]]
    a.nextState()
  end

  def checkVector(good, result)
    assert_equal(good.size, result.size)

    good.each2(result) { |g,r| assert_in_delta g, r, Constants::Epsilon }
  end

  def testProbabilities
    m = Markov.new(Matrix[[0.6, 0.0, 0.2], [0.1, 0.5, 0.3], [0.3, 0.5, 0.5]])
    result = m.getProbabilities(Vector[0.1, 0.3, 0.6])
    checkVector(Vector[0.18, 0.34, 0.48], result)
  end

  def testChoose
    srand(0xd1ce);

    m = Markov.new(Matrix[[0.6, 0.0, 0.2], [0.1, 0.5, 0.3], [0.3, 0.5, 0.5]])

    assert_equal(0, m.state)
    assert_equal(0, m.nextState)
    assert_equal(0, m.state)
    assert_equal(0, m.nextState)
    assert_equal(0, m.state)
    assert_equal(2, m.nextState)
    assert_equal(2, m.state)
    assert_equal(1, m.nextState)
    assert_equal(1, m.state)
    assert_equal(1, m.nextState)
    assert_equal(1, m.state)
    assert_equal(2, m.nextState)
    assert_equal(2, m.state)
    assert_equal(0, m.nextState)
    assert_equal(0, m.state)
    assert_equal(2, m.nextState)
    assert_equal(2, m.state)
  end
end
