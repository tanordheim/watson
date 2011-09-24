require 'log4r'

module Logger

  include Log4r

  def self.debug(message)
    logger.debug(message)
  end

  def self.info(message)
    logger.info(message)
  end

  def self.warn(message)
    logger.warn(message)
  end

  def self.error(message)
    logger.error(message)
  end

  def self.fatal(message)
    logger.fatal(message)
  end

  private

  def self.logger
    unless defined?(@@logger)
      @@logger = Logger.new('watson')
      @@logger.outputters = Outputter.stdout
    end
    @@logger
  end

end
