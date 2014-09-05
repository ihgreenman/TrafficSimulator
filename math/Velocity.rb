
# This class represents a velocity scalar.
# Internally, it stores the value in feet per second, but
# it has accessors and creation functions that allow for usage of
# feet per second or miles per hour.
class Velocity
  include Comparable

  ######################################################################
  ########################## Variable Access ###########################
  ######################################################################
  # Access to the variable that holds the feet per second value.
  attr_reader :fps

  
  ######################################################################
  ####################### Conversion Functions #########################
  ######################################################################
  # Standard "to string" conversion function.
  # Allows for easy debug printing.
  def to_s
    "Velocity:#{@fps}_fps"
  end

  ######################################################################
  ############################ Constructors ############################
  ######################################################################
  # main constructor function.
  def initialize(fps)
    @fps   = fps
  end

  # Takes a numeric argument in MPH.
  def Velocity::MPH(mph)
    Velocity.new mph.to_f * 22.0/15.0
  end

  # Takes a numeric argument in FPS.
  def Velocity::FPS(fps)
    Velocity.new fps.to_f
  end

  # Takes a string argument which specifies a unit (MPH or FPS).
  # Used in parsing the configuration file.
  def Velocity::String(string)
    data = string.split(/[ _]/)

    if (data.size < 2)
      raise ArgumentError, "Bad format for Velocity: '#{string}' (poss. needs units or size)"
    end

    case data[1]
      when /MPH/i
        return Velocity::MPH(data[0])
      when /FPS/i
        return Velocity::FPS(data[0])
      else
        raise ArgumentError, "Unrecognized unit: #{data[1]} from #{string}"
    end
  end

  ######################################################################
  ############################## Constants #############################
  ######################################################################

  # Defines a constant for zero MPH.  Defined here since it requires the
  # constructors to be previously defined.
  Zero = Velocity.FPS(0)

  ######################################################################
  ############################## Functions #############################
  ######################################################################
  # Returns the internal value converted to MPH.
  def mph
    @fps * 15.0/22.0
  end

  # Returns the internal value converted to MPH, rounded to the nearest
  # integer value.
  def mph_i
    (@fps * 15.0/22.0).round
  end

  # Returns the internal value (in feet per second) rounded to the nearest
  # integer value.
  def fps_i
    @fps.round
  end

  # Defines the operation of adding two velocities.
  def +(other)
    temp = Velocity.new @fps
    temp.plusEquals other
  end

  # Defines the operation of adding two velocities, where the result is stored
  # in the first value.  Used to prevent construction of an additional temporary
  # object.
  def plusEquals other
    @fps += other.fps
    self
  end

  # Defines the operation of subtracting two velocities.
  def -(other)
    Velocity.new @fps - other.fps
  end

  # Defines the operation of multiplying a velocity times a scalar.
  def *(other)
    Velocity.new @fps * other
  end

  # Compares two velocities.
  def <=> (other)
    @fps <=> other.fps
  end
end
