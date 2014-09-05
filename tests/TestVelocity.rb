#!/usr/bin/ruby

require 'test/unit'
require './math/Velocity'
require './math/Constants'

class TestVelocity < Test::Unit::TestCase

  def testCreate
    v = Velocity::MPH(60)
    assert_in_delta(60.0,      v.mph,  Constants::Epsilon)
    assert_equal(   60,        v.mph_i)
    assert_in_delta(88.0,      v.fps,  Constants::Epsilon)
    assert_equal(   88,        v.fps_i)

    v = Velocity::MPH(65)
    assert_in_delta(65.0,      v.mph,  Constants::Epsilon)
    assert_equal(   65,        v.mph_i)
    assert_in_delta(95+1/3.0,  v.fps,  Constants::Epsilon)
    assert_equal(   95,        v.fps_i)

    v = Velocity::FPS(44)
    assert_in_delta(30.0,      v.mph,  Constants::Epsilon)
    assert_equal(   30,        v.mph_i)
    assert_in_delta(44.0,      v.fps,  Constants::Epsilon)
    assert_equal(   44,        v.fps_i)

    v = Velocity::FPS(56)
    assert_in_delta(38+2/11.0, v.mph,  Constants::Epsilon)
    assert_equal(   38,        v.mph_i)
    assert_in_delta(56.0,      v.fps,  Constants::Epsilon)
    assert_equal(   56,        v.fps_i)

    v = Velocity::String("56_fPs")
    assert_in_delta(38+2/11.0, v.mph,  Constants::Epsilon)
    assert_equal(   38,        v.mph_i)
    assert_in_delta(56.0,      v.fps,  Constants::Epsilon)
    assert_equal(   56,        v.fps_i)

    v = Velocity::MPH("65_MpH")
    assert_in_delta(65.0,      v.mph,  Constants::Epsilon)
    assert_equal(   65,        v.mph_i)
    assert_in_delta(95+1/3.0,  v.fps,  Constants::Epsilon)
    assert_equal(   95,        v.fps_i)
  end

  def testAdd
    v = Velocity::MPH(60) + Velocity::MPH(5)
    assert_in_delta(65.0,      v.mph,  Constants::Epsilon)
    assert_equal(   65,        v.mph_i)
    assert_in_delta(95+1/3.0,  v.fps,  Constants::Epsilon)
    assert_equal(   95,        v.fps_i)

    v = Velocity::FPS(50) + Velocity::FPS(38)
    assert_in_delta(60.0,      v.mph,  Constants::Epsilon)
    assert_equal(   60,        v.mph_i)
    assert_in_delta(88.0,      v.fps,  Constants::Epsilon)
    assert_equal(   88,        v.fps_i)

    v = Velocity::MPH(60) - Velocity::MPH(5)
    assert_in_delta(55.0,      v.mph,  Constants::Epsilon)
    assert_equal(   55,        v.mph_i)
    assert_in_delta(80+2/3.0,  v.fps,  Constants::Epsilon)
    assert_equal(   81,        v.fps_i)

    v = Velocity::FPS(50) - Velocity::FPS(6)
    assert_in_delta(30.0,      v.mph,  Constants::Epsilon)
    assert_equal(   30,        v.mph_i)
    assert_in_delta(44.0,      v.fps,  Constants::Epsilon)
    assert_equal(   44,        v.fps_i)
  end

  def testMult
    v = Velocity::MPH(32.5) * 2
    assert_in_delta(65.0,      v.mph,  Constants::Epsilon)
    assert_equal(   65,        v.mph_i)
    assert_in_delta(95+1/3.0,  v.fps,  Constants::Epsilon)
    assert_equal(   95,        v.fps_i)

    v = Velocity::FPS(176) * 0.5
    assert_in_delta(60.0,      v.mph,  Constants::Epsilon)
    assert_equal(   60,        v.mph_i)
    assert_in_delta(88.0,      v.fps,  Constants::Epsilon)
    assert_equal(   88,        v.fps_i)

    v = Velocity::MPH(11.0) * 5.0
    assert_in_delta(55.0,      v.mph,  Constants::Epsilon)
    assert_equal(   55,        v.mph_i)
    assert_in_delta(80+2/3.0,  v.fps,  Constants::Epsilon)
    assert_equal(   81,        v.fps_i)

    v = Velocity::FPS(33.0) * (4.0/3.0)
    assert_in_delta(30.0,      v.mph,  Constants::Epsilon)
    assert_equal(   30,        v.mph_i)
    assert_in_delta(44.0,      v.fps,  Constants::Epsilon)
    assert_equal(   44,        v.fps_i)
  end
end
