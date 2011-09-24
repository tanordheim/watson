class Plugins::Load < Plugin

  def run
    average = load_average_for_last_minute.to_f
    { :average => average }
  end

  private

  # Returns the load average for the last minute.
  def load_average_for_last_minute
    
    if PlatformInfo.linux?

      load_info = open('/proc/loadavg', 'r') { |f| f.read }.strip
      load_info.split(' ')[0]

    elsif PlatformInfo.osx?

      uptime = capture_command_output('uptime')
      uptime[0].strip.match(/load averages\: (\d+\.\d+)/)[1]

    else
      unsupported_platform
    end

  end

end
