
# This class is used to collect various statistics about a set of data.
# It provides for count of samples, sum, average, and variance, without
# needing to store the entire set of data.
class Statistics

  ######################################################################
  ########################## Variable Access ###########################
  ######################################################################
  # numSamples is the number of samples collected.
  # sumSamples is the sum of the samples collected.
  attr_reader :numSamples, :sumSamples

  ######################################################################
  ####################### Conversion Functions #########################
  ######################################################################
  # Converts the statistical data to a human and machine readable format.
  def to_s decimalPlaces=8
    averageSumSquared = @sumSamplesSquared/@numSamples
    averageSumSquared = nil if averageSumSquared.nan?

    average        = @numSamples == 0 ? "" : sprintf("%.#{decimalPlaces}f", self.average)
    variance       = @numSamples  < 2 ? "" : sprintf("%.#{decimalPlaces}f", self.variance)
    averageSquared = @numSamples  < 2 ? "" : sprintf("%.#{decimalPlaces}f", @sumSamplesSquared / @numSamples)

    "<stats:#=#{@numSamples}:avg=#{average}:var=#{variance}:avg^2=#{averageSquared}>"
  end

  # Converts the value from to_s back to a statistical data set.
  def from_s (string)
    stats = string.split(/[:=]/)
    @numSamples = stats[2].to_i
    
    if @numSamples == 0
      reset
      return 1
    end

    @sumSamples        = stats[4].to_f * @numSamples
    @sumSamplesSquared = stats[8].to_f * @numSamples

    1
  end

  ######################################################################
  ############################ Constructors ############################
  ######################################################################
  # Constructs an empty statistical set, or revives a set from a
  # previous collection run.
  def initialize *args
    if args.size() > 0
      from_s args[0]
    else
      reset
    end
  end

  # Resets the set to an empty state (clears all data samples)
  def reset
    @numSamples        = 0
    @sumSamples        = 0.0
    @sumSamplesSquared = 0.0
  end

  # Adds a sample or group of samples.  The samples may be in a multi-dimensional
  # array.
  def addSample *args
    args.flatten!
    args.each do |v|
      @numSamples        += 1
      @sumSamples        += v.to_f
      @sumSamplesSquared += v.to_f ** 2
    end
  end

  # Returns the average of the sample set.
  def average
    return nil if @numSamples < 1
    @sumSamples.to_f / @numSamples
  end

  # Returns the variance of the sample set.
  def variance
    return nil if @numSamples < 2
    (@sumSamplesSquared - (@sumSamples ** 2) / @numSamples) / (@numSamples - 1)
  end
end
