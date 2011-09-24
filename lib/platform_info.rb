require 'sys/uname'

module PlatformInfo
  include Sys

  # Returns true if this platform is supported by the Watson agent.
  def self.supported?
    linux? || osx?
  end

  # Returns the name of the system the agent is running on.
  def self.system_name
    @@system_name ||= Uname.uname.sysname
  end

  def self.linux?
    system_name == 'Linux'
  end

  def self.osx?
    system_name == 'Darwin'
  end

end
