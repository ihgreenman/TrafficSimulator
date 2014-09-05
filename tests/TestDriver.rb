#!/usr/bin/ruby

require 'test/unit'
require './model/Driver'

class FakeCarForDriver
  attr_accessor :bodyStart, :bodyEnd, :lastSpeed, :maxVelocity, :carAhead
  def initialize(position, length, last_jump, maxVelocity_fps)
    @length = length
    @bodyStart = position
    @bodyEnd   = position - @length

    @lastSpeed = Velocity.FPS(last_jump)
    @maxVelocity = Velocity.FPS(maxVelocity_fps)

    @carAhead = nil
  end

  def position=(position)
    @bodyStart = position
    @bodyEnd   = position - @length
  end

  def last_jump=(speed)
    @lastSpeed = Velocity.FPS(speed)
  end

  def distanceToCarAhead
    return nil unless @carAhead
    @carAhead.bodyEnd - bodyStart
  end
end

class FakeLaneForDriver
  # @TODO: fixme
  attr_accessor :length, :speed_fps
  def initialize(length, speed_fps)
    @length = length
    @speed_fps = speed_fps
  end
end

class TestDriver < Test::Unit::TestCase

  def setup
    Driver.reset

    @driver1 = Driver.new "normal     60  +5_MPH 0.5 10_feet 5_feet .00001 .001  5_MPH".split
    @driver2 = Driver.new "slow       10 -10_MPH 3   11_feet 5_feet .00001 .0001 1_MPH".split
    @driver3 = Driver.new "tailgate   30  +5_MPH 0.2 12_feet 2_feet .0005  .01   3_MPH".split
  end

  def testCreation

    drivers = [
      ["normal",     60,   5.0, 0.5, 10, 5.0, 0.00001, 0.001,  5],
      ["slow",       10, -10.0, 3.0, 11, 5.0, 0.00001, 0.0001, 1],
      ["tailgate",   30,   5.0, 0.2, 12, 2.0, 0.0005,  0.01,   3]
    ]

    assert_equal(@driver1, Driver.find("normal"));
    assert_equal(@driver2, Driver.find("slow"));
    assert_equal(@driver3, Driver.find("tailgate"));

    drivers.each do |driver|
      t = Driver.find(driver[0]);
#      print ":#{driver[0]} #{t}\n"
      assert_not_nil(t);

      assert_equal(driver[0], t.name);
      assert_equal(driver[1], t.frequency);
      assert_equal(driver[2], t.speedDiff.mph);
      assert_equal(driver[3], t.follow);
      assert_equal(driver[4], t.width);
      assert_equal(driver[5], t.deviation);
      assert_equal(driver[6], t.accident);
      assert_equal(driver[7], t.laneChange);
      assert_equal(driver[8], t.maxAccel.mph_i);
    end
  end

  def testSelection
    srand(0xd1ce)

    assert_equal(@driver1, Driver.select)
    assert_equal(@driver1, Driver.select)
    assert_equal(@driver3, Driver.select)
    assert_equal(@driver1, Driver.select)
    assert_equal(@driver1, Driver.select)
    assert_equal(@driver3, Driver.select)
    assert_equal(@driver1, Driver.select)
    assert_equal(@driver3, Driver.select)
    assert_equal(@driver2, Driver.select)
    assert_equal(@driver1, Driver.select)
    assert_equal(@driver1, Driver.select)
    assert_equal(@driver3, Driver.select)
    assert_equal(@driver3, Driver.select)
    assert_equal(@driver1, Driver.select)
  end

  def testJump
    srand(0xd1ce)

    car = FakeCarForDriver.new 450, 20, 75, 67
    next_car = FakeCarForDriver.new 500, 15, 50, 67

    assert_equal(67, @driver1.velocity(car).fps_i)

    car.carAhead = next_car
    assert_equal(51, @driver1.velocity(car).fps_i)
    assert_equal(50, @driver1.velocity(car).fps_i)
    assert_equal(57, @driver1.velocity(car).fps_i)
    assert_equal(52, @driver1.velocity(car).fps_i)

    next_car.position = 545
    next_car.last_jump = 5
    car.position = 520
    car.last_jump = 3

    assert_equal( 6, @driver1.velocity(car).fps_i)
    assert_equal(13, @driver1.velocity(car).fps_i)
    assert_equal( 3, @driver1.velocity(car).fps_i)
    assert_equal(13, @driver1.velocity(car).fps_i)

    srand(0xd1ce)

    car = FakeCarForDriver.new 450, 20, 75, 67
    next_car = FakeCarForDriver.new 500, 15, 30, 67

#    print @driver1, "\n"

    assert_equal(67, @driver1.velocity(car).fps_i)

    car.carAhead = next_car
    assert_equal(41, @driver1.velocity(car).fps_i)
    assert_equal(40, @driver1.velocity(car).fps_i)
    assert_equal(47, @driver1.velocity(car).fps_i)
    assert_equal(42, @driver1.velocity(car).fps_i)

    next_car.position = 545
    next_car.last_jump = 5
    car.position = 520
    car.last_jump = 3

    assert_equal( 6, @driver1.velocity(car).fps_i)
    assert_equal(13, @driver1.velocity(car).fps_i)
    assert_equal( 3, @driver1.velocity(car).fps_i)
    assert_equal(13, @driver1.velocity(car).fps_i)
  end
end
