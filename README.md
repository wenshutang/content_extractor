# ContentExtractor

ContentExtractor is a lightweight DSL that converts unstructured html to structured data. It enables code to capture html elements in an idiomatic way. 

**Note**: ContentExtractor has to be used with **[Nokogiri](http://www.nokogiri.org/)** for html parsing


## Features
* Parse HTML elements using CSS selectors
* Simple tranformation from nested HTML elements to `json` ready objects
* Codify extract-transform (ETL) in a single step
* Includes a lightweight parallel crawler

## Installation

Add this line to Gemfile:

```ruby
gem 'content_extractor'
```

Then bundle:

    $ bundle

Or install it locally as:

    $ gem install content_extractor

## Getting started

#### Convert a small html snippet to an object
```
require 'nokogiri'
require 'content_extractor'
doc = Nokogiri::HTML("<html><body><h1>123 main st.</h1></body></html>")
elem = ContentExtractor::Element.new {
   address_  ContentExtractor::Matchable.match_first(doc, 'h1').text
}
{"address" => "123 main st."}
```
#### Note that:
1. `ContentExtractor::Element` is the basic building block that represents a html element. 
2. `Matchable.match_first` matches the first element with the `<h1>` tag and returns a [Nokogiri::XML::Node](http://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/Node) object.
3. `address_ some_value` inside the element block becomes `{"address" => "some_value"}`

## Parsing nested objects 
Complex nested objects can be easily represented with code. In essence, you can map your object hierarchy in code to match that of the html. 
Suppose we would like to extract all the Bob Ross products [from here](https://www.walmart.com/c/kp/bob-ross-painting-supplies)
```
require 'open-uri'
include ContentExtractor

doc = Nokogiri::HTML(open('https://www.walmart.com/c/kp/bob-ross-painting-supplies'))
data = ContentExtractor::Element.new do 
  item_selector = 'div.search-result-gridview-item.clearfix' 
  Matchable.match_any(doc, item_selector) do |item_elem|
    name_ Matchable.match_first(item_elem, 'h2').text
    price_ Matchable.match_first(item_elem, 'span.Price-group').text
  end
end
```
The relevant html objects are represented in hierarchy by nested ruby blocks. The `data` object then becomes:
```
[ 
  {
    "name" => "8 X 10 inch Professional ... Panels)",
    "price" => "$19.96"
  },
  ...
  {
    "name" => "Chalk Supply Furniture ... Small",
    "price" => "$11.99"
  }
]
```
#### A few things to note here:

An `element` accepts a block. Inside the block, a tagged name, value pair creates a corresponding key, value pair 
```
  foo bar
  {"foo" => "bar"}
```
If a block is supplied with the value, a new element is created
```
  foo bar { |param| ... }
  {"foo" => ContentExtractor::Element(param){...} }
```
Note that the outside scope is not maintained, it's advised to pass any pertinent objects through the block parameters.

`element` works by taking advantage of [`method_missing`](https://ruby-doc.org/core-2.4.0/BasicObject.html#method-i-method_missing) and ruby meta-programming. Some methods are defined in ruby that can be dangerous to overwrite ( `type, class, id,` etc. ). 
You can use an underscore to disambiguate your tag name from the method call.

Finally, calling the 

## Using the crawler
**To make content scrapping easier, ContentExtractor includes a lightweight multi-threaded crawler.**

Parsing of a page is represented by `ContentExtractor::Parser`. Inherit from this object and implement the `parse!` function.
```
class MyParser < ContentExtractor::Parser
  def parse!
      # opens the provided URL and stored as Nokogiri::HTML doc
      @html_doc = open_url
      # parsing code here
    end
end
MyParser.new('http://a.b.c').parse!
```

The `ContentExtractor::crawler` has an internal queue of parsers and can concurrently process them. Each parser has access to the crawler and may add additional parser or multiple parsers to the queue.

For example, let's say we would like to extract all the articles from a food recipe blog. Each article page follows a consistent html blueprint. We define the following parsers:
```
# One parser for the recipe pages since they share the same html structure
class RecipeParser < ContentExtractor::Parser
  ... code to parse a recipe page ...
end

# The front page parser extracts all the article links
class FrontPageParser < ContentExtractor::Parser
  def parse!
    @html_doc = open_url
    article_urls = parse_urls(@html_doc)
    # after all urls have been extracted, create a RecipeParser for each
    # and append them to the @crawler
    article_urls.each do |url|
      @crawler << RecipeParser.new(url, @crawler)
    end
  end
end

# Kick off the crawling
crawler = ContentExtractor::Crawler.new 
crawler << FrontPageParser.new('http://yummy.food', crawler)
crawler.crawl
```

To prevent overwhelming the target site, there is a default http request interval of 0.5 seconds. You may change that by setting `Crawler.new(interval=1)`

For detailed working  examples, checkout the example directory

## License

Copyright (c) 2017-2018 Wen Shu Tang

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
