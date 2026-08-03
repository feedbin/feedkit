# frozen_string_literal: true

require "ipaddr"
require "resolv"
require "socket"
require "http"
require_relative "errors"

# Ported from Mastodon's PrivateAddressCheck.
module Feedkit
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
    ].each(&:freeze).freeze

    module_function

    def private_address?(address)
      # An IPv4-mapped or IPv4-compatible IPv6 address reaches the same host as
      # the IPv4 address it embeds, and an IPv4 range never matches an IPv6
      # address, so the IPv4 form is what gets compared. IPAddr#native returns
      # the address unchanged when there is nothing to unwrap.
      address = address.native if address.ipv6?
      address.private? || address.loopback? || address.link_local? || CIDR_LIST.any? { |cidr| cidr.include?(address) }
    end

    # Opens TCP connections, refusing any address that is not routable on the
    # public internet.
    class Socket < ::TCPSocket
      CONNECT_TIMEOUT = 5
      RESOLV_TIMEOUT = 5

      class << self
        def open(host, port = nil, connect_timeout: nil, resolv_timeout: nil, **)
          socks = []
          address_by_socket = {}
          outer_exception = nil

          connect_timeout ||= CONNECT_TIMEOUT
          resolv_timeout ||= RESOLV_TIMEOUT

          # Every candidate is checked before anything is opened. Checking as we
          # go would let a connection error from a later address overwrite the
          # rejection, hiding why the request was refused, and would connect to
          # a host that answers with a mix of public and private addresses.
          candidates = addresses(host, resolv_timeout)
          candidates.each { |address| check_private_address!(address, host) }

          # A deadline rather than a per-select timeout: a socket that becomes
          # writable only to fail restarts the loop, and each restart would
          # otherwise be granted the full timeout again.
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + connect_timeout

          candidates.each do |address|
            sock = ::Socket.new(address.ipv6? ? ::Socket::AF_INET6 : ::Socket::AF_INET, ::Socket::SOCK_STREAM, 0)
            sockaddr = ::Socket.pack_sockaddr_in(port, address.to_s)

            sock.setsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY, 1)
            sock.connect_nonblock(sockaddr)

            # If that hasn't raised an exception, we somehow managed to connect
            # immediately and can return without waiting on the others
            return sock
          rescue IO::WaitWritable
            socks << sock
            address_by_socket[sock] = sockaddr
          rescue => exception
            sock&.close
            outer_exception = exception
          end

          until socks.empty?
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            ready = (remaining > 0) ? IO.select(nil, socks, nil, remaining) : nil

            if ready.nil?
              raise HTTP::TimeoutError, "Connect timed out after #{connect_timeout} seconds"
            end

            _, writable, = ready

            writable.each do |sock|
              socks.delete(sock)

              begin
                sock.connect_nonblock(address_by_socket[sock])
              rescue Errno::EISCONN
                # Do nothing
              rescue => exception
                sock.close
                outer_exception = exception
                next
              end

              return sock
            end
          end

          raise outer_exception if outer_exception

          raise SocketError, "no address for #{host}"
        ensure
          # Whatever is still pending lost the race, timed out, or was abandoned
          # by an exception on the way out. The socket being returned has always
          # been taken out of the list by this point.
          socks.each(&:close)
        end

        alias_method :new, :open

        def check_private_address!(address, host)
          return unless PrivateAddressCheck.private_address?(address)

          raise PrivateNetworkAddress, "#{host} resolves to a private address: #{address}"
        end

        def addresses(host, timeout)
          [IPAddr.new(host)]
        rescue IPAddr::InvalidAddressError
          resolvers = [Resolv::Hosts.new, Resolv::DNS.new.tap { |dns| dns.timeouts = timeout }]
          addresses = Resolv.new(resolvers).getaddresses(host)
          found = addresses.grep(Resolv::IPv6::Regex).take(2) + addresses.grep_v(Resolv::IPv6::Regex).take(2)
          found.map { |address| IPAddr.new(address) }
        end
      end
    end
  end
end
