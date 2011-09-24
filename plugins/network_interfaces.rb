class Plugins::NetworkInterfaces < Plugin

  def run

    labels = network_interface_labels
    counters = network_interface_counters

    # Merge the labels into the counter information.
    counters.keys.each do |interface_name|
      if labels[interface_name]
        counters[interface_name][:labels] = labels[interface_name]
      end
    end

    counters

  end

  private

  # Returns labels for available network interfaces
  def network_interface_labels

    labels = {}
    ipv4_address_regexp = Regexp.new(/^[\d\.]+$/)
    ipv6_address_regexp = Regexp.new(/^[a-f\d\:]+$/)

    if PlatformInfo.linux?

      net_dev = IO.readlines('/proc/net/dev')[2..-1] # Skip the column headers.
      net_dev.each do |net_dev_line|

        tokens = net_dev_line.strip.split(':')
        interface = tokens[0]
        labels[interface] = {}

        # Run the ifconfig command to fetch interface details.
        ifconfig = capture_command_output('ifconfig', interface)
        ipv4_address_line = ifconfig.select { |line| line.strip =~ /^inet addr\:/ }.first
        ipv6_address_line = ifconfig.select { |line| line.strip =~ /^inet6 addr\:/ }.first

        if ipv4_address_line
          address_tokens = ipv4_address_line.split(/\s+/)[0].split(':')
          labels[interface][:ipv4_address] = address_tokens[1]
        end

        if ipv6_address_line
          address_tokens = ipv6_address_line.split(/\s+/)[0].split(':')
          labels[interface][:ipv6_address] = address_tokens[1]
        end
        
      end

    elsif PlatformInfo.osx?

      netstat = capture_command_output('netstat', '-idn')[1..-1] # Skip the column header line
      netstat.each do |netstat_line|

        tokens = netstat_line.strip.split(/\s+/)

        interface = tokens[0]
        labels[interface] ||= {}


        # If this line has 10 tokens, thenit means an IP address is present in
        # the Address column.
        if tokens.size == 10

          # If we have an IPv4 address in this netstat line, add it to the
          # interface labels unless an address is already defined.
          if tokens[3] =~ ipv4_address_regexp
            labels[interface][:ipv4_address] ||= tokens[3]
          end

          # If we have an IPv6 address in this netstat line, add it to the
          # interface labels unless an address is already defined.
          if tokens[3] =~ ipv6_address_regexp
            labels[interface][:ipv6_address] ||= tokens[3]
          end

        end

      end

    else
      unsupported_platform
    end

    labels

  end

  # Returns counters for all available network interfaces
  def network_interface_counters
    
    counters = {}

    # Data we need to gather about each interface is:
    #  - Received packets
    #  - Received packet errors
    #  - Transmitted packets
    #  - Transmitted packet errors
    #  - Received bytes
    #  - Transmitted bytes

    if PlatformInfo.linux?

      net_dev = IO.readlines('/proc/net/dev')[2..-1] # Skip the column headers
      net_dev.each do |net_dev_line|

        tokens = net_dev_line.strip.split(':')
        interface = tokens[0]
        counters = tokens[1].split(/\s+/)

        rx_bytes = tokens[0]
        rx_packets = tokens[1]
        rx_packet_errors = tokens[2]
        tx_bytes = tokens[8]
        tx_packets = tokens[9]
        tx_packet_errors = tokens[10]

        counters[interface] = {
          :packets => {
            :rx => rx_packets,
            :rx_errors => rx_packet_errors,
            :tx => tx_packets,
            :tx_errors => tx_packet_errors
          },
          :bytes => {
            :rx => rx_bytes,
            :tx => tx_bytes
          }
        }

      end

    elsif PlatformInfo.osx?

      netstat = capture_command_output('netstat', '-nbid')[1..-1] # Skip the column header line
      netstat.each do |netstat_line|

        tokens = netstat_line.strip.split(/\s+/)
        interface = tokens[0]
        unless counters.key?(interface)

          rx_packets = tokens[4].to_i
          rx_packet_errors = tokens[5].to_i
          rx_bytes = tokens[6].to_i
          tx_packets = tokens[7].to_i
          tx_packet_errors = tokens[8].to_i
          tx_bytes = tokens[9].to_i

          counters[interface] = {
            :packets => {
              :rx => rx_packets,
              :rx_errors => rx_packet_errors,
              :tx => tx_packets,
              :tx_errors => tx_packet_errors
            },
            :bytes => {
              :rx => rx_bytes,
              :tx => tx_bytes
            }
          }

        end

      end

    else
      unsupported_platform
    end

    counters

  end
 
end
