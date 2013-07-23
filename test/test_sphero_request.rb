require 'minitest/autorun'
require 'sphero'

class TestSpheroRequest < MiniTest::Unit::TestCase
  def test_ping_checksum
    ping = Sphero::Request::Ping.new 0
    expected_bytes = "\xFF\xFF\x00\x01\x00\x01\xFD".force_encoding(Encoding::ASCII_8BIT)
    assert_equal expected_bytes, ping.to_str
  end

  def test_sleep_dlen
    sleep = Sphero::Request::Sleep.new 0, 0, 0
    assert_equal 0x04, sleep.dlen
  end
end
