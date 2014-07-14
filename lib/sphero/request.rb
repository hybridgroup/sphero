class Sphero
  class Request
    SOP1 = 0xFF
    SOP2 = 0xFF

    attr_reader :data, :seq

    def initialize seq, data = []
      @seq    = seq
      @data   = data
      @did    = 0x00
    end

    def header
      [SOP1, SOP2, @did, @cid, @seq, dlen]
    end

    # The data to write to the socket
    def to_str
      bytes
    end

    def response header, body
      name = self.class.name.split('::').last
      if Response.const_defined?(name)
        Response.const_get(name).new header, body
      else
        Response.new header, body
      end
    end

    def packet_header
      header.pack 'CCCCCC'
    end

    def packet_body
      @data.pack 'C*'
    end

    def checksum
      ~((packet_header + packet_body).unpack('C*').drop(2).reduce(:+) % 256) & 0xFF
    end

    def bytes
      packet_header + packet_body + checksum.chr
    end

    def dlen
      packet_body.bytesize + 1
    end

    class Sphero < Request
      def initialize seq, data = []
        super
        @did = 0x02
      end
    end

    def self.make_command klass, cid, &block
      Class.new(klass) {
        define_method(:initialize) do |seq, *args|
          super(seq, args)
          @cid = cid
        end
      }
    end

    SetBackLEDOutput = make_command Sphero, 0x21
    SetRotationRate  = make_command Sphero, 0x03
    SetRGB           = make_command Sphero, 0x20
    GetRGB           = make_command Sphero, 0x22

    Ping             = make_command Request, 0x01
    GetVersioning    = make_command Request, 0x02
    GetBluetoothInfo = make_command Request, 0x11
    SetAutoReconnect = make_command Request, 0x12
    GetAutoReconnect = make_command Request, 0x13
    GetPowerState    = make_command Request, 0x20

    class Roll < Sphero
      def initialize seq, speed, heading, delay
        super(seq, [speed, heading, delay])
        @cid = 0x30
      end

      private
      def packet_body
        @data.pack 'CnC'
      end
    end

    class Heading < Sphero
      def initialize seq, heading
        super(seq, [heading])
        @cid = 0x01
      end

      private
      def packet_body
        @data.pack 'n'
      end
    end

    class Stabilization < Sphero
      def initialize seq, on
        super(seq, [on ? 1 : 0])
        @cid = 0x02
      end

      private
      def packet_body
        @data.pack 'C'
      end
    end

    class Sleep < Request
      def initialize seq, wakeup, macro
        super(seq, [wakeup, macro])
        @cid    = 0x22
      end

      private

      def packet_body
        @data.pack 'nC'
      end
    end

    class SetPowerNotification < Request
      def initialize seq, enable
        super(seq, [enable])
        @cid = 0x21
      end
    end

    class SetTempOptionFlags < Request
      def initialize seq, flag
        super(seq, [flag])
        @cid = 0x37
        @did = 0x02
      end

      private
      def packet_body
        @data.pack 'N'
      end
    end

    GYRO_AXIS_H_FILTERED = 0x0000_0001
    GYRO_AXIS_M_FILTERED = 0x0000_0002
    GYRO_AXIS_L_FILTERED = 0x0000_0004 
    LEFT_MOTOR_BACK_EMF_FILTERED = 0x0000_0020
    RIGHT_MOTOR_BACK_EMF_FILTERED = 0x0000_0040 
    MAGNETOMETER_AXIS_Z_FILTERED = 0x0000_0080
    MAGNETOMETER_AXIS_Y_FILTERED = 0x0000_0100
    MAGNETOMETER_AXIS_X_FILTERED = 0x0000_0200
    GYRO_AXIS_Z_FILTERED = 0x0000_0400
    GYRO_AXIS_Y_FILTERED = 0x0000_0800
    GYRO_AXIS_X_FILTERED = 0x0000_1000
    ACCELEROMETER_AXIS_Z_FILTERED = 0x0000_2000
    ACCELEROMETER_AXIS_Y_FILTERED = 0x0000_4000
    ACCELEROMETER_AXIS_X_FILTERED = 0x0000_8000
    IMU_YAW_ANGLE_FILTERED = 0x0001_0000
    IMU_ROLL_ANGLE_FILTERED = 0x0002_0000
    IMU_PITCH_ANGLE_FILTERED = 0x0004_0000
    LEFT_MOTOR_BACK_EMF_RAW = 0x0020_0000
    RIGHT_MOTOR_BACK_EMF_RAW = 0x0040_0000
    MAGNETOMETER_AXIS_Z_RAW = 0x0080_0000
    MAGNETOMETER_AXIS_Y_RAW = 0x0100_0000
    MAGNETOMETER_AXIS_X_RAW = 0x0200_0000
    GYRO_AXIS_Z_RAW = 0x0400_0000
    GYRO_AXIS_Y_RAW = 0x0800_0000
    GYRO_AXIS_X_RAW = 0x1000_0000
    ACCELEROMETER_AXIS_Z_RAW = 0x2000_0000
    ACCELEROMETER_AXIS_Y_RAW = 0x4000_0000
    ACCELEROMETER_AXIS_X_RAW = 0x8000_0000

    QUATERNION_Q0 = 0x0000_0001
    QUATERNION_Q1 = 0x0000_0002
    QUATERNION_Q2 = 0x0000_0004
    QUATERNION_Q3 = 0x0000_0008
    ODOMETER_X = 0x0000_0010
    ODOMETER_Y = 0x0000_0020
    ACCELONE = 0x0000_0040
    VELOCITY_X = 0x0000_0080
    VELOCITY_Y = 0x0000_0100

    class SetDataStreaming < Sphero
      def initialize seq, n, m, mask, pcnt, mask2
        super(seq, [n, m, mask, pcnt, mask2])
        @cid = 0x12
        @mask = mask
        @mask2 = mask2
      end

      private

      def packet_body
        @data.pack 'nnNCN'
      end
    end

    class ConfigureCollisionDetection < Sphero
      def initialize seq, meth, x_t, y_t, x_spd, y_spd, dead
        super(seq, [meth, x_t, y_t, x_spd, y_spd, dead])
        @cid = 0x12
      end
    end
  end
end
