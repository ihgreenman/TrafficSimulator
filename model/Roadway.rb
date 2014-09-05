require './math/Probability'
require './model/Lane'

class Roadway
#  attr_reader :lanes
  attr_reader :rate, :name, :passengers

  def inspect
    to_s
  end

  def to_s
    "Roadway:#{name}"
  end

  def initialize(fileOrName)
    @rate = []
    @name = "???"

    @passengers = Probability.normalize [80, 15, 3, 2], [1, 2, 3, 4]

    if (fileOrName.kind_of?(String))
      file = File.open(fileOrName)
    else
      file = fileOrName
    end

    file.each do |line|
      line.chomp!
      next if line =~ /^\s*(#.*)?$/

#      print "-> ", line, "\n"

      values = line.split

      case values[0]
        when /^lane$/
#          print "Found lane: ", values.join("  "), "\n"
          values.shift
          Lane.create(values)
        when /^next_to$/
#          print "Found next_to: ", values.join("  "), "\n"
          values.shift
          Lane.addNextTo(values)
        when /^feed_rate/
#          print "Found feed_rate: ", values.join(" "), "\n"
          values.shift
          rate.push [values.shift.to_f, values.shift.to_i]
        when /^exit_to/
          values.shift
          Lane.addExitTo(values)
        when /^driver/
          values.shift
          Driver.new values
        when /^name/
          values.shift
          @name = values[0]
        else
          print "Found ??? -- ", line, "\n"
      end
    end

    Lane.finalize

    names    = []
    generate = []
    absorb   = []

    Lane.allLanes.each do |name, lane|
      names.push(name)
      generate.push(lane.generate)
      absorb.push(lane.absorb)
    end

    @absorb   = Probability.normalize(absorb,   names)

    @rate.push [nil, 100000000]
    @current_feed_index = 0
    @current_feed_rate  = @rate[0][0]
    @end_feed_time      = @rate[0][1]
  end

  def getFeedRate
    if World.time > @end_feed_time
      @current_feed_index += 1
      @current_feed_index  = @rate.size - 1 if @current_feed_index >= @rate.size

      @current_feed_rate   = @rate[@current_feed_index][0]
      @end_feed_time      += @rate[@current_feed_index][1]
    end

    @current_feed_rate
  end

  def reset
    @current_feed_index = 0
    @current_feed_rate  = @rate[0][0]
    @end_feed_time      = @rate[0][1]
  end
end
