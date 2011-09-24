#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'yaml'
require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'platform_info'))
require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'logger'))
require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'plugin_registry'))
require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'process_collector'))
require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'data_collector'))

# Check if this is running on a supported platform.
unless PlatformInfo.supported?
  raise "This platform is not supported by the Watson agent: #{PlatformInfo.system_name}"
end

# Load the configuration file.
config_path = File.expand_path(File.join(File.dirname(__FILE__), 'config.yml'))
config = open(config_path, 'r') { |f| YAML.load(f) }

# Print some information when the agent starts.
Logger.info "Starting Watson agent run for server #{config['sherlock']['server']}:#{config['sherlock']['port']}"
Logger.info "Identifying self as #{config['node']['id']}"

# Build the data collection we're pushing to Sherlock.
data = {
  :node => config['node']['id'],
  :agent_version => '1.0.0'
}

# Construct a new process collector and ask it to collect info about all
# running processes.
process_collector = ProcessCollector.new(config)
data[:processes] = process_collector.gather_process_info
Logger.info "Read information about #{data[:processes].size} running processes"

# Construct a new data collector an ask it to collect all available data.
collector = DataCollector.new(config)
data[:data] = collector.gather_metrics
Logger.info "Gathered information from #{PluginRegistry.plugins.size} available plugins"

Logger.debug data[:data]
