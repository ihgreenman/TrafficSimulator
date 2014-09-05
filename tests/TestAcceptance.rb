#!/usr/bin/ruby

require 'test/unit'
require './model/World'
require './model/Lane'
require './model/Driver'
require './model/Car'

class TestAcceptance < Test::Unit::TestCase

  AverageDistance       = 1550.0
  AverageDistanceDelta  = 49.0
  AverageTime           = 23.0
  AverageTimeDelta      =  5.0
  AverageAccidents      =  1.0
  AverageAccidentsDelta =  1.0

  def setup
    Lane.reset
    Driver.reset
    World.reset

    @w = World.instance

    srand(0xd1ce)
  end

  def testOneLaner1
    @w.parseCommandLine ["testing.txt", "./acceptance_one_lane.cnf"]
    @w.fullClear
    driver = Driver.find("normal")
    lane = Lane.find("lane1")
    assert_equal(0, @w.totalRuns)

    Car.new(15, driver, 2)

    assert_equal(0, lane.movingSize)
    assert_equal(1, lane.waitingSize)
    @w.iterate

    assert_equal(1, lane.movingSize)
    assert_equal(0, lane.waitingSize)
    @w.run

    assert_equal(0, lane.movingSize)
    assert_equal(0, lane.waitingSize)

    assert_equal(1,         @w.totalRuns)
    assert_equal(1,         @w.totalCarsFinished)
    assert_in_delta(0.0,    @w.statsLaneChanges.average, Constants::Epsilon)

    assert_in_delta(AverageDistance,  @w.statsDistance.average,  AverageDistanceDelta)
    assert_in_delta(AverageTime,      @w.statsTime.average,      AverageTimeDelta)
    assert_in_delta(AverageAccidents, @w.statsAccidents.average, AverageAccidentsDelta)

    @w.writeFinalStats
  end

  def testOneLaner2
    @w.parseCommandLine ["output.txt", "./acceptance_one_lane.cnf"]
    @w.fullClear

    driver = Driver.find("normal")
    lane = Lane.find("lane1")

    Car.new(15, driver, 2)
    Car.new(15, driver, 2)
    Car.new(15, driver, 2)
    Car.new(15, driver, 2)
    Car.new(15, driver, 2)
    Car.new(15, driver, 2)
    Car.new(15, driver, 2)
    Car.new(15, driver, 2)

    assert_equal(0, lane.movingSize)
    assert_equal(8, lane.waitingSize)
    @w.iterate

    assert_equal(1, lane.movingSize)
    assert_equal(7, lane.waitingSize)
    @w.iterate

    assert_equal(2, lane.movingSize)
    assert_equal(6, lane.waitingSize)
    @w.iterate

    assert_equal(3, lane.movingSize)
    assert_equal(5, lane.waitingSize)
    @w.run

    assert_equal(0, lane.movingSize)
    assert_equal(0, lane.waitingSize)

    assert_equal(1,         @w.totalRuns)
    assert_equal(8,         @w.totalCarsFinished)
    assert_in_delta(0.0,    @w.statsLaneChanges.average, Constants::Epsilon)

    assert_in_delta(AverageDistance,  @w.statsDistance.average,  AverageDistanceDelta)
    assert_in_delta(AverageTime,      @w.statsTime.average,      AverageTimeDelta)
    assert_in_delta(AverageAccidents, @w.statsAccidents.average, AverageAccidentsDelta)
  end

  def testFeeder1
    @w.parseCommandLine ["output.txt", "./acceptance_feeder.cnf"]
    @w.fullClear
    driver = Driver.find("normal")
    lane1 = Lane.find("lane1")
    lane2 = Lane.find("lane2")
    assert_equal(0, @w.totalRuns)

    car = Car.new(15, driver, 2, lane2, lane1)
    lane2.addCar car

    assert_equal(0, lane2.movingSize)
    assert_equal(1, lane2.waitingSize)
    @w.iterate

    assert_equal(1, lane2.movingSize)
    assert_equal(0, lane2.waitingSize)
    @w.run

    assert_equal(0, lane2.movingSize)
    assert_equal(0, lane2.waitingSize)

    assert_equal(1,         @w.totalRuns)
    assert_equal(1,         @w.totalCarsFinished)
    assert_in_delta(1.0,    @w.statsLaneChanges.average, Constants::Epsilon)

    assert_in_delta(AverageDistance,  @w.statsDistance.average,  AverageDistanceDelta)
    assert_in_delta(AverageTime,      @w.statsTime.average,      AverageTimeDelta)
    assert_in_delta(AverageAccidents, @w.statsAccidents.average, AverageAccidentsDelta)
  end

  def testFeeder2
    @w.parseCommandLine ["output.txt", "./acceptance_feeder.cnf"]
    @w.fullClear
    lane1 = Lane.find("lane1")
    lane2 = Lane.find("lane2")
    driver = Driver.find("normal")

    (1..6).each do
      car = Car.new 15, driver, 2, lane2, lane1
      lane2.addCar car
    end

    assert_equal(0, lane2.movingSize)
    assert_equal(6, lane2.waitingSize)
    @w.iterate

    assert_equal(1, lane2.movingSize)
    assert_equal(5, lane2.waitingSize)
    @w.iterate

    assert_equal(1, lane2.movingSize)
    assert_equal(5, lane2.waitingSize)
    @w.iterate

    assert_equal(2, lane2.movingSize)
    assert_equal(4, lane2.waitingSize)
    @w.iterate

    assert_equal(2, lane2.movingSize)
    assert_equal(4, lane2.waitingSize)
    @w.run

    assert_equal(0, lane1.movingSize)
    assert_equal(0, lane2.movingSize)
    assert_equal(0, lane2.waitingSize)

    assert_equal(1,         @w.totalRuns)
    assert_equal(6,         @w.totalCarsFinished)
    assert_in_delta(1.0,    @w.statsLaneChanges.average, Constants::Epsilon)

    assert_in_delta(AverageDistance,  @w.statsDistance.average,  AverageDistanceDelta)
    assert_in_delta(AverageTime,      @w.statsTime.average,      AverageTimeDelta)
    assert_in_delta(AverageAccidents, @w.statsAccidents.average, AverageAccidentsDelta)
  end

  def testFeeder3
    @w.parseCommandLine ["output.txt", "./acceptance_feeder.cnf"]
    @w.fullClear
    lane1 = Lane.find("lane1")
    lane3 = Lane.find("lane3")
    driver = Driver.find("normal")

    (1..6).each do
      car = Car.new 15, driver, 2, lane3, lane1
      lane3.addCar car
    end

    assert_equal(0, lane3.movingSize)
    assert_equal(6, lane3.waitingSize)
    @w.iterate

    (1..5).each do |i|
      assert_equal(1, lane3.movingSize)
      assert_equal(5, lane3.waitingSize)
      @w.iterate
    end

    (1..5).each do |i|
      assert_equal(2, lane3.movingSize)
      assert_equal(4, lane3.waitingSize)
      @w.iterate
    end

    assert_equal(3, lane3.movingSize)
    assert_equal(3, lane3.waitingSize)
    @w.run

    assert_equal(0, lane1.movingSize)
    assert_equal(0, lane3.movingSize)
    assert_equal(0, lane3.waitingSize)

    assert_equal(1,         @w.totalRuns)
    assert_equal(6,         @w.totalCarsFinished)
    assert_in_delta(1.0,    @w.statsLaneChanges.average, Constants::Epsilon)

    assert_in_delta(AverageDistance,    @w.statsDistance.average,  AverageDistanceDelta)
    assert_in_delta(AverageTime + 10.0, @w.statsTime.average,      AverageTimeDelta)
    assert_in_delta(AverageAccidents,   @w.statsAccidents.average, AverageAccidentsDelta)
  end
end
