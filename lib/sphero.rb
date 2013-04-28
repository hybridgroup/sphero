require 'sphero/request'
require 'sphero/response'
require 'thread'

class Sphero
  VERSION = '1.2.0'

  FORWARD = 0
  RIGHT = 90
  BACKWARD = 180
  LEFT = 270

  DEFAULT_RETRIES = 3

  attr_accessor :connection_types, :async_messages

  class << self
    def start(dev, &block)
      retries_left = DEFAULT_RETRIES
      begin
        sphero = self.new dev
        if (block_given?)
          begin
             sphero.instance_eval(&block)
          ensure
             sphero.close
          end
          return nil
        end
        return sphero      
      rescue Errno::EBUSY
        puts retries_left
        retries_left = retries_left - 1
        retry unless retries_left < 0
      end
    end
  end

  def initialize dev
    if dev.is_a?(String)
      initialize_serialport dev
    else
      @sp = dev
    end

    @dev  = 0x00
    @seq  = 0x00
    @lock = Mutex.new
    @async_messages = []
  end
  
  def close
    @lock.synchronize do
      @sp.close
    end
  end

  def ping
    write Request::Ping.new(@seq)
  end

  def version
    write Request::GetVersioning.new(@seq)
  end

  def bluetooth_info
    write Request::GetBluetoothInfo.new(@seq)
  end

  def auto_reconnect= time_s
    write Request::SetAutoReconnect.new(@seq, time_s)
  end

  def auto_reconnect
    write(Request::GetAutoReconnect.new(@seq)).time
  end

  def disable_auto_reconnect
    write Request::SetAutoReconnect.new(@seq, 0, 0x00)
  end

  def power_state
    write Request::GetPowerState.new(@seq)
  end

  def sphero_sleep wakeup = 0, macro = 0
    write Request::Sleep.new(@seq, wakeup, macro)
  end

  def roll speed, heading, state = true
    write Request::Roll.new(@seq, speed, heading, state ? 0x01 : 0x00)
  end

  def stop
    roll 0, 0
  end

  def heading= h
    write Request::Heading.new(@seq, h)
  end

  def color colorname, persistant = false
    color = COLORS[colorname]
    rgb color[:r], color[:g], color[:b], persistant
  end

  def rgb r, g, b, persistant = false
    write Request::SetRGB.new(@seq, r, g, b, persistant ? 0x01 : 0x00)
  end

  # This retrieves the "user LED color" which is stored in the config block
  # (which may or may not be actively driven to the RGB LED).
  def user_led
    write Request::GetRGB.new(@seq)
  end

  # Brightness 0x00 - 0xFF
  def back_led_output= h
    write Request::SetBackLEDOutput.new(@seq, h)
  end

  # Rotation Rate 0x00 - 0xFF
  def rotation_rate= h
    write Request::SetRotationRate.new(@seq, h)
  end

  # just a nicer alias for Ruby's own sleep
  def keep_going(duration)
    Kernel::sleep duration
  end

  ## async messages

  # configure power notification messages
  def set_power_notification enable=true
    write Request::SetPowerNotification.new(@seq, enable ? 0x01 : 0x00)
  end

  # configure data streaming notification messages
  def set_data_streaming n, m, mask, pcnt, mask2
    write Request::SetDataStreaming.new(@seq, n, m, mask, pcnt, mask2)
  end

  # configure collision detection messages
  def configure_collision_detection meth, x_t, y_t, x_spd, y_spd, dead
    write Request::ConfigureCollisionDetection.new(@seq, meth, x_t, y_t, x_spd, y_spd, dead)
  end

  # read all outstanding async packets and store in async_responses
  # would not do well to receive simple responses this way...
  def read_async_messages
    header, body = nil
    new_responses = []

    @lock.synchronize do
      header, body = read_next_response

      while header && Response.async?(header)
        new_responses << Response::AsyncResponse.response(header, body)
        header, body = read_next_response
      end
    end
    
    async_messages.concat(new_responses) unless new_responses.empty?
    return !new_responses.empty?
  end

  private
  
  def is_windows?
    os = RUBY_PLATFORM.split("-")[1]
    if (os == 'mswin' or os == 'bccwin' or os == 'mingw' or os == 'mingw32')
      true
    else
      false
    end
  end

  def initialize_serialport dev
    require 'serialport'
    @sp = SerialPort.new dev, 115200, 8, 1, SerialPort::NONE
    if is_windows?
      @sp.read_timeout=1000
      @sp.write_timeout=0
      @sp.initial_byte_offset=5
    end
  rescue LoadError
    puts "Please 'gem install hybridgroup-serialport' for serial port support."
  end

  def write packet
    header, body = nil

    @lock.synchronize do
      rs, ws = IO.select([], [@sp], [], 20)
      @sp.write packet.to_str
      @seq += 1

      header = nil
      loop do
        header = read_header(true)
        break if header
      end

      body = read_body(header.last, true) if header

      # pick off asynch packets and store, till we get to the message response
      while header && Response.async?(header)
        async_messages << Response::AsyncResponse.response(header, body)
        header = read_header(true)
        body = read_body(header.last, true) if header
      end
    end

    response = packet.response header, body

    if response.success?
      response
    else
      raise "Unable to write to Sphero!"
    end
  end

  def read_header(blocking=false)
    begin
      data = read_next_chunk(5, blocking)
      return nil unless data && data.length == 5
      header = data.unpack 'C5'
    rescue Errno::EBUSY
      retry
    rescue Exception => e
      puts e.message
      puts e.backtrace.inspect
      retry
    end

    header
  end

  def read_body(len, blocking=false)
    begin
      data = read_next_chunk(len, blocking)
      return nil unless data && data.length == len
    rescue Errno::EBUSY
      retry
    rescue Exception => e
      puts e.message
      puts e.backtrace.inspect
      retry
    end

    data
  end

  def read_next_chunk(len, blocking=false)
    begin
      if blocking || is_windows?
        rs, ws, = IO.select([@sp], [], [], 20)
        data = @sp.read(len)
        return nil unless data && data.length == len
      else
        data = @sp.read_nonblock(len)
      end
    rescue Errno::EBUSY
      retry
    rescue Exception => e
      puts e.message
      puts e.backtrace.inspect
      return nil
    end
    data
  end  

  COLORS = {
    'aliceblue'            => {:r => 240, :g => 248, :b => 255},
    'antiquewhite'         => {:r => 250, :g => 235, :b => 215},
    'aqua'                 => {:r => 0, :g => 255, :b => 255},
    'aquamarine'           => {:r => 127, :g => 255, :b => 212},
    'azure'                => {:r => 240, :g => 255, :b => 255},
    'beige'                => {:r => 245, :g => 245, :b => 220},
    'bisque'               => {:r => 255, :g => 228, :b => 196},
    'black'                => {:r => 0, :g => 0, :b => 0},
    'blanchedalmond'       => {:r =>  255, :g => 235, :b => 205},
    'blue'                 => {:r => 0, :g => 0, :b => 255},
    'blueviolet'           => {:r => 138, :g => 43, :b => 226},
    'brown'                => {:r => 165, :g => 42, :b => 42},
    'burlywood'            => {:r => 222, :g => 184, :b => 135},
    'cadetblue'            => {:r => 95, :g => 158, :b => 160},
    'chartreuse'           => {:r => 127, :g => 255, :b => 0},
    'chocolate'            => {:r => 210, :g => 105, :b => 30},
    'coral'                => {:r => 255, :g => 127, :b => 80},
    'cornflowerblue'       => {:r => 100, :g => 149, :b => 237},
    'cornsilk'             => {:r => 255, :g => 248, :b => 220},
    'crimson'              => {:r => 220, :g => 20, :b => 60},
    'cyan'                 => {:r => 0, :g => 255, :b => 255},
    'darkblue'             => {:r => 0, :g => 0, :b => 139},
    'darkcyan'             => {:r => 0, :g => 139, :b => 139},
    'darkgoldenrod'        => {:r => 184, :g => 134, :b => 11},
    'darkgray'             => {:r => 169, :g => 169, :b => 169},
    'darkgreen'            => {:r => 0, :g => 100, :b => 0},
    'darkkhaki'            => {:r => 189, :g => 183, :b => 107},
    'darkmagenta'          => {:r => 139, :g => 0, :b => 139},
    'darkolivegreen'       => {:r => 85, :g => 107, :b => 47},
    'darkorange'           => {:r => 255, :g => 140, :b => 0},
    'darkorchid'           => {:r => 153, :g => 50, :b => 204},
    'darkred'              => {:r => 139, :g => 0, :b => 0},
    'darksalmon'           => {:r => 233, :g => 150, :b => 122},
    'darkseagreen'         => {:r => 143, :g => 188, :b => 143},
    'darkslateblue'        => {:r => 72, :g => 61, :b => 139},
    'darkslategray'        => {:r => 47, :g => 79, :b => 79},
    'darkturquoise'        => {:r => 0, :g => 206, :b => 209},
    'darkviolet'           => {:r => 148, :g => 0, :b => 211},
    'deeppink'             => {:r => 255, :g => 20, :b => 147},
    'deepskyblue'          => {:r => 0, :g => 191, :b => 255},
    'dimgray'              => {:r => 105, :g => 105, :b => 105},
    'dodgerblue'           => {:r => 30, :g => 144, :b => 255},
    'firebrick'            => {:r => 178, :g => 34, :b => 34},
    'floralwhite'          => {:r => 255, :g => 250, :b => 240},
    'forestgreen'          => {:r => 34, :g => 139, :b => 34},
    'fuchsia'              => {:r => 255, :g => 0, :b => 255},
    'gainsboro'            => {:r => 220, :g => 220, :b => 220},
    'ghostwhite'           => {:r => 248, :g => 248, :b => 255},
    'gold'                 => {:r => 255, :g => 215, :b => 0},
    'goldenrod'            => {:r => 218, :g => 165, :b => 32},
    'gray'                 => {:r => 128, :g => 128, :b => 128},
    'green'                => {:r => 0, :g => 128, :b => 0},
    'greenyellow'          => {:r => 173, :g => 255, :b => 47},
    'honeydew'             => {:r => 240, :g => 255, :b => 240},
    'hotpink'              => {:r => 255, :g => 105, :b => 180},
    'indianred'            => {:r => 205, :g => 92, :b => 92},
    'indigo'               => {:r => 75, :g => 0, :b => 130},
    'ivory'                => {:r => 255, :g => 255, :b => 240},
    'khaki'                => {:r => 240, :g => 230, :b => 140},
    'lavender'             => {:r => 230, :g => 230, :b => 250},
    'lavenderblush'        => {:r => 255, :g => 240, :b => 245},
    'lawngreen'            => {:r => 124, :g => 252, :b => 0},
    'lemonchiffon'         => {:r => 255, :g => 250, :b => 205},
    'lightblue'            => {:r => 173, :g => 216, :b => 230},
    'lightcoral'           => {:r => 240, :g => 128, :b => 128},
    'lightcyan'            => {:r => 224, :g => 255, :b => 255},
    'lightgoldenrodyellow' => {:r => 250, :g => 250, :b => 210},
    'lightgreen'           => {:r => 144, :g => 238, :b => 144},
    'lightgrey'            => {:r => 211, :g => 211, :b => 211},
    'lightpink'            => {:r => 255, :g => 182, :b => 193},
    'lightsalmon'          => {:r => 255, :g => 160, :b => 122},
    'lightseagreen'        => {:r => 32, :g => 178, :b => 170},
    'lightskyblue'         => {:r => 135, :g => 206, :b => 250},
    'lightslategray'       => {:r => 119, :g => 136, :b => 153},
    'lightsteelblue'       => {:r => 176, :g => 196, :b => 222},
    'lightyellow'          => {:r => 255, :g => 255, :b => 224},
    'lime'                 => {:r => 0, :g => 255, :b => 0},
    'limegreen'            => {:r => 50, :g => 205, :b => 50},
    'linen'                => {:r => 250, :g => 240, :b => 230},
    'magenta'              => {:r => 255, :g => 0, :b => 255},
    'maroon'               => {:r => 128, :g => 0, :b => 0},
    'mediumaquamarine'     => {:r => 102, :g => 205, :b => 170},
    'mediumblue'           => {:r => 0, :g => 0, :b => 205},
    'mediumorchid'         => {:r => 186, :g => 85, :b => 211},
    'mediumpurple'         => {:r => 147, :g => 112, :b => 219},
    'mediumseagreen'       => {:r => 60, :g => 179, :b => 113},
    'mediumslateblue'      => {:r => 123, :g => 104, :b => 238},
    'mediumspringgreen'    => {:r => 0, :g => 250, :b => 154},
    'mediumturquoise'      => {:r => 72, :g => 209, :b => 204},
    'mediumvioletred'      => {:r => 199, :g => 21, :b => 133},
    'midnightblue'         => {:r => 25, :g => 25, :b => 112},
    'mintcream'            => {:r => 245, :g => 255, :b => 250},
    'mistyrose'            => {:r => 255, :g => 228, :b => 225},
    'moccasin'             => {:r => 255, :g => 228, :b => 181},
    'navajowhite'          => {:r => 255, :g => 222, :b => 173},
    'navy'                 => {:r => 0, :g => 0, :b => 128},
    'oldlace'              => {:r => 253, :g => 245, :b => 230},
    'olive'                => {:r => 128, :g => 128, :b => 0},
    'olivedrab'            => {:r => 107, :g => 142, :b => 35},
    'orange'               => {:r => 255, :g => 165, :b => 0},
    'orangered'            => {:r => 255, :g => 69, :b => 0},
    'orchid'               => {:r => 218, :g => 112, :b => 214},
    'palegoldenrod'        => {:r => 238, :g => 232, :b => 170},
    'palegreen'            => {:r => 152, :g => 251, :b => 152},
    'paleturquoise'        => {:r => 175, :g => 238, :b => 238},
    'palevioletred'        => {:r => 219, :g => 112, :b => 147},
    'papayawhip'           => {:r => 255, :g => 239, :b => 213},
    'peachpuff'            => {:r => 255, :g => 218, :b => 185},
    'peru'                 => {:r => 205, :g => 133, :b => 63},
    'pink'                 => {:r => 255, :g => 192, :b => 203},
    'plum'                 => {:r => 221, :g => 160, :b => 221},
    'powderblue'           => {:r => 176, :g => 224, :b => 230},
    'purple'               => {:r => 128, :g => 0, :b => 128},
    'red'                  => {:r => 255, :g => 0, :b => 0},
    'rosybrown'            => {:r => 188, :g => 143, :b => 143},
    'royalblue'            => {:r => 65, :g => 105, :b => 225},
    'saddlebrown'          => {:r => 139, :g => 69, :b => 19},
    'salmon'               => {:r => 250, :g => 128, :b => 114},
    'sandybrown'           => {:r => 244, :g => 164, :b => 96},
    'seagreen'             => {:r => 46, :g => 139, :b => 87},
    'seashell'             => {:r => 255, :g => 245, :b => 238},
    'sienna'               => {:r => 160, :g => 82, :b => 45},
    'silver'               => {:r => 192, :g => 192, :b => 192},
    'skyblue'              => {:r => 135, :g => 206, :b => 235},
    'slateblue'            => {:r => 106, :g => 90, :b => 205},
    'slategray'            => {:r => 112, :g => 128, :b => 144},
    'snow'                 => {:r => 255, :g => 250, :b => 250},
    'springgreen'          => {:r => 0, :g => 255, :b => 127},
    'steelblue'            => {:r => 70, :g => 130, :b => 180},
    'tan'                  => {:r => 210, :g => 180, :b => 140},
    'teal'                 => {:r => 0, :g => 128, :b => 128},
    'thistle'              => {:r => 216, :g => 191, :b => 216},
    'tomato'               => {:r => 255, :g => 99, :b => 71},
    'turquoise'            => {:r => 64, :g => 224, :b => 208},
    'violet'               => {:r => 238, :g => 130, :b => 238},
    'wheat'                => {:r => 245, :g => 222, :b => 179},
    'white'                => {:r => 255, :g => 255, :b => 255},
    'whitesmoke'           => {:r => 245, :g => 245, :b => 245},
    'yellow'               => {:r => 255, :g => 255, :b => 0},
    'yellowgreen'          => {:r => 154, :g => 205, :b => 50}
  }
end
