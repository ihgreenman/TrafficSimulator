require 'matrix'
require './math/Constants'

# This class represents a Markov transition matrix.
# It ended up not being as useful as the Probability class.
#
# Potential Improvements:
# * Create a cumulative transition probability matrix (ala the
# Probability class.

class Markov
  ######################################################################
  ########################## Variable Access ###########################
  ######################################################################

  # The transition matrix.  Allows you to directly inspect it.
  attr_reader :transition

  # This represents the current state that the instance of the Markov
  # model is currently in.  You can both set and read it.
  attr_accessor :state

  ######################################################################
  ############################ Constructors ############################
  ######################################################################
  # This is the constructor for the Markov class.
  # It takes a square matrix with normalized columns (the columns
  # represent the current state(s) and the rows represent the (possible)
  # target states.
  # This function will throw if the column vectors are not normalized.
  def initialize(transition_matrix)
    unless transition_matrix.square?
      raise ArgumentError, "transition matrix must be square"
    end

    transition_matrix.column_vectors.each do |column|
      value = 0.0;
      (0..column.size - 1).each { |i| value += column[i] }
      unless (value - 1.0).abs < Constants::Epsilon
        raise ArgumentError, "Non-normalized transition matrix"
      end
    end

    @transition = transition_matrix
    @state = 0
  end

  # This function returns the probability of ending up at a specific state from
  # a given source 1 x n maxtrix (n is the number of states)
  def getProbabilities(start)
    return @transition * start
  end

  # Chooses a new state based on the current state and the transition matrix.
  # Updates the @state variable to represent this change.
  def nextState
    column = @transition.column(@state)
    rv = rand

    (0..column.size - 1).each do |v|
      rv -= column[v]
      if rv < 0
        @state = v
        break
      end
    end

    @state
  end
end
