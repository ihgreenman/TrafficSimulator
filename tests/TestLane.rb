#!/usr/bin/ruby

require 'test/unit'
require './model/Lane'
require './math/Constants'

class FakeCarForLane
  attr_accessor :position
  def initialize(position)
    @position = position
  end
end

class TestLane < Test::Unit::TestCase

  def setup
    Lane.reset
    @lane1 = Lane.create "c1 500.1_feet 1_person 60.5_MPH 100.1 5_s 12_MPH feeds c4 30.1_feet".split
    @lane2 = Lane.create "c2 550.1_feet 2_people 61.5_MPH 150.1 6_s 14_MPH absorbs 30.1".split
    @lane3 = Lane.create "c3 600.1_feet 3_people 62.5_MPH 230.1 7_s 16_MPH feeds c2 50.1_feet".split
    @lane4 = Lane.create "c4 650.1_feet 4_people 63.5_MPH 300.1 8_s 18_MPH absorbs 50.1".split

    Lane.finalize
  end

  def testCreation
    #   lane <name> <length> <passengers> <speed> <generate> feeds <name2> <distance>
    #   lane <name> <length> <passengers> <speed> <generate> absorbs <absorb>

    lanes = [
      ["c1", 500, 1, 60.5, 100.1, 5, 12, @lane4, "c4", 30.1,  0.0],
      ["c2", 550, 2, 61.5, 150.1, 6, 14,    nil,  nil,  0.0, 30.1],
      ["c3", 600, 3, 62.5, 230.1, 7, 16, @lane2, "c2", 50.1,  0.0],
      ["c4", 650, 4, 63.5, 300.1, 8, 18,    nil,  nil,  0.0, 50.1]
    ]

    assert_equal(@lane1, Lane.find("c1"));
    assert_equal(@lane2, Lane.find("c2"));
    assert_equal(@lane3, Lane.find("c3"));
    assert_equal(@lane4, Lane.find("c4"));

    lanes.each do |lane|
      t = Lane.find(lane[0]);
      assert_not_nil(t);

      assert_equal(lane[0], t.name);
      assert_equal(lane[1], t.length);
      assert_equal(lane[2], t.minPassengers);
      assert_equal(lane[3], t.speedLimit.mph);
      assert_equal(lane[4], t.generate);
      assert_equal(lane[5], t.meterRate)
      assert_equal(lane[6], t.initialSpeed.mph);
      if (lane[7])
        assert_equal(lane[7], t.feeds);
        assert_equal(lane[8], t.feedsName);
        assert_equal(lane[9], t.feedsDistance);
      else
        assert_equal(lane[10], t.absorb);
      end
    end
  end

  def check_lanes(expected, result)
    assert_not_nil(result)
    assert_equal(expected.size, result.size)

    expected.each do |exp|
      found = nil
      result.each { |r| found = true if exp == r }

      fail("expected value not found") unless found
    end
  end

  def testNext
    Lane.addNextTo("c1 200.2 c2 100.1 57.3".split)
    Lane.addNextTo("c1 250.2 c3 110.1 58.7".split)

    assert_equal(2, @lane1.nextTo.size)
    assert_equal(1, @lane2.nextTo.size)
    assert_equal(1, @lane3.nextTo.size)
    assert_equal(0, @lane4.nextTo.size)

    assert_equal(200..257, @lane1.nextTo[@lane2].range)
    assert_equal(250..308, @lane1.nextTo[@lane3].range)
    assert_nil(@lane1.nextTo[@lane4])

    assert_nil(@lane1.nextTo[@lane2].convert(199))
    assert_equal(115, @lane1.nextTo[@lane2].convert(215))
    assert_nil(@lane1.nextTo[@lane2].convert(258))

    assert_nil(@lane1.nextTo[@lane3].convert(249))
    assert_equal(125, @lane1.nextTo[@lane3].convert(265))
    assert_nil(@lane1.nextTo[@lane3].convert(309))

    assert_equal(100..157, @lane2.nextTo[@lane1].range)
    assert_nil(@lane2.nextTo[@lane3])
    assert_nil(@lane2.nextTo[@lane4])

    assert_nil(@lane2.nextTo[@lane1].convert(99))
    assert_equal(215, @lane2.nextTo[@lane1].convert(115))
    assert_nil(@lane2.nextTo[@lane1].convert(158))

    assert_equal(110..168, @lane3.nextTo[@lane1].range)
    assert_nil(@lane3.nextTo[@lane2])
    assert_nil(@lane3.nextTo[@lane4])

    assert_nil(@lane3.nextTo[@lane1].convert(249))
    assert_equal(265, @lane3.nextTo[@lane1].convert(125))
    assert_nil(@lane3.nextTo[@lane1].convert(309))

    assert_nil(@lane4.nextTo[@lane1])
    assert_nil(@lane4.nextTo[@lane2])
    assert_nil(@lane4.nextTo[@lane3])

    assert_nil(@lane1[ 50])
    assert_nil(@lane1[199])
    check_lanes([@lane2        ], @lane1[200])
    check_lanes([@lane2        ], @lane1[249])
    check_lanes([@lane2, @lane3], @lane1[250])
    check_lanes([@lane2, @lane3], @lane1[257])
    check_lanes([        @lane3], @lane1[258])
    check_lanes([        @lane3], @lane1[308])
    assert_nil(@lane1[309])

    assert_nil(@lane2[99])
    check_lanes([@lane1], @lane2[100])
    check_lanes([@lane1], @lane2[157])
    assert_nil(@lane2[158])

    assert_nil(@lane3[109])
    check_lanes([@lane1], @lane3[110])
    check_lanes([@lane1], @lane3[168])
    assert_nil(@lane3[169])

    assert_nil(@lane4[110])
  end

  def checkExitTo(from, to, change, encourage, force)
    assert_equal(change,    from.exitTo[to].changeTo)
    assert_equal(encourage, from.exitTo[to].encourage)
    assert_equal(force,     from.exitTo[to].force)
  end

  def testExitTo
    Lane.addExitTo("c2 c1 c2 1100 1200".split)
    Lane.addExitTo("c3 c1 c4  200  300".split)

    checkExitTo(@lane1, @lane1, @lane1,  400,  550)
    checkExitTo(@lane1, @lane2, @lane2, 1100, 1200)
    checkExitTo(@lane1, @lane3, @lane4,  200,  300)
    assert_nil(@lane1.exitTo[@lane4])
  end
end
