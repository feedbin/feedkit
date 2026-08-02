# frozen_string_literal: true

require "ipaddr"
require "resolv"
require "socket"
require "http"
require_relative "errors"

module Feedkit
  # Identifies addresses that are not routable on the public internet.
  #
  # Ported from Mastodon's PrivateAddressCheck.
  module PrivateAddressCheck
    CIDR_LIST = [
      # IPv4 addresses
      IPAddr.new("0.0.0.0/8"),       # Current network (only valid as source address)
      IPAddr.new("100.64.0.0/10"),   # Shared Address Space
      IPAddr.new("172.16.0.0/12"),   # Private network
      IPAddr.new("192.0.0.0/24"),    # IETF Protocol Assignments
      IPAddr.new("192.0.2.0/24"),    # TEST-NET-1, documentation and examples
      IPAddr.new("192.88.99.0/24"),  # IPv6 to IPv4 relay (includes 2002::/16)
      IPAddr.new("198.18.0.0/15"),   # Network benchmark tests
      IPAddr.new("198.51.100.0/24"), # TEST-NET-2, documentation and examples
      IPAddr.new("203.0.113.0/24"),  # TEST-NET-3, documentation and examples
      IPAddr.new("224.0.0.0/4"),     # IP multicast (former Class D network)
      IPAddr.new("240.0.0.0/4"),     # Reserved (former Class E network)
      IPAddr.new("255.255.255.255"), # Broadcast

      # IPv6 addresses
      IPAddr.new("::/128"),          # Unspecified
      IPAddr.new("64:ff9b::/96"),    # IPv4/IPv6 translation (RFC 6052)
      IPAddr.new("64:ff9b:1::/48"),  # IPv4/IPv6 translation (RFC 8215)
      IPAddr.new("100::/64"),        # Discard prefix (RFC 6666)
      IPAddr.new("2001::/32"),       # Teredo tunneling
      IPAddr.new("2001:10::/28"),    # Deprecated (previously ORCHID)
      IPAddr.new("2001:20::/28"),    # ORCHIDv2
      IPAddr.new("2001:db8::/32"),   # Addresses used in documentation and example source code
      IPAddr.new("2002::/16"),       # 6to4
      IPAddr.new("fc00::/7"),        # Unique local address
      IPAddr.new("3fff::/20"),       # Addresses used in documentation and example source code
      IPAddr.new("ff00::/8")         # Multicast
    ].freeze

    module_function

    def private_address?(address)
      address = address.native if address.ipv6? && (address.ipv4_mapped? || address.ipv4_compat?)
      address.private? || address.loopback? || address.link_local? || CIDR_LIST.any? { |cidr| cidr.include?(address) }
    end

    # Private addresses the operator has explicitly opted back in to, set with
    # FEEDKIT_ALLOWED_PRIVATE_ADDRESSES as a comma or space separated list of
    # addresses and CIDR ranges.
    def allowed_address?(address)
      allowed_addresses.any? { |range| range.include?(address) }
    end

    def allowed_addresses
      ENV["FEEDKIT_ALLOWED_PRIVATE_ADDRESSES"].to_s.split(/[\s,]+/).reject(&:empty?).map { |address| IPAddr.new(address) }
    end

    # Opens TCP connections, refusing any address that is not routable on the
    # public internet.
    #
    # Hostnames are resolved here rather than by the socket so every candidate
    # address can be checked, and the connection is then made to the address
    # that was checked. Letting the socket resolve the name a second time would
    # leave room for the answer to change in between.
    #
    # Ported from Mastodon's Request::Socket.
    class Socket < ::TCPSocket
      CONNECT_TIMEOUT = 5
      RESOLV_TIMEOUT = 5

      class << self
        def open(host, port = nil, connect_timeout: nil, resolv_timeout: nil, **)
          connect_timeout ||= CONNECT_TIMEOUT
          resolv_timeout ||= RESOLV_TIMEOUT

          outer_e = nil
          socks = []
          addr_by_socket = {}

          addresses(host, resolv_timeout).each do |address|
            check_private_address!(address, host)

            sock = ::Socket.new(ipv6?(address) ? ::Socket::AF_INET6 : ::Socket::AF_INET, ::Socket::SOCK_STREAM, 0)
            sockaddr = ::Socket.pack_sockaddr_in(port, address)

            sock.setsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY, 1)
            sock.connect_nonblock(sockaddr)

            # If that hasn't raised an exception, we somehow managed to connect
            # immediately, close pending sockets and return immediately
            socks.each(&:close)
            return sock
          rescue IO::WaitWritable
            socks << sock
            addr_by_socket[sock] = sockaddr
          rescue => exception
            outer_e = exception
          end

          until socks.empty?
            _, writable, = IO.select(nil, socks, nil, connect_timeout)

            if writable.nil?
              socks.each(&:close)
              raise HTTP::TimeoutError, "Connect timed out after #{connect_timeout} seconds"
            end

            writable.each do |sock|
              socks.delete(sock)

              begin
                sock.connect_nonblock(addr_by_socket[sock])
              rescue Errno::EISCONN
                # Do nothing
              rescue => exception
                sock.close
                outer_e = exception
                next
              end

              socks.each(&:close)
              return sock
            end
          end

          raise outer_e if outer_e

          raise SocketError, "no address for #{host}"
        end

        alias_method :new, :open

        def check_private_address!(address, host)
          address = IPAddr.new(address)

          return if PrivateAddressCheck.allowed_address?(address)
          return unless PrivateAddressCheck.private_address?(address)

          raise PrivateNetworkAddress, "#{host} resolves to a private address: #{address}"
        end

        def addresses(host, timeout)
          [IPAddr.new(host).to_s]
        rescue IPAddr::InvalidAddressError
          resolvers = [Resolv::Hosts.new, Resolv::DNS.new.tap { |dns| dns.timeouts = timeout }]
          addresses = Resolv.new(resolvers).getaddresses(host)
          addresses.grep(Resolv::IPv6::Regex).take(2) + addresses.grep_v(Resolv::IPv6::Regex).take(2)
        end

        def ipv6?(address)
          address.match?(Resolv::IPv6::Regex)
        end
      end
    end
  end
end
