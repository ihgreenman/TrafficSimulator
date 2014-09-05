require 'singleton'

require './model/Roadway'
require './model/Driver'
require './model/Car'
require './math/Statistics'

class World
  @@time = 0

  ######################################################################
  # In object-oriented parlance, a singleton is a class which can only
  # have a single instance at runtime. This allows for safe "global"
  # variables and functions.
  include Singleton

  ######################################################################
  ########################## Variable Access ###########################
  ######################################################################
  attr_reader :statsDistance, :statsTime, :statsLaneChanges, :statsAccidents
  attr_reader :totalCarsEntered, :totalCarsFinished
  attr_reader :totalRuns, :repeats

  def initialize()
    @roadway        = nil
    @configFilename = nil
    @resultFile     = nil
    @resultFilename = nil
    @runName        = nil

    @statsDistance      = Statistics.new
    @statsTime          = Statistics.new
    @statsLaneChanges   = Statistics.new
    @statsAccidents     = Statistics.new
    @statsBreakdowns    = Statistics.new
    @statsEfficiency    = Statistics.new

    @totalCarsEntered  = 0
    @totalCarsFinished = 0
    @totalInputsByName   = {}
    @totalExitsByName    = {}

    @totalRuns          = 0
    @repeats             = 0
  end

  def parseCommandLine(args)
    if (args.size < 2)
      print "Usage:\n  traffic resultfile configfile [repeat]\n"
      exit(-1)
    end

    @resultFilename = args[0]
    @configFilename = args[1]

    @repeats = 1
    @repeats = args[2].to_i if args.size >= 2

    @roadway = Roadway.new @configFilename
    @resultFile = File.open(@resultFilename, "a")

    @runName = @roadway.name

    Lane.allLanes.each do |name, lane|
      @totalInputsByName[lane.name] = 0
      @totalExitsByName[lane.name]  = 0
    end
  end

  def World.reset
    @@time = 0
  end

  def fullClear
    clear
    @totalRuns = 0
  end

  def clear
    Lane.allLanes.each do |name, lane|
      lane.clear
    end

    @roadway.reset

    @statsDistance.reset
    @statsTime.reset
    @statsLaneChanges.reset
    @statsAccidents.reset
    @statsBreakdowns.reset
    @statsEfficiency.reset

    @totalCarsEntered   = 0
    @totalCarsFinished  = 0
    @totalInputsByName = {}
    @totalExitsByName  = {}

    Lane.allLanes.each do |name, lane|
      @totalInputsByName[lane.name] = 0
      @totalExitsByName[lane.name]  = 0
    end
  end

  def World.time
    @@time
  end

  def World.tick
    @@time += 1
  end

  def run
    @totalRuns += 1

    while iterate
      if 0 == (@@time % 60)
        print "#{@@time} #{@totalCarsEntered} #{@totalCarsFinished}",
              " #{@totalCarsEntered - @totalCarsFinished}\n"

        moving       = 0
        waiting      = 0
        totalMoving  = 0
        totalWaiting = 0

        Lane.allLanes.each do |name, lane|
          moving  = lane.movingSize
          waiting = lane.waitingSize
          totalMoving  += moving
          totalWaiting += waiting

          printf("--> %15s  i:%-3i  c:%-3i s:%-4i f:%-4i\n",
                 lane.name, waiting, moving,
                 @totalInputsByName[lane.name],
                 @totalExitsByName[lane.name])
        end

        printf "-->                  i:%-3i  c:%-3i\n", totalWaiting, totalMoving
      end
    end

    # Tally unfinished cars
    Lane.allLanes.each { |name, lane| lane.eachCar {|car| finalTally(car, false) }}

    print "\n"
  end

  def iterate
    World.tick

    lanes = Lane.allLanes

    rate = @roadway.getFeedRate
    return nil unless rate

    # add in feeding of cars...
    rate = rate.to_i + ((rand < (rate - rate.to_i)) ? 1 : 0)

    (1..rate).each do
      passengers = @roadway.passengers.choose[1]
      driver = Driver.select

      car = Car.new(15, driver, passengers)
      creationTally car
    end

    lanes.each { |name, lane| lane.iterateChoose }
    lanes.each { |name, lane| lane.iterateChange }
    lanes.each { |name, lane| lane.iterateMove }
    lanes.each { |name, lane| lane.iterateRemove }
#    lanes.each { |name, lane| lane.status }

    1
  end

  def creationTally(car)
    @totalCarsEntered += 1

    @totalInputsByName[car.currentLane.name] += 1
    @totalExitsByName[car.exitLane.name] += 1
  end

  def finalTally(car, finished)
    @totalCarsFinished += 1 if finished

    timeDelta = @@time - car.createTime

    @statsDistance.addSample     car.distance
    @statsTime.addSample         timeDelta
    @statsLaneChanges.addSample  car.totalLaneChanges
    @statsAccidents.addSample    car.totalAccidents
    @statsBreakdowns.addSample   car.totalBreakdowns
    @statsEfficiency.addSample   car.distance/timeDelta

#    print "C: #{car.totalLaneChanges} #{car.driver.name}\n"
  end

  def writeFinalStats
    @resultFile << @runName << " [" << @configFilename << "]"

    @resultFile << " D=" << @statsDistance
    @resultFile << " T=" << @statsTime
    @resultFile << " F=" << @totalCarsFinished
    @resultFile << " E=" << @totalCarsEntered
    @resultFile << " C=" << @statsLaneChanges
    @resultFile << " A=" << @statsAccidents
    @resultFile << " B=" << @statsBreakdowns
    @resultFile << " EFF=" << @statsEfficiency << "\n"

    @resultFile << "Start At:"
    @totalInputsByName.each do |name, value|
      @resultFile << " " << name << "=" << value
    end

    @resultFile << "\nExit At:"
    @totalExitsByName.each do |name, value|
      @resultFile << " " << name << "=" << value
    end
    @resultFile << "\n"

    @resultFile.flush
  end
end
