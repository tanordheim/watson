class Plugins::Disks < Plugin

  def run

    labels = filesystem_labels
    usage = filesystem_usage

    # Merge the labels into the usage information.
    usage.keys.each do |device_name|
      if labels[device_name]
        usage[device_name][:labels] = labels[device_name]
      end
    end

    usage

  end

  private

  # Return labels for all mounted filesystems
  def filesystem_labels

    labels = {}

    mount = capture_command_output('mount')
    mount.each do |mount_line|

      mount_line.strip!
      device = mount_line.match(/^(.*?) on/)[1]

      if PlatformInfo.linux?

        # /dev/hda3 on / type ext4 (rw,errors=remount-ro)
        mount_point = mount_line.match(/^#{Regexp.quote(device)} on (.*?) type/)[1]
        fs_type = mount_line.match(/type (.*?) \(/)[1]

      elsif PlatformInfo.osx?

        # /dev/disk0s2 on / (hfs, local, journaled)
        mount_point = mount_line.match(/^#{Regexp.quote(device)} on (.*?) \(/)[1]
        fs_type = mount_line.match(/ \((.*?), /)[1]
        
      else
        unsupported_platform
      end

      labels[device] = {
        :mount_point => mount_point,
        :file_system => fs_type
      }

    end

    labels

  end

  # Returns usage information for all mounted filesystems
  def filesystem_usage

    usage = {}

    df = capture_command_output('df', '-k')[1..-1] # Don't include the column headers.
    df.each do |df_line|

      df_line.strip!
      device = df_line.match(/^(.*?)\s{2,}/)[1]
      tokens = df_line.gsub(/^#{Regexp.quote(device)}\s+/, '').split(/\s+/, 5)
      
      # Convert all KB values to bytes.
      size = tokens[0].to_i * 1024
      used = tokens[1].to_i * 1024
      available = tokens[2].to_i * 1024
      used_percentage = tokens[3].to_i

      usage[device] = {
        :size => size,
        :used => used,
        :used_percentage => used_percentage,
        :available => available
      }

    end

    usage

  end

end
