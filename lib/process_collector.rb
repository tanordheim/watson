require 'open3'

class ProcessCollector

  include Sys

  def initialize(config)
    @config = config
  end

  def gather_process_info

    processes = []

    stdin, stdout, stderr = Open3.popen3('ps', 'auxww')
    ps_lines = stdout.readlines[1..-1] # Strip away the column descriptions.

    # Go through each line in the PS output and extract the columns we need.
    #
    # Data we're gathering from each process are:
    #  - Username of the user owning the process
    #  - PID
    #  - CPU usage (%)
    #  - Memory usage (%)
    #  - Virtual memory size
    #  - Residential set size
    #  - TTY
    #  - State
    #  - Started at
    #  - CPU time
    #  - Command
    ps_lines.each do |process|

      ps_columns = process.strip.split(/\s+/, 11)

      process_info = {}
      ps_column_indexes.each do |column_name, index|
        process_info[column_name] = ps_columns[index]
      end

      processes.push process_info

    end

    processes

  end

  protected

  # Returns the column indexes for all fields in the ps process output
  def ps_column_indexes
    @ps_column_indexes ||= {
      :user => 0,
      :pid => 1,
      :cpu => 2,
      :memory => 3,
      :vsz => 4,
      :rss => 5,
      :tty => 6,
      :status => 7,
      :started => 8,
      :cpu_time => 9,
      :command => 10
    }
  end

  private

  # Returns the current configuration.
  def config
    @config
  end

end
