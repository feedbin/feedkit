require "test_helper"

class Feedkit::PrivateAddressTest < Minitest::Test

  PRIVATE = {
    "loopback"               => "127.0.0.1",
    "loopback range"         => "127.10.20.30",
    "loopback ipv6"          => "::1",
    "rfc1918 10"             => "10.0.0.1",
    "rfc1918 172.16"         => "172.16.0.1",
    "rfc1918 192.168"        => "192.168.1.1",
    "link local"             => "169.254.169.254", # cloud metadata endpoint
    "link local ipv6"        => "fe80::1",
    "current network"        => "0.0.0.0",
    "shared address space"   => "100.64.0.1",
    "ietf protocol"          => "192.0.0.1",
    "test-net-1"             => "192.0.2.1",
    "6to4 relay"             => "192.88.99.1",
    "benchmark"              => "198.18.0.1",
    "test-net-2"             => "198.51.100.1",
    "test-net-3"             => "203.0.113.1",
    "multicast"              => "224.0.0.1",
    "reserved class e"       => "240.0.0.1",
    "broadcast"              => "255.255.255.255",
    "unspecified ipv6"       => "::",
    "nat64"                  => "64:ff9b::1",
    "nat64 rfc8215"          => "64:ff9b:1::1",
    "discard prefix"         => "100::1",
    "teredo"                 => "2001::1",
    "orchid deprecated"      => "2001:10::1",
    "orchidv2"               => "2001:20::1",
    "documentation ipv6"     => "2001:db8::1",
    "6to4"                   => "2002::1",
    "documentation 3fff"     => "3fff::1",
    "unique local"           => "fc00::1",
    "unique local fd"        => "fd00::1",
    "multicast ipv6"         => "ff00::1"
  }

  PUBLIC = {
    "google dns"             => "8.8.8.8",
    "cloudflare dns"         => "1.1.1.1",
    "public ipv6"            => "2606:4700:4700::1111",
    "just below shared"      => "100.63.255.255",
    "just above shared"      => "100.128.0.0",
    "just below test-net-1"  => "192.0.1.255",
    "just above test-net-3"  => "203.0.114.0"
  }

  PRIVATE.each do |name, address|
    define_method("test_blocks_#{name.tr(" .-", "___")}") do
      assert Feedkit::PrivateAddress.match?(IPAddr.new(address)),
        "#{address} (#{name}) should be treated as private"
    end
  end

  PUBLIC.each do |name, address|
    define_method("test_allows_#{name.tr(" .-", "___")}") do
      refute Feedkit::PrivateAddress.match?(IPAddr.new(address)),
        "#{address} (#{name}) should not be treated as private"
    end
  end

  def test_blocks_ipv4_mapped_ipv6
    # ::ffff:127.0.0.1 must not slip past the IPv4 rules
    assert Feedkit::PrivateAddress.match?(IPAddr.new("::ffff:127.0.0.1"))
    assert Feedkit::PrivateAddress.match?(IPAddr.new("::ffff:169.254.169.254"))
    assert Feedkit::PrivateAddress.match?(IPAddr.new("::ffff:10.0.0.1"))
  end

  def test_allows_ipv4_mapped_public_ipv6
    refute Feedkit::PrivateAddress.match?(IPAddr.new("::ffff:8.8.8.8"))
  end
end
