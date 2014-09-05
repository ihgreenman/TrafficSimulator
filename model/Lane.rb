
require 'set'
require './math/Velocity'
require './util/UniqueList'

# This set of classes represent a lane: what it is next to, if it exits
# the simulation or who it feeds to, what the speed limit is,
# and the cars contained in the lane.


# This is an information class that provides information about which lanes
# are next to this lane, and the location that the lanes are attached.
class NextTo
  attr_reader :otherLane, :range, :otherStart

  def initialize(otherLane, start, otherStart, length)
    @otherLane   = otherLane
    @range       = start..(start + length)
    @otherStart  = otherStart
  end

  ######################################################################
  # This function converts a position in one lane to a position in the
  # other.
  def convert(distance)
    if (@range === distance)
      return distance - @range.begin + @otherStart
    end
    nil
  end
end

# This class represents if it is possible to exit the simulator via a given
# lane from this lane.  Further, it tells the simulator what lane the car
# must make a lane change to, and how far it can go before it will be
# compelled to make a lane change (encourage) and how far it can go before
# it will stop in traffic to make the change (force)
class ExitTo
  attr_reader :changeTo, :encourage, :force

  def initialize(change, encourage, force)
    @changeTo = change
    @encourage = encourage
    @force     = force
  end
end

# This class represents a lane of traffic: Where it is, where it goes to,
# what it is next to (and where), and what it contains.
class Lane
  attr_reader :name, :length, :minPassengers, :speedLimit
  attr_reader :generate, :absorb, :nextTo
  attr_reader :exitTo, :meterRate, :along
  attr_reader :initialSpeed

  @@lanes = {}

  def totalSize
    @cars.size
  end

  def waitingSize
    result = 0
    @cars.each { |car| result += 1 if car.bodyStart < 0 }
    result
  end

  def movingSize
    result = 0
    @cars.each { |car| result += 1 if car.bodyStart >= 0 }
    result
  end

  def clear
    @cars.clear
  end

  def to_s
    "<Lane:#{@name}>"
  end

  alias inspect to_s

  # New is private since we need to choose an appropriate subclass based on
  # the construction arguments
  private_class_method :new

  def initialize(args)
    @name           = args.shift
    @length         = args.shift.to_i
    @minPassengers = args.shift.to_i
    @speedLimit    = Velocity.String(args.shift)
    @generate       = args.shift.to_f
    @meterRate     = args.shift.to_i
    @initialSpeed  = Velocity.String(args.shift)
    @meterTime     = 0

    @absorb         = 0.0

    @along          = Array.new @length

    @nextTo        = {}
    @exitTo        = { self => ExitTo.new(self, @length - 100, @length + 50)}
    @cars           = UniqueList.new

    @@lanes[name] = self
  end

  def Lane.generate
    @@generate
  end

  def Lane.absorb
    @@absorb
  end

  def Lane.allLanes
    @@lanes
  end

  def Lane.find(name)
    @@lanes[name]
  end

  def Lane.reset
    @@lanes = {}
  end

  def Lane.create(args)
    type = args[7]

    case (type)
      when /^feeds?$/
        LaneFeeds.create(args)
      when /^absorbs?$/
        LaneAbsorbs.create(args)
      else
        raise ArgumentError, "lane: Unknown type #{type} for #{name}"
    end
  end

  def Lane.finalize
    generate     = {}
    absorb       = {}

    @@lanes.each { |name, lane| lane.finalize(generate, absorb) }

    @@generate = Probability.normalize generate.values, generate.keys
    @@absorb   = Probability.normalize absorb.values,   absorb.keys
  end

  def Lane.addNextTo(args)
    raise(ArgumentError, "next_to: Too few arguments: " + args.join(" ")) unless args.size >= 5

    lane1  = find(args[0]) || raise(ArgumentError, "next_to: No such lane: " + args[0])
    start1 = args[1].to_i
    lane2  = find(args[2]) || raise(ArgumentError, "next_to: No such lane: " + args[2])
    start2 = args[3].to_i
    length = args[4].to_i

    lane1.addNextTo lane2, start1, start2, length
    lane2.addNextTo lane1, start2, start1, length
    1
  end

  def addNextTo(lane, start, startOther, length)
    @nextTo[lane] = NextTo.new lane, start, startOther, length
    (start..(start + length)).each { |i| (along[i] ||= []).push lane }
  end

  def Lane.addExitTo(args)
    raise(ArgumentError, "exit_to: Too few arguments: " + args.join(" ")) unless args.size >= 4

    to        = find(args.shift)
    from      = find(args.shift)
    change    = find(args.shift)
    encourage = args.shift.to_i
    force     = args.shift.to_i

    from.exitTo[to] = ExitTo.new change, encourage, force
  end

  def meterOK
    @meterTime <= World.time
  end

  def updateMeter
    return if @meterRate < 1
    @meterTime = World.time + @meterRate
  end

  def [] (where)
    @along[where]
  end

  def addCar(car)
    car.laneStart(@cars.tail)
    @cars.insertItem car
  end

  def deleteCar(car)
    @cars.delete car
  end

  def insertCar car, check
    if check
      prevCar = @cars.findItemOrPrev car
  
      if prevCar
        return false if prevCar.bodyEnd - car.bodyStart < car.lastSpeed.fps * car.changeLead 
        nextCar = prevCar.nextItem
      else
        nextCar = @cars.head
      end
  
      if nextCar
        return false if car.bodyEnd - nextCar.bodyStart < nextCar.lastSpeed.fps * car.changeTrail
      end
    end

    @cars.insertItemIfCan car
  end

  def eachCar &proc
    @cars.each(&proc)
  end

  def iterateChoose
    @changers = []

    @cars.each do |car|
      car.chooseVelocity
    end
  end

  def iterateChange
    @cars.each do |car|
      if (change = car.wantLaneChange)
        @changers.push [car, change]
      end
    end

    @changers.each do |change|
      car = change[0]
      target = change[1]

      car.laneChange @nextTo[target]
    end
  end

  def iterateMove
    @cars.each do |car|
      if car.inQueue
        break unless car.moveInQueue
      else
        car.move
      end
    end
  end

  def iterateRemove
    return if @cars.size == 0

    car = @cars.head
    while(car && car.bodyStart >= @length)
      return unless remove(car)
      car = @cars.head
    end
  end
end


# This is a derived class of Lane which implements the characteristics needed
# for a lane that feeds into another.
class LaneFeeds < Lane
  attr_reader :feeds, :feedsName, :feedsDistance

  def initialize(args)
    if (args.size < 10)
      raise ArgumentError, "lane: Too few arguments: " + args.join(" ")
    end

    super(args)

    args.shift
    @feedsName     = args.shift
    @feedsDistance = args.shift.to_f
  end

  def LaneFeeds.create(args)
    new args
  end

  def finalize(generate, absorb)
    @feeds = @@lanes[@feedsName]
    generate[self] = @generate if @generate > 0
  end

  def remove(car)
    car.laneFeeder(@feedsDistance, @feeds)
  end
end

class LaneAbsorbs < Lane
  def initialize(args)
    if (args.size < 9)
      raise ArgumentError, "lane: Too few arguments: " + args.join(" ")
    end

    super(args)

    args.shift
    @absorb         = args.shift.to_f
  end

  def LaneAbsorbs.create(args)
    new args
  end

  def finalize(generate, absorb)
    generate[self] = @generate if @generate > 0
    absorb[self]   = @absorb if @absorb > 0
  end

  def remove(car)
    @cars.delete car
    World.instance.finalTally(car, true)
    true
  end
end
