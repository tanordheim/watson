require 'eventmachine'

class DataCollector

  def initialize(config)
    @config = config
    @plugins = []
    initialize_plugins
  end

  # Gather metrics from all available plugins.
  def gather_metrics

    pending_plugins = plugins.collect(&:id)
    @plugin_results = {}

    EM.run do
      plugins.each do |plugin|

        Thread.new do
          begin
            run_plugin(plugin)
          ensure
            pending_plugins.delete(plugin.id)
          end
        end

      end

      until pending_plugins.empty?; end
      EM.stop

    end

    @plugin_results

  end

  protected

  # Initialize all available plugins.
  def initialize_plugins
    PluginRegistry.plugins.each do |id, plugin_class|
      @plugins << plugin_class.new(id, config)
    end
  end

  # Run the specified plugin, gathering information and storing the data in our
  # result map.
  def run_plugin(plugin)

    worker = CollectorWorker.new(plugin)

    worker.callback do |result|
      Logger.debug "Worker for #{plugin.id} completed with result=#{result.inspect}"
      @plugin_results[plugin.id] = result
    end
    worker.errback do |error|
      Logger.error "Worker for #{plugin.id} failed: #{error}"
    end

    worker.run

  end

  private

  # Returns the current configuration.
  def config
    @config
  end

  # Returns a list of all initialized plugins.
  def plugins
    @plugins
  end

  # Describes an EventMachine worker thats used to run all plugins in parallel.
  class CollectorWorker
    include EM::Deferrable

    def initialize(plugin)
      @plugin = plugin
    end

    def run
      begin
        result = plugin.run
        succeed result
      rescue StandardError => e
        
        Logger.debug "Exception thrown from plugin #{plugin.id}: #{e.message}"
        e.backtrace.each do |line|
          Logger.debug line
        end

        fail e.message

      end
    end

    private

    def plugin
      @plugin
    end

  end

end
