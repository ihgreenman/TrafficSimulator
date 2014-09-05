#!/usr/bin/ruby

unless defined? InTest
  InTest = 1
end

require 'test/unit'
require './model/Car'
require './model/World'
require './math/Velocity'

class FakeNextToForCar
  attr_reader :otherLane

  def initialize(delta, other)
    @delta = delta
    @otherLane = other
    World.reset
  end

  def convert(value)
    value + @delta
  end
end

class FakeLaneForCar
  attr_reader :speed_limit, :exit_to, :initial_speed

  def initialize(speed_fps, initial_fps)
    @speed_limit = Velocity.FPS(speed_fps)
    @initial_speed = Velocity.FPS(initial_fps)
    @exit_to   = {}
  end
end

class TestCar < Test::Unit::TestCase

  def setup
    Driver.reset
    Lane.reset
    World.reset
    World.tick
    World.tick
    World.tick

    @driver1 = Driver.new "normal     60  +5_MPH 0.5 10 5 .00001 .5 5_MPH".split
    @driver2 = Driver.new "slow       10 -10_MPH 3   11 5 .00001 .5 1_MPH".split
    @driver3 = Driver.new "tailgate   30  +5_MPH 0.2 12 2 .0005  .5 7_MPH".split
    @driver4 = Driver.new "bad_car    30  +5_MPH 0.2 12 2 .001   .5 7_MPH .2".split
    @driver5 = Driver.new "bad_driver 30  +5_MPH 0.2 12 2 .2     .5 7_MPH .001".split

    @lane1 = Lane.create "lane1 1500 1 60_MPH  500 0 15_MPH absorb 0".split
    @lane2 = Lane.create "lane2 2500 1 60_MPH    0 1 15_MPH absorb 1000".split
    @lane3 = Lane.create "lane3 2000 2 60_MPH    0 2 15_MPH feeds lane2 2250".split

    Lane.addNextTo("lane1 250 lane2 500 750".split)
    Lane.addNextTo("lane2 250 lane3 0 2000".split)

    Lane.addExitTo("lane1 lane2 lane1 700 1000".split)
    Lane.addExitTo("lane1 lane3 lane2 400 700".split)

    Lane.addExitTo("lane2 lane1 lane2 900 1250".split)
    Lane.addExitTo("lane2 lane3 lane2 1900 2250".split)

    Lane.finalize
  end

  def testSetup
    car = Car.new 15, @driver1, 2

    assert_equal(  @lane1, car.currentLane)
    assert_equal(  @lane2, car.exitLane)
    assert_equal(      -1, car.bodyStart)
    assert_equal(     -16, car.bodyEnd)
    assert_equal(      22, car.lastSpeed.fps_i)
    assert_equal(@driver1, car.driver)
    assert_equal(       2, car.passengers)
    assert_equal(       3, car.createTime)
    assert_equal(       0, car.distance)

    car.setPosition(90)
    assert_equal(      90, car.bodyStart)
  end

  def testWantLaneChange
    srand(0xd1ce)

    car = Car.new 15, @driver1, 2

    assert_equal(nil, car.wantLaneChange)

    car.setPosition(249)
    assert_equal(nil, car.wantLaneChange)

    car.setPosition(250)
    assert_equal(nil,    car.wantLaneChange)
    assert_equal(@lane2, car.wantLaneChange)
    assert_equal(@lane2, car.wantLaneChange)
    assert_equal(nil,    car.wantLaneChange)
    assert_equal(@lane2, car.wantLaneChange)

    car.setPosition(900)
    assert_equal(@lane2, car.wantLaneChange)
    assert_equal(@lane2, car.wantLaneChange)
    assert_equal(@lane2, car.wantLaneChange)

    car = Car.new 15, @driver1, 2
    car.setPosition(500)
    assert_equal(nil,    car.wantLaneChange)
    assert_equal(@lane2, car.wantLaneChange)
    assert_equal(nil,    car.wantLaneChange)
    assert_equal(nil,    car.wantLaneChange)
    assert_equal(@lane2, car.wantLaneChange)
    assert_equal(@lane2, car.wantLaneChange)
    assert_equal(nil,    car.wantLaneChange)

    car.setPosition(900)
    assert_equal(@lane2, car.wantLaneChange)
    assert_equal(@lane2, car.wantLaneChange)
    assert_equal(@lane2, car.wantLaneChange)

    car = Car.new 15, @driver1, 1, @lane1, @lane1
    car.setPosition(500)
    assert_equal(nil,    car.wantLaneChange)
    assert_equal(nil,    car.wantLaneChange)
    assert_equal(@lane2, car.wantLaneChange)

    car.setPosition(2300)
    assert_equal(nil, car.wantLaneChange)
    assert_equal(nil, car.wantLaneChange)
    assert_equal(nil, car.wantLaneChange)

    car = Car.new 15, @driver1, 1, @lane2, @lane1
    car.setPosition(250)
    assert_equal(nil, car.wantLaneChange)
    assert_equal(nil, car.wantLaneChange)
    assert_equal(nil, car.wantLaneChange)

    car.setPosition(500)
    assert_equal(nil,    car.wantLaneChange)
    assert_equal(nil,    car.wantLaneChange)
    assert_equal(nil,    car.wantLaneChange)
    assert_equal(@lane1, car.wantLaneChange)

    car = Car.new 15, @driver1, 2, @lane3, @lane1
    car.setPosition(400)
    assert_equal(@lane2, car.wantLaneChange)
    assert_equal(@lane2, car.wantLaneChange)
    assert_equal(@lane2, car.wantLaneChange)
  end

  def testChooseJump
    srand(0xd1ce)
    
    car = Car.new 15, @driver1, 1, @lane2, @lane1
    assert_equal(29, car.chooseVelocity.fps_i)
    assert_equal(29, car.chooseVelocity.fps_i)

    car.setLastJump(90)
    assert_equal(95, car.chooseVelocity.fps_i)
    assert_equal(95, car.chooseVelocity.fps_i)

    car.setPosition(950)
    assert_equal(50, car.chooseVelocity.fps_i)

    car.setPosition(1000)
    assert_equal(0, car.chooseVelocity.fps_i)

    car2 = Car.new 15, @driver1, 1, @lane2, @lane1
    car.setPosition(0)
    car2.setPosition(50)
    car2.setLastJump(20)
    car2.insertItemAfter car

    assert_equal(36, car.chooseVelocity.fps_i)
    assert_equal(35, car.chooseVelocity.fps_i)
    assert_equal(42, car.chooseVelocity.fps_i)
    assert_equal(37, car.chooseVelocity.fps_i)

    car.setPosition(0)
    car2.setPosition(100)
    car2.setLastJump(20)

    assert_equal(88, car.chooseVelocity.fps_i)

    car.setPosition(950)
    car2.setPosition(960)
    car2.setLastJump(40)

    assert_equal(15, car.chooseVelocity.fps_i)
    assert_equal( 5, car.chooseVelocity.fps_i)
    assert_equal(15, car.chooseVelocity.fps_i)
    assert_equal(11, car.chooseVelocity.fps_i)
  end

  def testMaxSpeedFPS
    car1 = Car.new 15, @driver1, 1, @lane2, @lane1
    car2 = Car.new 15, @driver2, 1, @lane2, @lane1
    car3 = Car.new 15, @driver3, 1, @lane2, @lane1

    car1.setLastJump(0)
    car2.setLastJump(0)
    car3.setLastJump(0)

    assert_equal( 7, car1.maxVelocity.fps_i)
    assert_equal( 1, car2.maxVelocity.fps_i)
    assert_equal(10, car3.maxVelocity.fps_i)

    car1.setLastJump(20)
    car2.setLastJump(20)
    car3.setLastJump(20)

    assert_equal(27, car1.maxVelocity.fps_i)
    assert_equal(21, car2.maxVelocity.fps_i)
    assert_equal(30, car3.maxVelocity.fps_i)

    car1.setLastJump(73)
    car2.setLastJump(73)
    car3.setLastJump(73)

    assert_equal(80, car1.maxVelocity.fps_i)
    assert_equal(73, car2.maxVelocity.fps_i)
    assert_equal(83, car3.maxVelocity.fps_i)

    car1.setLastJump(90)
    car2.setLastJump(90)
    car3.setLastJump(90)

    assert_equal(95, car1.maxVelocity.fps_i)
    assert_equal(73, car2.maxVelocity.fps_i)
    assert_equal(95, car3.maxVelocity.fps_i)
  end

  def testDoJump
    srand(0xd1ce)

    car = Car.new 15, @driver1, 1, @lane2, @lane1
    assert_equal(29, car.chooseVelocity.fps_i)
    car.move
    assert_equal(29, car.lastSpeed.fps_i)
    assert_equal(29, car.bodyStart)
    assert_equal(29, car.distance)

    assert_equal(36, car.chooseVelocity.fps_i)
    car.move
    assert_equal(36, car.lastSpeed.fps_i)
    assert_equal(65, car.bodyStart)
    assert_equal(65, car.distance)

    car2 = Car.new 15, @driver1, 1, @lane2, @lane1
    car.setPosition(0)
    car.setLastJump(50)
    car2.setPosition(40)
    car2.setLastJump(20)
    car2.insertItemAfter car

    assert_equal(27, car2.chooseVelocity.fps_i)
    assert_equal(32, car.chooseVelocity.fps_i)

    car2.move
    assert_equal(27, car2.lastSpeed.fps_i)
    assert_equal(67, car2.bodyStart)
    assert_equal(27, car2.distance)

    car.move
    assert_equal(32, car.lastSpeed.fps_i)
    assert_equal(32, car.bodyStart)
    assert_equal(97, car.distance)

    assert_equal(34, car2.chooseVelocity.fps_i)
    assert_equal(34, car.chooseVelocity.fps_i)

    car2.move
    assert_equal(34, car2.lastSpeed.fps_i)
    assert_equal(101, car2.bodyStart)
    assert_equal(61, car2.distance)

    car.move
    assert_equal(34, car.lastSpeed.fps_i)
    assert_equal(66, car.bodyStart)
    assert_equal(131, car.distance)

    assert_equal(41, car2.chooseVelocity.fps_i)
    assert_equal(33, car.chooseVelocity.fps_i)

    car2.move
    assert_equal(41, car2.lastSpeed.fps_i)
    assert_equal(142, car2.bodyStart)
    assert_equal(102, car2.distance)
    car2.setPosition(90)

    car.move
    assert_equal(8, car.lastSpeed.fps_i)
    assert_equal(74, car.bodyStart)
    assert_equal(139, car.distance)
  end

  def testCanLaneChange
    next_to = FakeNextToForCar.new 50, @lane1
    total = 0

    car2 = Car.new 15, @driver1, @lane1, @lane1
    car2.setPosition 165
    car2.setLastJump(10)

    car = Car.new 15, @driver1, 1, @lane2, @lane1
    car.setLastJump(20)

    (50..98).each do |i|
 #     print "i: #{i}\n"
      total += 1
      @lane1.deleteCar car
      @lane2.insertCar car, false

      car.setPosition(i)
      car.setLane(@lane2)
      assert_equal(true, car.laneChange(next_to))
      assert_equal(next_to.convert(i), car.bodyStart)
      assert_equal(@lane1, car.currentLane)
      assert_equal(total, car.totalLaneChanges)
    end

    (99..131).each do |i|
      car.setPosition(i)
      car.setLane(@lane2)
