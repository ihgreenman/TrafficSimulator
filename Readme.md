Traffic Simulator written in Ruby

I wrote this for a Math class about 7 years ago. It's (original) purpose was to
simulate traffic patterns over the SR520 Lake Washington Bridge.

It's very configurable, and the main configuration file (520_usable.cnf) has a
lot of information about how to configure the simulator.

To run the unit tests:

> ruby AllTests.rb

To run the simulator:

> ruby traffic.rb outputfile.txt config.cnf count

Where
* outputfile.txt is the file to write the output to
* config.cnf is the configuration file (there are a number added to the project)
* count is the (integer) number of times to repeat the simulation

For example:

> ruby traffic.rb results.txt 520_usable.cnf 5

This will run the simulation described in the 520_usable.cnf file, repeating it 5 times,
and placing the results in results.txt.

Enjoy!

-Ian

ian at ihgreenman.com
