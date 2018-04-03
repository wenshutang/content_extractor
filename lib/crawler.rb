require 'thread'
require_relative 'content_extractor'

module ContentExtractor

  class Crawler
    
    attr_reader :errors, :domain, :threads

    attr_accessor :queue

    include ContentExtractor

    def initialize max_threads=5, opts={}, &block
      Thread.abort_on_exception = true
      @max_threads = max_threads
      @queue       = Queue.new
      @threads     = []
      @interval    = opts['interval'] || 0.5

      # more idiomatic way of initializing the crawler before running it
      yield self if block_given?
    end

    def crawl
      @main_thread = Thread.current

      until @queue.empty? and @threads.empty? do
        begin
          @threads.each {|t| puts t.status}
          if @threads.count < @max_threads
            parser = @queue.deq
            logger.info "spwaning parser thread #{parser.object_id}"
            spawn_parser_thread parser
          end
          sleep @interval
        rescue Exception
          logger.warn "Queue now empty, crawl finished."
        end
      end
    end

    def add_parser parser
      @queue << parser
    end
    alias :<< :add_parser

  private
    def spawn_parser_thread ps
      @threads << Thread.new do
        ps.parse!
        @threads.delete(Thread.current)
      end
    end

  end

end
