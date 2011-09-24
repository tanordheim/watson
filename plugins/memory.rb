class Plugins::Memory < Plugin

  def run
    physical = physical_memory_info
    swap = swap_memory_info
    { :physical => physical, :swap => swap }
  end

  private

  # Returns information about the physical memory.
  def physical_memory_info

    if PlatformInfo.linux?

      {
        :total => proc_meminfo['MemTotal'],
        :used => proc_meminfo['MemTotal'] - proc_meminfo['MemFree'],
        :cached => proc_meminfo['Cached'],
        :free => proc_meminfo['MemFree'] 
      }

    elsif PlatformInfo.osx?

      hw_memsize = capture_command_output('sysctl', 'hw.memsize')[0]
      total_memory = hw_memsize.split(':')[1].strip.to_i

      # Parse the header information produced by top -l 1 to figure out the
      # physical memory stats.
      top = capture_command_output('top', '-l', '1')
      top_phys_mem = top.select { |t| t =~ /^PhysMem\:/ }.first.strip.gsub(/^PhysMem\:\s+/, '')
      top_phys_mem_pairs = top_phys_mem.split(',')

      phys_mem = {}
      top_phys_mem_pairs.each do |top_phys_mem_pair|
        items = top_phys_mem_pair.strip.split(/\s+/)
        key = items[1].gsub(/\W/, '')
        value = items[0].to_i * 1024 * 1024 # Convert MB to bytes
        phys_mem[key] = value
      end

      {
        :total => total_memory,
        :used => phys_mem['used'],
        :free => phys_mem['free']
      }

    else
      unsupported_platform
    end

  end

  # Returns information about the swap memory.
  def swap_memory_info

    if PlatformInfo.linux?

      {
        :total => proc_meminfo['SwapTotal'],
        :used => proc_meminfo['SwapTotal'] - proc_meminfo['SwapFree'],
        :cached => proc_meminfo['SwapCached'],
        :free => proc_meminfo['SwapFree']
      }

    elsif PlatformInfo.osx?

      swapusage = capture_command_output('sysctl', 'vm.swapusage')[0].strip
      swap = {}
      swap_pairs = swapusage.gsub(/^vm\.swapusage\:\s+/, '').split(/\s{2,}/)
      swap_pairs.each do |swap_pair|

        items = swap_pair.split('=', 2)
        key = items[0].strip
        value = items[1].strip.to_i * 1024 * 1024 # Convert MB to bytes

        swap[key] = value

      end

      {
        :total => swap['total'],
        :used => swap['used'],
        :free => swap['free']
      }
      
    else
      unsupported_platform
    end

  end

  # Read /proc/meminfo on Linux based systems and return the data as a hash.
  def proc_meminfo

    unless defined?(@proc_meminfo)

      @proc_meminfo = {}

      meminfo = IO.readlines('/proc/meminfo')
      meminfo.each do |meminfo_line|

        pairs = meminfo_line.strip.split(':', 2)
        key = pairs[0].strip
        value = pairs[1].strip

        # Remove "kB" from the value and multiply it by 1024.
        value = value.to_i * 1024

        @proc_meminfo[key] = value

      end

    end
    @proc_meminfo

  end

end
