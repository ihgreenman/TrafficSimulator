#!/usr/bin/ruby -w

require 'test/unit'
require './math/Probability'

class TestProbability < Test::Unit::TestCase

  def testConstruction
    assert_raise ArgumentError do
      a = Probability.new Vector[0.5, 0.1, 0, 0.5]
      a.choose()
    end

    assert_raise ArgumentError do
      a = Probability.new [0.5, 0.1, 0, 0.5], ["a", "b", "c"]
      a.choose()
    end

    a = Probability.new [1.0, 0.0, 0.0, 0.0]
    a.choose()
    a = Probability.new Vector[0.5, 0.1, 0.0, 0.4], ["a", "b", "c", "d"]
    a.choose()
  end

  def testChoose
    srand(0xd1ce)

    p = Probability.new Vector[0.4, 0.2, 0.25, 0.1, 0.05]
    v = [0, 0, 2, 0, 0, 4, 0, 4, 2, 1, 0, 4, 3, 0, 0, 3, 4, 4, 0, 3, 2, 2, 0, 0, 2, 4, 1, 2]

    v.each do |i|
      assert_equal(i, p.choose[0])
    end
  end

  def testNormal
    # tests creation of a normal distribution
    # 
    # 0.1914624612740131036377046106
    # 0.1498822847945298449475279350
    # 0.09184805266259898541027341340
    # 0.04405706932067885880421140380
    # 0.02275013194817920720028263719

    test1 = Probability.normal(60, 2, "to_i", 55, 1, 64)
    assert_not_nil(test1)
    assert_equal(10, test1.probabilities.size)

    assert_in_delta(0.022750, test1[55], Constants::Epsilon)
    assert_in_delta(0.044057, test1[56], Constants::Epsilon)
    assert_in_delta(0.091848, test1[57], Constants::Epsilon)
    assert_in_delta(0.149882, test1[58], Constants::Epsilon)
    assert_in_delta(0.191462, test1[59], Constants::Epsilon)
    assert_in_delta(0.191462, test1[60], Constants::Epsilon)
    assert_in_delta(0.149882, test1[61], Constants::Epsilon)
    assert_in_delta(0.091848, test1[62], Constants::Epsilon)
    assert_in_delta(0.044057, test1[63], Constants::Epsilon)
    assert_in_delta(0.022750, test1[64], Constants::Epsilon)

  end
end
