require 'nokogiri'
require 'uri'
require 'open-uri'
require_relative 'element'

module ContentExtractor

  class Parser
    # The current Document object
    attr_accessor :html_doc

    attr_accessor :data

    attr_accessor :crawler

    def self.inherited(child)
      [:parse!].each do | method |
        child.send(:define_method, method) do 
          raise "You must implement #{method}!"
        end
      end
    end

    def initialize url, crawler, options = {}, &block
      @host_url   = URI.parse(url).scheme ? url : "http://#{url}"
      @crawler    = crawler
    end

    def add_attributes attrs
      @data.merge attrs
    end

    protected
    # Could be blocking, also could add hook for js driven rendering
    def open_url
      u = URI.parse(@host_url)
      u.open { |file| @html_doc = Nokogiri::HTML(file) }

    rescue OpenURI::HTTPError => excp
      raise "#{excp}, could not open #{@host_url}: "
    ensure
      @html_doc
    end

    def truncate(url)
      url = url.size > 60 ? url[0..30]+'...'+ url[-30..-1] : url
    end

  end

end
