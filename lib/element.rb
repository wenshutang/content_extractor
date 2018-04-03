require 'nokogiri'
require 'open-uri'
require 'json'
require_relative 'utilities'

module ContentExtractor

  class Element

    attr_accessor :data
    
    def initialize &block
      @data = {}

      return unless block_given?

      # if block.arity <= 0
        @context = eval 'self', block.binding
        # puts "- respond to match_first? #{@context.respond_to?('match_first')}"
        # puts "- context_name: #{@context.class.name}"
        instance_eval &block

      # else
         # yield self
      # end

    end

    def method_missing(method, *args, &block)
      # puts "missing: #{method.to_s}" #, arg[0]: #{args.first}"
      key = method.to_s.chomp('_')
      # unless @context.respond_to?('match_first')
      #   puts "!!no match_first: #{@context.class.name}"
      # end

      # if @context && @context.respond_to?(method)
      if @context.respond_to?(method)
        # puts "send to current context: #{method.to_s}"
        @context.send(method, *args, &block) #"child.#{method}"
      elsif block_given? 
        child = Element.new
        self[key] = child
        child.instance_exec *args, &block
      else
        self[key] = args.first
      end

    end

    # if a key is present, data is appended as an enumerable
    def []= k, v
      # puts "Adding #{k}: #{v}"
      if @data.is_a?(Hash)
        @data.has_key?(k) ? self << {k => v} : @data[k] = v
        return
      end
      @data.last.has_key?(k) ? self << {k => v} : @data.last[k] = v

    end

    def << v
      if @data.is_a?(Hash) 
        @data = [@data] << v
      else
        @data << v
      end
    end

    def [] k
      @data[k]
    end
   
    def to_h
      if @data.is_a? Array
        @data.map { |e| e.to_h }
      else
        @data.each do |k,v| 
          @data[k] = v.to_h if v.is_a? ContentExtractor::Element
        end
      end
      @data
    end
    alias :to_data :to_h

    def to_h!
      if @data.is_a? Enumerable
        @data = Array.new(@data)
      else
        @data = @data.to_h
      end
    end
    alias :to_data! :to_h!

    def inspect
      JSON.pretty_generate(self.to_h).gsub(":", " =>")
    end

  end

end
