require 'element'
require 'parser'
require 'crawler'
require 'utilities'
require 'logger'

module ContentExtractor

  def logger
    ContentExtractor.logger
  end

  def self.logger
    @logger ||= Logger.new(STDOUT)
    @logger.level = Logger::WARN
    @logger
  end

end
