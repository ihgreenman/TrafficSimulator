
require 'matrix'
require './math/Constants'

# This class represents the probability of choosing a descrete
# item of several possiblities, given a probability vector.
# Note that this class does not handle non-descrete cases!

class Probability
  
  ######################################################################
  ########################## Variable Access ###########################
  ######################################################################
  # probabilities is the probability vector.
  # cumulative is the cumulative probability vector.
  # object_lookup maps the resulting object to the numerical choice.
  # objects are the list of objects that will be returned when asking the
  #   class to choose a random outcome.
  attr_reader :probabilities, :cumulative, :object_lookup, :objects

  ######################################################################
  ############################ Constructors ############################
  ######################################################################
  # This is the constructor for the Probability class.
  # It can take up to two arguments; the first is a vector (or array) of
  # normalized probabilities for choosing a specific outcome.  The
  # second (optional) argument is the vector (or array) of objects that
  # will be returned based on the various outcomes.  If the second vector
  # is specified, it must have the same number of items as the
  # probability vector.
  # If you want to create a probability vector based on non-normalized
  # probabilities, see Probability.Normalize
  # If you want to create a finite Gausian distribution, see
  # Probability.Normal
  def initialize(probabilities, *args)
    if (args.size == 0)
      objects = []
    else
      objects = args[0]
    end

    @cumulative = Array.new probabilities.size

    value = 0.0;
    (0..probabilities.size - 1).each do |i|
      raise ArgumentError, "Probability cannot be less than 0" unless probabilities[i] >= 0
      value += probabilities[i]
      @cumulative[i] = value
    end

    unless (value - 1.0).abs < Constants::Epsilon
      raise ArgumentError, "Non-normalized probability vector"
    end

    if objects.size > 0 and probabilities.size != objects.size
      raise ArgumentError, "Object lookup table wrong size"
    end

    if probabilities.kind_of? Vector
      @probabilities = probabilities
    else
      @probabilities = Vector[*probabilities]
    end

    @objects         = objects
    @object_lookup   = {}
    objects.each_index { |i| @object_lookup[objects[i]] = i }

    @first_index       = @cumulative.size / 4
    @second_index      = @cumulative.size / 2
    @third_index       = @cumulative.size * 3 / 4
    @last_index        = @cumulative.size - 1

    @first_cumulative  = @cumulative[@first_index]
    @second_cumulative = @cumulative[@second_index]
    @third_cumulative  = @cumulative[@third_index]
  end

  ######################################################################
  ###################### Class (Static) Functions ######################
  ######################################################################

  ######################################################################
  # This function create a normalized distribution from non-normalized
  # probabilities.
  def Probability.normalize(probabilities, *args)
    unless probabilities.kind_of? Vector
      probabilities = Vector[*probabilities]
    end

    length = 0.0;
    (0..probabilities.size - 1).each { |i| length += probabilities[i] }
    probabilities *= 1.0/length

    return Probability.new(probabilities, *args)
  end

  ######################################################################
  # This returns the normalized cumulative distrubution function for a
  # Gaussian distribution at the given value, for the given mean and
  # deviation.
  def Probability.normal_cdf(value, mean, deviation)
    0.5 * (1.0 + Math.erf((value - mean)/(deviation * Constants::Sqrt2)))
  end

  ######################################################################
  ############################## Functions #############################
  ######################################################################

  ######################################################################
  # This creates a normal (Gaussian) probability distribution. The parameters
  # are as follows:
  # mean      -- the mean of the distribution.
  # deviation -- the devition of the distribution.
  # extract   -- the name of the function to call on start/delta/finish to
  #              get the float value of the data types in question.
  # start     -- the initial value for the distribution
  # delta     -- the delta of the increments between "bins"
  # finish    -- the final value.
  # To create a normal distribution with mean 200, deviation of 30, starting at 85 and going to
  # 205, with an increment of 10 units per segment, we can use:
  # result = Probability.normal(200, 30, :to_f, 85, 10, 205)
  # Because we have the extract function, we can use any data object that has both the +
  # and the comparison operators defined, as well as some (specified) function to extract
  # the "value" of the object.  Velocity is an example of one such class.
  def Probability.normal(mean, deviation, extract, start, delta, finish)
    last_cdf = normal_cdf((start + delta).send(extract), mean, deviation)
    next_cdf = 0.0
    probability = [last_cdf]
    objects       = [start]

    i = start + delta
    while (i < finish)
      next_cdf = normal_cdf((i + delta).send(extract), mean, deviation)
      probability.push(next_cdf - last_cdf)
      objects.push(i)
      last_cdf = next_cdf
      i += delta
    end

    probability.push(1.0 - last_cdf)
    objects.push(finish)

    Probability.new probability, objects
  end

  ######################################################################
  # Looks up the probability of getting an object based on the the index to the
  # object or the object itself.
  def [] (key)
    if @object_lookup.has_key? key
      return @probabilities[@object_lookup[key]]
    end

    return 0.0 if !key.kind_of? Integer

    if (key >= @probabilities.size)
      raise ArgumentError, "Bad probability index: " + key
    end

    @probabilities[key]
  end

  ######################################################################
  # Chooses an index and an object to use from the (optional) second list
  # that was provided as a parameter to the constructor.  Provides both the
  # index chosen and the object as an array.
  def choose
    rv = rand()

    (0..@probabilities.size - 1).each do |i|
      return [i, @objects[i]] if rv <= @cumulative[i]
    end

    # Fail-safe, in case the cumulative function has a value slightly < 1
    [@probabilities.size - 1, @objects[@probabilities.size - 1]]
  end

  ######################################################################
  # Chooses an object to use from the (optional) second list that was
  # provided as a parameter to the constructor.
  # If you have an instance of the Probability class named prob, the following
  # lines of code are equivilent:
  #   result = prob.choose[1]
  #   result = prob.chooseObject
  # It is worth noting that the second form is both easier to read when
  # encountered elsewhere *and* also considerably faster.
  def chooseObject
    rv = rand()

    # starting index lookup.  Used to speed up the rest of the process.
    # Most, if not all, of the rest of the code in this code base only uses
    # probability vectors which have 12 or fewer elements.
    if rv <= @second_cumulative
      if rv <= @first_cumulative
        start  = 0
        finish = @first_index
      else
        start  = @first_index
        finish = @second_index
      end
    else
      if rv <= @third_cumulative
        start  = @second_index
        finish = @third_index
      else
        start  = @third_index
        finish = @last_index
      end
    end

    start.upto(finish) do |i|
      return @objects[i] if rv <= @cumulative[i]
    end

    # Fail-safe, in case the cumulative function has a value slightly < 1
    @objects[@probabilities.size - 1]
  end
end
