
class Driver
  ######################################################################
  ########################## Variable Access ###########################
  ######################################################################
  attr_reader :name, :frequency, :speedDiff, :follow
  attr_reader :width, :deviation, :accident, :laneChange, :maxAccel
  attr_reader :breakdown, :changeLead, :changeTrail

  ######################################################################
  ########################## Class Variables ###########################
  ######################################################################
  # Variables that are shared by all instances of Driver.

  ######################################################################
  # @@drivers is a list of all possible drivers
  @@drivers = {}

  ######################################################################
  # @@distribution is an instance of Probability that returns a random
  #   driver based on the probablities listed for drivers in the
  #   configuration file.
  @@distribution = nil

  ######################################################################
  ####################### Standard Conversions #########################
  ######################################################################

  ######################################################################
  # This function returns a string describing this class for debug output.
  # Provided to prevent infinite recursion, as the default implementation
  # does not handle class that point to other classes which point to the
  # first class well.
  def inspect
    to_s
  end

  ######################################################################
  # Returns a nice description of the current object.
  def to_s
    "Driver:#{name}"
  end

  ######################################################################
  ############################ Constructors ############################
  ######################################################################

  ######################################################################
  # This is the constructor for the driver class.  The arguments are a
  # split up version of the data provided in the config file.
  def initialize(args)
    if (args.size < 9)
      raise ArgumentError, "Too few arguments for driver"
    end

    @name               = args.shift
    @frequency          = args.shift.to_f
    @speedDiff          = Velocity.String(args.shift)
    @follow             = args.shift.to_f
    @followInv          = 1.0 - @follow
    @width              = args.shift.to_i
    @deviation          = args.shift.to_f
    @accident           = args.shift.to_f
    @laneChange         = args.shift.to_f
    @maxAccel           = Velocity.String(args.shift)
    @breakdown          = args.shift.to_f
    @changeLead         = args.shift.to_f
    @changeTrail        = args.shift.to_f

    @breakdown          = @accident * 0.01 unless @breakdown > 0.0
    @changeLead         = 0.5 unless @changeLead > 0.0
    @changeTrail        = @changeLead unless @changeTrail > 0.0

    start  = Velocity.FPS(-@width)
    finish = Velocity::Zero
    delta  = Velocity.FPS(1)
    @deltaSpeed = Probability.normal(-@width/2, @deviation, "fps", start, delta, finish)

    @@drivers[@name] = self
  end

  ######################################################################
  ###################### Class (Static) Functions ######################
  ######################################################################

  ######################################################################
  # Selects a driver at random among the various possibilties.  The
  # probability of selection of a specific type of driver is based on
  # the probabilities listed in the configuration file.
  def Driver.select
    unless @@distribution
      probabilities = []
      names = []

      @@drivers.each do |name, driver|
        probabilities.push(driver.frequency)
        names.push(driver)
      end

      @@distribution = Probability.normalize probabilities, names
    end

    @@distribution.chooseObject
  end

  ######################################################################
  # Finds a type of driver by the name given to that driver.
  def Driver.find(name)
    @@drivers[name]
  end

  ######################################################################
  ############################## Functions #############################
  ######################################################################

  ######################################################################
  # Returns the calculated velocity of the car.
  def velocity(car)
    return car.maxVelocity unless car.carAhead
    maxVelocity = car.maxVelocity

    result = car.carAhead.lastSpeed * @followInv
    result.plusEquals(Velocity.FPS(car.distanceToCarAhead))

    return maxVelocity if maxVelocity.fps < result.fps - @width - 1

    result.plusEquals(@deltaSpeed.chooseObject)

    return Velocity::Zero if result.fps < 0.0
    return maxVelocity if result > maxVelocity
    result
  end

  ######################################################################
  # Returns the calculated value of the velocity without taking into
  # consideration the velocity of the car ahead. (It considers that
  # velocity to be zero.)
  def velocityNoTime(car)
    return car.maxVelocity unless car.carAhead

    follow = car.carAhead.lastSpeed * @follow
    guess  = Velocity.FPS(car.distanceToCarAhead)
    result = guess - follow + @deltaSpeed.chooseName

    return Velocity::Zero if result.fps < 0
    return car.maxVelocity if result > car.maxVelocity
    result
  end

  ######################################################################
  ####################### Test Fixture Functions #######################
  ######################################################################

  ######################################################################
  # This method is for testing only.  You have been warned.
  def Driver.reset
    @@drivers = {}
    @@distribution = nil
  end
end
