#!/usr/bin/ruby -w

require './model/World'

print "Starting...\n"

w = World.instance
w.parseCommandLine ARGV

1.upto w.repeats do |i|
  print "Run #{i}\n"

  World.reset
  w.clear
  w.run
  w.writeFinalStats
end

print "Done\n"
