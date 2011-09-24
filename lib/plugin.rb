require 'open3'

# This is a base class for all data collection plugins.
class Plugin

  # Initialize the plugin.
  def initialize(id, config)
    @id = id
    @config = config
  end

  # Run the plugin and gather all metrics available. This should be overridden
  # by any plugin implementation.
  def run
    {}
  end

  # Returns the id of the current plugin.
  def id
    @id
  end

  # Returns the name of the current plugin.
  def name
    self.class.name.split('::').last
  end

  protected

  # Raise an unsupported platform-error
  def unsupported_platform
    raise "Plugin does not support the platform #{PlatformInfo.system_name}"
  end

  # Capture the output of the specified command.
  def capture_command_output(command, *args)

    stdin, stdout, stderr = Open3.popen3(command, *args)
    output = stdout.readlines
    errors = stderr.readlines

    # If the command printed any errors, log them.
    if errors.size > 0
      errors.each do |line|
        Logger.warn "`#{command}` yielded error output: #{line.strip}"
      end
    end

    output

  end

  private

  # Returns the current configuration.
  def config
    @config
  end

end
