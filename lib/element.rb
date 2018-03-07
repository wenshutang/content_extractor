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
        # puts "- after instance_eval"
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
        # puts ">>> CASE 3 <<<"
        self[key] = args.first
      end

    end

    # if a key is present, data is appended as an enumerable
    def []= k, v
      @data[k] = @data[k] ? [*@data[k]] << v : v
    end

    def [] k
      @data[k]
    end

    # def key_cnt
    #   @data.keys.each{|k| p k}
    # end
    
    def to_h
      @data.each do | k,v | 
#        if v.is_a? Enumerable
#          @data[k] = v.map { |e| e.to_data }
        @data[k] = v.to_h if v.is_a? ContentExtractor::Element

      end
      @data
    end
    alias :to_data :to_h

    def inspect
      JSON.pretty_generate(self.to_h).gsub(":", " =>")
    end

  end

end
