class Plugins::Processes < Plugin

  def run
    ps_output = capture_command_output('ps', 'aux')[1..-1] || []
    { :count => ps_output.size }
  end

end
