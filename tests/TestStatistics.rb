#!/usr/bin/ruby

require 'test/unit'
require './math/Statistics'
require './math/Constants'

class TestStatistics < Test::Unit::TestCase

  def testVarious
    statistics = Statistics.new

    assert_equal 0, statistics.numSamples
    assert_nil statistics.average
    assert_nil statistics.variance

    statistics.addSample 0.05458600
    assert_equal 1, statistics.numSamples
    assert_in_delta 0.05458600, statistics.average, Constants::Epsilon
    assert_nil statistics.variance

    statistics.addSample 0.81348628
    assert_equal 2, statistics.numSamples
    assert_in_delta 0.43403614, statistics.average, Constants::Epsilon
    assert_in_delta 0.28796482, statistics.variance, Constants::Epsilon

    statistics.addSample
    assert_equal 2, statistics.numSamples
    assert_in_delta 0.43403614, statistics.average, Constants::Epsilon
    assert_in_delta 0.28796482, statistics.variance, Constants::Epsilon

    statistics.addSample 0.88220526, 0.35875874, 0.17620300
    assert_equal 5, statistics.numSamples
    assert_in_delta 0.45704786, statistics.average, Constants::Epsilon
    assert_in_delta 0.13957932, statistics.variance, Constants::Epsilon

    statistics.addSample 
    assert_equal 5, statistics.numSamples
    assert_in_delta 0.45704786, statistics.average, Constants::Epsilon
    assert_in_delta 0.13957932, statistics.variance, Constants::Epsilon

    statistics.addSample [0.17847506]
    assert_equal 6, statistics.numSamples
    assert_in_delta 0.41061906, statistics.average, Constants::Epsilon
    assert_in_delta 0.12459726, statistics.variance, Constants::Epsilon

    statistics.addSample [0.08428419, 0.49209874, 0.10103090, 0.37973676]
    assert_equal 10, statistics.numSamples
    assert_in_delta 0.35208649, statistics.average, Constants::Epsilon
    assert_in_delta 0.08873974, statistics.variance, Constants::Epsilon

    statistics.addSample 0.71053677
    statistics.addSample [0.36557013]
    statistics.addSample 0.96560734
    statistics.addSample [0.55903829, 0.45389139]
    statistics.addSample 0.32161783
    statistics.addSample 0.81633543
    statistics.addSample 0.94628139
    statistics.addSample 0.23900876
    statistics.addSample 0.61306038
    assert_equal 20, statistics.numSamples
    assert_in_delta 0.47559063, statistics.average, Constants::Epsilon
    assert_in_delta 0.08959361, statistics.variance, Constants::Epsilon

    string1 = statistics.to_s
    assert_equal "<stats:#=20:avg=0.47559063:var=0.08959361:avg^2=0.31130038>", string1

    statistics.reset
    assert_equal 0, statistics.numSamples
    assert_nil statistics.average
    assert_nil statistics.variance
    assert_equal "<stats:#=0:avg=:var=:avg^2=>", statistics.to_s

    statistics = Statistics.new string1
    assert_equal 20, statistics.numSamples
    assert_in_delta 0.47559063, statistics.average, Constants::Epsilon
    assert_in_delta 0.08959361, statistics.variance, Constants::Epsilon
    assert_equal string1, statistics.to_s(8)
  end
end
