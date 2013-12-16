require 'rubygems'
require 'HTTParty'

module WebCheck

  VERSION = '1.0.1'

  #
  # Class representing the result of a checked website
  #
  class PageCheckResult < Hash

    # Add a page to the results
    # @param [String] url
    # @param [Integer] load_time
    def add_page(url, load_time)
      self[url] = load_time
    end

    # Returns average loading time in milliseconds
    # @return [Integer]
    def avg
      total_time = 0
      for url in self.keys
        total_time += self[url]
      end
      return total_time / self.size
    end

    # Returns the fastest and the slowest results
    # @return [fastest_url:String, fastest_time:Integer, slowest_url:String, slowest_time:Integer]
    def peaks
      fastest_url = ''
      slowest_url = ''
      slowest_time = 0
      fastest_time = 0

      for url in self.keys
        if self[url] > slowest_time
          slowest_time = self[url]
          slowest_url = url
        elsif fastest_time == 0 or self[url] < fastest_time
          fastest_time = self[url]
          fastest_url = url
        end
      end

      return fastest_url, fastest_time, slowest_url, slowest_time
    end

  end

  #
  # Class that does the magic
  #
  class PageChecker

    # @param [Object] debug
    def initialize(debug=false)
      @debug = debug
      @output_lambda = lambda { |message, is_error=nil|
        print(message)
        $stdout.flush
      }
    end

    # This method makes it possible to have your own debug procedure
    # The function given will be executed when this class sends debug
    # messages, but it will only be invoked in case @debug is set
    # true upon initialization
    #
    # @param output_lambda
    def output_method(output_lambda)
      @output_lambda = output_lambda
    end

    # @param [String] url
    # @param [Integer] num_pages
    # @return [PageCheckResult]
    def check(url, num_pages=30)

      uri = URI(url)
      result = PageCheckResult.new

      debug('--> Starting to load pages')

      response, load_time = fetch(url)
      result.add_page(url, load_time)

      # http error
      if is_error(response)
        debug('[Main page error '+response.code.to_s+']', true)
        return result
      end

      # Fetch URL's on page
      page_urls = find_urls(uri, response.body)[0..num_pages]
      i = 0
      page_urls.each { |url|
        debug(("." * i) + url, nil, false)
        response, load_time = fetch(url)

        if is_error(response)
          debug(' [error '+response.code.to_s+']', true)
        else
          debug(' [ok]', false)
        end

        result.add_page(url, load_time)
        i += 1
      }

      return result
    end

  private

    def debug(message, is_error=nil, add_break=true)
      if @debug
        @output_lambda.call(message + (add_break ? "\n":''), is_error)
      end
    end

    def is_error (response)
      return response.code.to_i > 299
    end

    def fetch(url)

      time_begin = Time.now

      options = {:headers => {'User-Agent' => 'Ruby WebCheck ' + VERSION}}
      response = HTTParty.get(url, options)

      load_time = ((Time.now - time_begin) * 1000).to_i

      return response, load_time
    end

    # @param [URI] uri
    # @param [String] content
    # @return [Array]
    def find_urls(uri, content)
      #regex = /href=\"(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
      # okey... lets hax this... todo: write a regex that works...
      regex = /href=\"(.*)\"/ix
      page_urls = Array.new
      content.scan(regex).each { |url|
        url = url[0].split('"')[0]
        if url != nil and is_valid(url)
          if url[0] == '/'
            page_urls.push('%s://%s/%s' % [uri.scheme, uri.host, ltrim(url, '/')])
          elsif url.index(uri.host)
            page_urls.push(url)
          end
        end
      }
      return page_urls
    end

    def is_valid(url)
      url = url.downcase
      invalid = ['.jpg', '.jpeg', '.png', '.gif', '.ico', '.xml', '.php', '.css', '.js', 'mailto:']
      invalid.each { |ext|
        if url.index(ext)
          return false
        end
      }
      return true
    end

    def ltrim(str, character)
      n = 0
      while str[n, 1] == character.to_s
        n += 1
      end
      if n > 0
        str.slice!(0, n)
      end
      return str
    end

  end

end
