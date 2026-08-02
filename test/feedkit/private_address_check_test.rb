require "test_helper"

class Feedkit::PrivateAddressCheckTest < Minitest::Test

  PRIVATE_ADDRESSES = %w[
    0.0.0.0
    10.0.0.1
    100.64.0.1
    127.0.0.1
    169.254.169.254
    172.16.0.1
    192.0.0.1
    192.0.2.1
    192.88.99.1
    192.168.1.7
    198.18.0.1
    198.51.100.1
    203.0.113.1
    224.0.0.1
    240.0.0.1
    255.255.255.255
    ::
    ::1
    ::ffff:0.0.0.1
    ::ffff:127.0.0.1
    ::ffff:192.168.1.7
    64:ff9b::101:101
    100::1
    2001::1
    2001:db8::1
    2002:c0a8::1
    3fff::1
    fc00::1
    fe80::1
    ff00::1
  ]

  PUBLIC_ADDRESSES = %w[
    1.1.1.1
    8.8.8.8
    93.184.216.34
    ::ffff:93.184.216.34
    2001:4860:4860::8888
    2606:2800:220:1:248:1893:25c8:1946
  ]

  def test_should_be_private
    PRIVATE_ADDRESSES.each do |address|
      assert Feedkit::PrivateAddressCheck.private_address?(IPAddr.new(address)), "#{address} should be private"
    end
  end

  def test_should_be_public
    PUBLIC_ADDRESSES.each do |address|
      refute Feedkit::PrivateAddressCheck.private_address?(IPAddr.new(address)), "#{address} should not be private"
    end
  end

  def test_should_allow_addresses_from_env
    mock_env("FEEDKIT_ALLOWED_PRIVATE_ADDRESSES" => "127.0.0.1, 10.0.0.0/8") do
      assert Feedkit::PrivateAddressCheck.allowed_address?(IPAddr.new("127.0.0.1")), "127.0.0.1 should be allowed"
      assert Feedkit::PrivateAddressCheck.allowed_address?(IPAddr.new("10.1.2.3")), "10.1.2.3 should be allowed"
      refute Feedkit::PrivateAddressCheck.allowed_address?(IPAddr.new("127.0.0.2")), "127.0.0.2 should not be allowed"
    end
  end

  def test_should_allow_no_addresses_by_default
    refute Feedkit::PrivateAddressCheck.allowed_address?(IPAddr.new("127.0.0.1")), "127.0.0.1 should not be allowed"
  end

  def test_should_check_addresses_before_connecting
    exception = assert_raises Feedkit::PrivateNetworkAddress do
      Feedkit::PrivateAddressCheck::Socket.check_private_address!("127.0.0.1", "localhost")
    end

    assert_includes exception.message, "localhost"
    assert_includes exception.message, "127.0.0.1"
  end

  def test_should_resolve_hostnames_to_addresses
    addresses = Feedkit::PrivateAddressCheck::Socket.addresses("localhost", 5)

    assert_includes addresses, "127.0.0.1"
  end

  def test_should_pass_through_literal_addresses
    assert_equal ["93.184.216.34"], Feedkit::PrivateAddressCheck::Socket.addresses("93.184.216.34", 5)
  end
end
