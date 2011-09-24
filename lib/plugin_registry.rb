# Base class for all plugins.
require File.expand_path(File.join(File.dirname(__FILE__), 'plugin'))

# Define the module plugins belong to.
module Plugins
end

# Define the plugin registry class
class PluginRegistry
  
  @@plugins = {}

  # Initialize the plugin registry, optionally passing in a list of plugins to
  # activate. If no plugins are specified, all plugins will be activated.
  def self.initialize!(activate_plugins = [])

    # Include all plugins found in the plugins/ directory.
    Dir[File.join(File.expand_path(File.join(File.dirname(__FILE__), '..', 'plugins')), '*.rb')].each do |path|

      filename = File.basename(path, '.rb')
      if activate_plugins.empty? || activate_plugins.include?(filename)
      
        # Require the plugin file.
        require path

        # Convert the filename to a class name and register it in the plugin registry.
        class_name = filename.split('_').collect { |w| w.capitalize }.join

        # Check if the class name is defined (checking that the plugin is named
        # properly).
        if Plugins.const_defined?(class_name, false)
          register(filename, Plugins.const_get(class_name))
        else
          raise "Expected plugin #{filename} to define class Plugins::#{class_name}, but class name was not found."
        end

      end

    end
    
    Logger.info "Initialized plugin registry with the following plugins: #{plugins.keys.join(', ')}"

  end

  def self.register(id, class_name)
    @@plugins[id.to_sym] = class_name
  end

  def self.plugins
    @@plugins
  end

end
