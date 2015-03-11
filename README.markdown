# sphero

* http://github.com/hybridgroup/sphero

[![Build Status](https://travis-ci.org/hybridgroup/sphero.png?branch=master)](https://travis-ci.org/hybridgroup/sphero)

## DESCRIPTION:

A ruby gem for controlling your Sphero ball.  Sends commands over the TTY
provided by the bluetooth connection.

## FEATURES/PROBLEMS:

* You need a Sphero

## SYNOPSIS:

You can easily start your Sphero and send it commands like this:

```ruby
require "Sphero"

Sphero.start '/dev/tty.Sphero-YBW-RN-SPP' do
	roll 60, Sphero::FORWARD
	keep_going 3

	roll 60, RIGHT
	keep_going 3

	roll 60, BACKWARD
	keep_going 3

	roll 60, LEFT
	keep_going 3

	stop
end
```

Here is another example:

```ruby
Sphero.start "/dev/tty.Sphero-PRG-RN-SPP" do
	ping

	# Roll 0 degrees, speed 125
	roll(125, 0)

	# Turn 360 degrees, 30 degrees at a time
	0.step(360, 30) { |h|
  	h = 0 if h == 360

		# Set the heading to h degrees
 		heading = h
 		keep_going 1
	}

	keep_going 1
	stop
end
```

Here is a another way to do the same thing as the previos example, via just normal method calls instead of the DSL:

```ruby
s = Sphero.new "/dev/tty.Sphero-PRG-RN-SPP"
s.ping

# Roll 0 degrees, speed 125
s.roll(125, 0)

# Turn 360 degrees, 30 degrees at a time
0.step(360, 30) { |h|
  h = 0 if h == 360

  # Set the heading to h degrees
  s.heading = h
  sleep 1
}
sleep 1
s.stop
```

## Pairing sphero with ubuntu
Add your user to the `dialout` group
```
$ sudo usermod -a -G dialout <user>
```
Then logout or restart your computer. Once your user is logged back in, pair the sphero with the ubuntu bluetooth manager.

Once paired, you may now bind your sphero to a rfcomm port
```
$ sudo hcitool scan 
Scanning ...
<address>		Sphero
$ sudo rfcomm bind /dev/rfcomm0 <address> 1
```

You may now access the sphero from `/dev/rfcomm0`

## REQUIREMENTS:

* A Sphero ball connected to your computer
* Supports MRI 1.9.2/1.9.3 and Rubinius 2.0rc1 for sure...

## INSTALL:

* gem install sphero

## LICENSE:

(The MIT License)

Copyright (c) 2012 Aaron Patterson
Copyright (c) 2012-2013 The Hybrid Group

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
