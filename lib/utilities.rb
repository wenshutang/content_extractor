module Utilities
  module Matchable
    
    extend self

    def match_any frag, selector, *args, &block
      frag.css(selector).map do |elem|
        block.call elem, args if block_given?
      end
    end

    def match_first frag, selector, *args, &block
      elem = frag.at_css selector
      if block_given?
        block.call elem, args
      else
        elem
      end
    end

  end
end
