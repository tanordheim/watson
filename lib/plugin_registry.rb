# Base class for all plugins.
require File.expand_path(File.join(File.dirname(__FILE__), 'plugin'))

# Define the module plugins belong to.
module Plugins
end

# Define the plugin registry class
class PluginRegistry
  
  @@plugins = {}

  def self.register(id, class_name)
    @@plugins[id.to_sym] = class_name
  end

  def self.plugins
    @@plugins
  end

end

# Include all plugins found in the plugins/ directory.
Dir[File.join(File.expand_path(File.join(File.dirname(__FILE__), '..', 'plugins')), '*.rb')].each do |path|

  # Require the plugin file.
  require path

  # Convert the filename to a class name and register it in the plugin registry.
  filename = File.basename(path, '.rb')
  class_name = filename.split('_').collect { |w| w.capitalize }.join

  # Check if the class name is defined (checking that the plugin is named
  # properly).
  if Plugins.const_defined?(class_name, false)
    PluginRegistry.register(filename, Plugins.const_get(class_name))
  else
    raise "Expected plugin #{filename} to define class Plugins::#{class_name}, but class name was not found."
  end

end
