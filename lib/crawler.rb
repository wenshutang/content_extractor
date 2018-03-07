require 'thread'

module ContentExtractor

  class Crawler
    
    attr_reader :errors, :domain, :threads

    def initialize max_threads=5, opts={}, &block
      # Thread.abort_on_exception = true
      @max_threads = max_threads
      @queue       = []
      @threads     = []

      # more idiomatic way of initializing the crawler before running it
      yield self if block_given?
    end

    def crawl
      @main_thread = Thread.current

      until @queue.empty? do
        # puts "q cnt: #{@queue.size}, thrd cnt: #{@threads.count}"
        if @threads.count < @max_threads
          parser = @queue.shift
          # puts "spwaning parser: #{parser.object_id}"
          spawn_parser_thread parser
        end
        sleep 1
      end

      @threads.each do |t| 
        begin
          t.join 
        rescue Exception => e
          # catch any exception raised by a thread instance
          puts "log exception here: #{e}"
          puts "#{e.inspect}"
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
