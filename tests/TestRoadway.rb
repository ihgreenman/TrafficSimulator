#!/usr/bin/ruby -w

require 'test/unit'
require './model/Roadway'
require './math/Constants'

class TestRoadway < Test::Unit::TestCase

  def setup
    Lane.reset
  end

  def testSetup
    setup = [
      "# test comment",
      "",
      "lane test1 1500   1 60_MPH    500    0 60_MPH absorb 500",
      "lane test2 2500   2 60_MPH   1000.5  0 60_MPH absorb 1000.5",
      "lane test3  300.5 1 65_MPH    150   15 55_MPH feeds  test1 390.5",
      "lane test4  300.5 1 60.5_MPH    0    0 60_MPH absorb 1500",
      "",
      "next_to test1 250 test2 500 750",
      "next_to test1 100 test3 10 290",
      "next_to test1 2100 test4 10 390",
      "",
      "feed_rate 5.1 60",
      "feed_rate 2.2 61",
      "feed_rate 3.3 62",
      "",
      "exit_to test2 test1 test3 1100 1200",
      "",
      "name roadway_test"
    ]

    r = Roadway.new(setup)

    lane1 = Lane.find("test1")
    lane2 = Lane.find("test2")
    lane3 = Lane.find("test3")
    lane4 = Lane.find("test4")

    # Lane config
    lanes = [
      ["test1", 1500, 1, 60.0,  500.0,  0, 60,   nil,     nil,   0.0,  500.0],
      ["test2", 2500, 2, 60.0, 1000.5,  0, 60,   nil,     nil,   0.0, 1000.5],
      ["test3",  300, 1, 65.0,  150.0, 15, 55, lane1, "test1", 390.5,    0.0],
      ["test4",  300, 1, 60.5,    0.0,  0, 60,   nil,     nil,   0.0, 1500.0],
    ]

    assert_equal(4, Lane.allLanes.size)

    lanes.each do |lane| 
      t = Lane.find(lane[0]);
      assert_not_nil(t);

      assert_equal(lane[ 0], t.name);
      assert_equal(lane[ 1], t.length);
      assert_equal(lane[ 2], t.minPassengers);
      assert_equal(lane[ 3], t.speedLimit.mph);
      assert_equal(lane[ 4], t.generate);
      assert_equal(lane[ 5], t.meterRate);
      assert_equal(lane[ 6], t.initialSpeed.mph);
      if (lane[7])
        assert_equal(lane[ 7], t.feeds);
        assert_equal(lane[ 8], t.feedsName);
        assert_equal(lane[ 9], t.feedsDistance);
      else
        assert_equal(lane[10], t.absorb);
      end
    end

    # Next To
    assert_equal(3, lane1.nextTo.size)
    assert_equal(1, lane2.nextTo.size)
    assert_equal(1, lane3.nextTo.size)
    assert_equal(1, lane4.nextTo.size)

    assert_equal(250..1000,  lane1.nextTo[lane2].range)
    assert_equal(100..390,   lane1.nextTo[lane3].range)
    assert_equal(2100..2490, lane1.nextTo[lane4].range)

    assert_equal(500..1250,  lane2.nextTo[lane1].range)
    assert_equal(10..300,    lane3.nextTo[lane1].range)
    assert_equal(10..400,    lane4.nextTo[lane1].range)

    # Car insertion rate(s)

    assert_equal(4, r.rate.size)

    assert_in_delta(5.1, r.rate[0][0], Constants::Epsilon)
    assert_equal(60, r.rate[0][1])

    assert_in_delta(2.2, r.rate[1][0], Constants::Epsilon)
    assert_equal(61, r.rate[1][1])

    assert_in_delta(3.3, r.rate[2][0], Constants::Epsilon)
    assert_equal(62, r.rate[2][1])

    assert_equal(nil, r.rate[3][0])

#    print ":: ", Lane.generate.probabilities, "\n"

    assert_equal(3, Lane.generate.probabilities.size)
    assert_in_delta(0.3029385, Lane.generate[lane1], Constants::Epsilon)
    assert_in_delta(0.6061799, Lane.generate[lane2], Constants::Epsilon)
    assert_in_delta(0.0908815, Lane.generate[lane3], Constants::Epsilon)
    assert_in_delta(0.0,       Lane.generate[lane4], Constants::Epsilon)

    assert_equal(3, Lane.absorb.probabilities.size)
    assert_in_delta(0.1666389, Lane.absorb[lane1], Constants::Epsilon)
    assert_in_delta(0.3334444, Lane.absorb[lane2], Constants::Epsilon)
    assert_in_delta(0.0,       Lane.absorb[lane3], Constants::Epsilon)
    assert_in_delta(0.4999167, Lane.absorb[lane4], Constants::Epsilon)

    assert_equal(lane3, lane1.exitTo[lane2].changeTo)
    assert_equal(1100,  lane1.exitTo[lane2].encourage)
    assert_equal(1200,  lane1.exitTo[lane2].force)

    assert_equal("roadway_test", r.name)
  end
end
