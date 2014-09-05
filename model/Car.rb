require './model/Lane'
require './util/UniqueListItem'

# The car class. An instance of this class represents a single car on
# the road.

class Car
  ######################################################################
  ############################# Includes ###############################
  ######################################################################
  # allows instances of Car to be used in UniqueList.  UniqueList is
  # a sorted linked list with a gaurantee of not having two items that are "equal".
  # "Equal" for a car is if two cars would otherwise occupy the same space on the
  # freeway.
  include UniqueListItem

  ######################################################################
  ##################### Publicly Readable Variables ####################
  ######################################################################
  attr_reader :lastSpeed, :nextSpeed, :driver
  attr_reader :passengers, :currentLane, :createTime, :exitLane, :distance
  attr_reader :totalLaneChanges, :totalAccidents, :bodyStart, :bodyEnd
  attr_reader :fixTime, :totalBreakdowns, :changeLead, :changeTrail


  ######################################################################
  ############################## Aliases ###############################
  ######################################################################
  # These are used to make the code more readable.
  # The "prevItem" and "nextItem" refer to the ordering of the list,
  # which is sorted from the end of the lane to the start.  (That is,
  # the further down the road a car is, the closer it is to the head of
  # the list.)
  alias carAhead  prevItem
  alias carBehind nextItem

  ######################################################################
  ############################# Constants ##############################
  ######################################################################
  # MinimumLength is the minimum length of a car.
  MinimumLength = 10

  # RepairTime is the amount of time that a disabled (by accident or
  # breakdown) car takes to be "repaired" and continue on the way.
  # InTest is defined if we are unit testing.  This allows for easier
  # testing of the car accident/repair cycle.
  if defined? InTest
    RepairTime    = 5
  else
    RepairTime    = 300
  end

  ######################################################################
  ####################### Conversion Functions #########################
  ######################################################################
  # Prints out a nice version of the car object, suitable for debugging.
  def to_s
    "<Car:#{sprintf '0x%x', 0x100000000 + self.object_id*2}:" +
    "#{@driver.name}:#{@currentLane.name}:#{bodyStart}:#{bodyEnd}>"
  end

  # Allows the unit tests to print out the data object it is looking at.
  # This is necessary since the default version handles recursive
  # objects poorly.
  alias inspect to_s

  ######################################################################
  ############################ Constructors ############################
  ######################################################################
  # Constructor for the car object.
  # The arguments are used for testing, if they are not provided, they
  # will be randomly chosen from the available possibilities.

  def initialize(length = 15, driver = nil, passengers = nil, currentLane = nil, exitLane = nil)
    if (length < MinimumLength)
      raise ArgumentError, "Car below minimum length of #{Car.minimumLength}: #{length}"
    end

    @bodyStart    = 0
    @length       = length ? length : 15
    @bodyEnd      = @bodyStart - @length
    @driver       = driver ? driver : Driver.select
    @passengers   = passengers ? passengers : Roadway.passengers.select
    @createTime   = World.time
    @distance     = 0
    @currentLane  = currentLane
    @exitLane     = exitLane
    @fixTime      = nil

    @maxAccel     = @driver.maxAccel
    @changeLead   = @driver.changeLead
    @changeTrail  = @driver.changeTrail

    # if the current lane is undefined, then we choose a lane to put ourselves into.
    # Keep on choosing until we get a valid entry/exit pair.
    unless @currentLane
      begin
        @currentLane = Lane.generate.chooseObject
        @exitLane    = Lane.absorb.chooseObject
      end until @currentLane.exitTo[@exitLane]

      @currentLane.addCar self
    end

    @lastSpeed   = @currentLane.initialSpeed
    @nextSpeed   = Velocity::Zero

    @totalLaneChanges = 0
    @totalAccidents    = 0
    @totalBreakdowns   = 0

    updateLane
  end

  ######################################################################
  ############################## Functions #############################
  ######################################################################
  # Comparison operator.  Defines a sort ordering for the cars, which is
  # based on the distance down the current lane.
  def <=>(other)
    return  -1 if other.bodyStart < bodyEnd
    return   1 if other.bodyEnd   > bodyStart
    0
  end

  ######################################################################
  # Returns the maximum velocity that a car may go.  This is the lesser
  # of either the speed limit plus the offset for the type of driver, or
  # the last velocity that they went plus an acceleration constant.
  def maxVelocity
    return @lastSpeed + @maxAccel if @lastSpeed < @maxCompare
    @maxVelocity
  end

  ######################################################################
  # Determines if this car is waiting in the queue to get into the lane
  # proper, or if it is in the lane already.
  def inQueue
    return @bodyStart < 0
  end

  ######################################################################
  # Determines if the car is blocking the next car in the queue from
  # entering the lane.
  def tailInQueue
    return @bodyEnd < 1
  end

  ######################################################################
  # Returns the distance from the front bumper of this car to the rear
  # bumper of the car ahead.
  def distanceToCarAhead
    return nil unless carAhead
    carAhead.bodyEnd - bodyStart
  end

  ######################################################################
  # Returns the distance from the rear bumper of this car to the front
  # bumper of the car behind.
  def distanceToCarBehind
    return nil unless carBehind
    bodyEnd - carBehind.bodyStart
  end

  ######################################################################
  # Chooses the next velocity for the car to use.
  def chooseVelocity
    # Are we waiting in the queue to enter the lane proper?  If so, we
    # will ignore the normal rules.
    return if inQueue

    # If we aren't fixed, we shouldn't choose a velocity.
    return unless isFixed

    @nextSpeed = @driver.velocity(self)

    if @exitTo.force <= @bodyStart + @nextSpeed.fps_i
      @nextSpeed = Velocity.FPS(@exitTo.force - @bodyStart)
    end

    # Improvement: Add a parameter to a lane that indicates if a car can go
    # past the end safely
    if @currentLane.length < @bodyEnd
      @nextSpeed = Velocity::Zero
    end

    @nextSpeed
  end

  ######################################################################
  # Returns true if the car does not have an active accident at the
  # current time.
  def isFixed
    return true unless @fixTime
    return false if World.time < @fixTime

    @fixTime = nil
    true
  end

  ######################################################################
  # Determines if a breakdown has occurred, and sets appropriate
  # parameters.
  def handlePossibleBreakdown
    return false unless rand < @driver.breakdown

    @lastSpeed = @nextSpeed = Velocity::Zero
    @fixTime = World.time + RepairTime
    @totalBreakdowns += 1

    true
  end

  ######################################################################
  # Determines if an accident has occurred, and sets appropriate
  # parameters.
  def handlePossibleAccident
    return false unless rand < @driver.accident

    @lastSpeed = @nextSpeed = Velocity::Zero
    @fixTime = World.time + RepairTime
    @bodyEnd = @bodyStart - @length
    @totalAccidents += 1

    true
  end

  ######################################################################
  # Implements the normal rules for moving in a lane.  Checks for
  # accidents, breakdowns, and moves the vehicle.
  def move
    return if @fixTime || handlePossibleBreakdown

    old_bodyStart = @bodyStart
    @bodyStart += @nextSpeed.fps_i

    if self.carAhead && (self.carAhead >= self)
      @bodyStart = carAhead.bodyEnd - 1

      actualDistance = @bodyStart - old_bodyStart
      ratio = actualDistance / @nextSpeed.fps

      return if 0.5 > ratio && handlePossibleAccident
    end

    @nextSpeed = Velocity::Zero
    @lastSpeed = Velocity.FPS(@bodyStart - old_bodyStart)
    @distance += @lastSpeed.fps_i

    @bodyEnd = @bodyStart - @length
    @bodyStart
  end

  ######################################################################
  # Moves the car out of the queue if it can do so.  Checks to see if
  # the space at the end of the queue is clear, and if the metering time
  # has expired.
  def moveInQueue
    # Don't bother unless the next car has cleared the end of the queue.
    if carAhead && carAhead.tailInQueue
      return false
    end

    return false unless @currentLane.meterOK

    @bodyStart = 0
    @bodyEnd = @bodyStart - @length
    @nextSpeed = @driver.velocity(self)
    @currentLane.updateMeter

    return true
  end

  ######################################################################
  # Determines if the car wants to make a lane change and returns the
  # lane that it wants to move to.  This *must* be seperate from
  # laneChange (below) since trying to put both operations in the same
  # function would cause the iterator to be invalidated.
  def wantLaneChange

    # If we are past the point at which the car should start moving over
    # to the exit, don't bother with any fancy logic -- just move.
    if @exitTo.encourage <= @bodyStart
      return nil if @currentLane == @exitLane

      @changeLane = @exitTo.changeTo
      return @changeLane
    end

    # Don't bother if we can't change lanes at this position.
    possible = @currentLane[@bodyStart]
    return nil unless possible

    may = []
    fewerCars = 1.0

    # Performs more rigorous tests on the lane, to see if we can
    # change lanes and if we should change lanes.
    possible.each do |lane|
      next unless lane.exitTo[@exitLane]
      next unless lane.minPassengers <= @passengers
      fewerCars = 10.0 if @currentLane.totalSize > lane.totalSize + 20

      may.push lane
    end

    # Again, don't bother if we can't change lanes at this position.
    return nil if may.size == 0

    # Check to see if we actually want to change lanes.
    return nil unless rand < driver.laneChange * fewerCars

    # Choose a lane to move to.
    rv = rand(may.size)
    may[rv]
  end

  ######################################################################
  # Tries to change lanes (if at all possible)
  # This is more complicate than it probably needs to be; the
  # UniqueList needs to have an atomic move operation.
  def laneChange(nextTo)
    new_bodyStart = nextTo.convert(@bodyStart)
    return false unless new_bodyStart && new_bodyStart > 0

    @currentLane.deleteCar self
    old_bodyStart = @bodyStart
    @bodyStart = new_bodyStart
    @bodyEnd = @bodyStart - @length

    unless nextTo.otherLane.insertCar self, true
      @bodyStart = old_bodyStart
      @bodyEnd = @bodyStart - @length

      @currentLane.insertCar self, false
      return false
    end

    @currentLane = nextTo.otherLane

    updateLane
    chooseVelocity
    @totalLaneChanges += 1
    true
  end

  ######################################################################
  # Implements the logic for a car reaching the end of a lane that
  # "feeds" into another.
  # This is more complicate than it probably needs to be; the
  # UniqueList needs to have an atomic move operation.
  def laneFeeder(feedDistance, otherLane)
    @currentLane.deleteCar self
    old_bodyStart = @bodyStart
    @bodyStart += (feedDistance - @currentLane.length).to_i
    @bodyEnd = @bodyStart - @length

    unless otherLane.insertCar self, true
      @bodyStart = old_bodyStart
      @bodyEnd = @bodyStart - @length
      @currentLane.insertCar self, false
      return false
    end

    @currentLane = otherLane
    updateLane
    chooseVelocity
    @totalLaneChanges += 1
    true
  end

  ######################################################################
  # Sets the initial parameters for when a car is first inserted into a
  # lane.
  def laneStart(nextCar)
    @bodyStart   = (nextCar && nextCar.tailInQueue) ? nextCar.bodyEnd - 1 : -1
    @bodyEnd = @bodyStart - @length
    @nextSpeed = Velocity::Zero
    @distance   = @bodyStart > 0 ? @bodyStart : 0
  end

private
  ######################################################################
  # Updates the various lane parameters when we are placed in a new or
  # different lane.
  def updateLane
    @maxVelocity = @currentLane.speedLimit + @driver.speedDiff
    @maxCompare = @maxVelocity - @maxAccel
    @exitTo = @currentLane.exitTo[@exitLane]
  end

public
  ######################################################################
  # only for testing.  You have been warned.
  def setPosition(position)
    @bodyStart = position
    @bodyEnd = @bodyStart - @length
  end

  ######################################################################
  ####################### Test Fixture Functions #######################
  ######################################################################

  ######################################################################
  # only for testing.  You have been warned.
  def setLastJump(lastJump)
    @lastSpeed = Velocity.FPS(lastJump)
  end

  ######################################################################
  # only for testing.  You have been warned.
  def setLane(currentLane)
    @currentLane = currentLane

    @lastSpeed   = @currentLane.initialSpeed
    @nextSpeed   = Velocity::Zero

    updateLane
  end
end