#      print "i: #{i}\n"
      assert_equal(false, car.laneChange(next_to))
      assert_equal(i, car.bodyStart)
#      print "#{car.currentLane.name}\n"
      assert_equal(@lane2, car.currentLane)
      assert_equal(total, car.totalLaneChanges)
    end

    (132..150).each do |i|
      total += 1
      @lane1.deleteCar car
      @lane2.insertCar car, false

      car.setPosition(i)
      car.setLane(@lane2)
      assert_equal(true, car.laneChange(next_to))
      assert_equal(next_to.convert(i), car.bodyStart)
      assert_equal(@lane1, car.currentLane)
      assert_equal(total, car.totalLaneChanges)
    end
  end

  def testBreakdown
    srand(0xd1ce)
    
    car = Car.new 15, @driver4, 2, @lane1, @lane1

    assert_equal(0, car.bodyStart)
    assert_nil car.fixTime

    assert_equal(32, car.chooseVelocity.fps_i)
    car.move
    assert_equal(32, car.bodyStart)
    assert_nil car.fixTime
    assert_equal(0, car.totalBreakdowns)

    World.tick

    assert_equal(42, car.chooseVelocity.fps_i)
    car.move
    assert_equal(32, car.bodyStart)
    assert_equal 9, car.fixTime
    assert_equal(1, car.totalBreakdowns)

    1.upto 4 do
      World.tick

      car.chooseVelocity
      assert_equal(0, car.nextSpeed.fps_i)
      car.move
      assert_equal(32, car.bodyStart)
      assert_equal 9, car.fixTime
      assert_equal(1, car.totalBreakdowns)
    end

    World.tick

    car.chooseVelocity
    assert_equal(10, car.nextSpeed.fps_i)
    car.move
    assert_equal(42, car.bodyStart)
    assert_nil car.fixTime
    assert_equal(1, car.totalBreakdowns)

    World.tick

    assert_equal(20, car.chooseVelocity.fps_i)
    car.move
    assert_equal(62, car.bodyStart)
    assert_nil car.fixTime
    assert_equal(1, car.totalBreakdowns)

    World.tick

    assert_equal(30, car.chooseVelocity.fps_i)
    car.move
    assert_equal(92, car.bodyStart)
    assert_nil car.fixTime
    assert_equal(1, car.totalBreakdowns)

    World.tick

    assert_equal(40, car.chooseVelocity.fps_i)
    car.move
    assert_equal(132, car.bodyStart)
    assert_nil car.fixTime
    assert_equal(1, car.totalBreakdowns)

    World.tick

    assert_equal(50, car.chooseVelocity.fps_i)
    car.move
    assert_equal(132, car.bodyStart)
    assert_equal 18, car.fixTime
    assert_equal(2, car.totalBreakdowns)

    1.upto 4 do
      World.tick

      car.chooseVelocity
      assert_equal(0, car.nextSpeed.fps_i)
      car.move
      assert_equal(132, car.bodyStart)
      assert_equal 18, car.fixTime
      assert_equal(2, car.totalBreakdowns)
    end

    World.tick

    assert_equal(10, car.chooseVelocity.fps_i)
    car.move
    assert_equal(142, car.bodyStart)
    assert_nil car.fixTime
    assert_equal(2, car.totalBreakdowns)
  end

  def testAccident
    srand(0xd1ce)
    
    car = Car.new 15, @driver5, 2, @lane1, @lane1
    car2 = Car.new 15, @driver5, 2, @lane1, @lane1
    car2.insertItemAfter car
    car2.setPosition(35)
    car2.setLastJump(60)

    assert_equal(0, car.bodyStart)
    assert_nil car.fixTime

    assert_equal(32, car.chooseVelocity.fps_i)
    car2.setPosition(37)
    car.move
    assert_equal(21, car.bodyStart)
    assert_nil car.fixTime
    assert_equal(0, car.totalAccidents)

    World.tick

    assert_equal(31, car.chooseVelocity.fps_i)
    car2.setPosition(39)
    car.move
    assert_equal(23, car.bodyStart)
    assert_nil car.fixTime
    assert_equal(0, car.totalAccidents)

    World.tick

    assert_equal(12, car.chooseVelocity.fps_i)
    car2.setPosition(39)
    car.move
    assert_equal(23, car.bodyStart)
    assert_nil car.fixTime
    assert_equal(0, car.totalAccidents)

    World.tick

    assert_equal(10, car.chooseVelocity.fps_i)
    car2.setPosition(41)
    car.move
    assert_equal(25, car.bodyStart)
    assert_equal 11, car.fixTime
    assert_equal(1, car.totalAccidents)

    World.tick

    43.upto 46 do |i|
      car.chooseVelocity
      assert_equal(0, car.nextSpeed.fps_i)
      car2.setPosition(i)
      car.move
      assert_equal(25, car.bodyStart)
      assert_equal 11, car.fixTime
      assert_equal(1, car.totalAccidents)

      World.tick
    end

    car.chooseVelocity
    assert_equal(10, car.nextSpeed.fps_i)
    car2.setPosition(50)
    car.move
    assert_equal(34, car.bodyStart)
    assert_nil car.fixTime
    assert_equal(1, car.totalAccidents)

    World.tick

    assert_equal(19, car.chooseVelocity.fps_i)
    car2.setPosition(53)
    car.move
    assert_equal(37, car.bodyStart)
    assert_nil car.fixTime
    assert_equal(1, car.totalAccidents)

    World.tick

    assert_equal(13, car.chooseVelocity.fps_i)
    car2.setPosition(53)
    car.move
    assert_equal(37, car.bodyStart)
    assert_nil car.fixTime
    assert_equal(1, car.totalAccidents)
  end
end
