require 'net/http'
require 'rubygems'
require 'HTTParty'
require 'colorize'

module WebCheck

  VERSION = '1.0.1'

  #
  # Class representing the result of a checked website
  #
  class PageCheckResult

    def initialize
      @links = {}
      @main_page_load_time = 0
    end

    # Add a page to the results
    # @param [String] link
    # @param [Integer] load_time
    def add_link(link, load_time)
      @links[link] = load_time
    end

    # Returns the number of pages checked
    # @return [Integer]
    def size
      return @links.size
    end

    # Returns average loading time in milliseconds
    # @return [Integer]
    def avg
      total_time = 0
      for key in @links.keys
        total_time += @links[key]
      end
      return total_time / @links.size
    end

    # Returns the fastest and the slowest results
    # @return [fastest_link:String, fastest_time:Integer, slowest_link:String, slowest_time:Integer]
    def peaks
      fastest_link = ''
      slowest_link = ''
      slowest_time = 0
      fastest_time = 0

      for link in @links.keys
        if @links[link] > slowest_time
          slowest_time = @links[link]
          slowest_link = link
        elsif fastest_time == 0 or @links[link] < fastest_time
          fastest_time = @links[link]
          fastest_link = link
        end
      end

      return fastest_link, fastest_time, slowest_link, slowest_time
    end

  end

  #
  # Class that does the magic
  #
  class PageChecker

    # @return [PageCheckResult]
    def check(url, debug_output=false, num_links=30)

      uri = URI(url)
      result = PageCheckResult.new

      if debug_output
        puts '--> Starting to load pages'
      end

      response, load_time = fetch(url)
      result.add_link(url, load_time)

      # Return http error
      if is_error(response)
        if debug_output
          puts ('[Main page error '+response.code.to_s+']').red
        end
        return result
      end

      # Fetch links on page
      links = find_links(uri, response.body)[0..num_links]
      i = 0
      links.each { |link|
        if debug_output
          print ("." * i) + link
          $stdout.flush
        end
        response, load_time = fetch(link)
        if debug_output
          puts is_error(response) ? (' [error '+response.code.to_s+']').red : ' [ok]'.green
        end
        result.add_link(link, load_time)
        i += 1
      }

      return result
    end

  private

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
    def find_links(uri, content)
      #regex = /href=\"(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
      # okey... lets hax this... todo: get hold of a regex that works...
      regex = /href=\"(.*)\"/ix
      links = Array.new
      content.scan(regex).each { |linker|
        link = linker[0].split('"')[0]
        if link != nil and is_valid(link)
          if link[0] == '/'
            links.push('%s://%s/%s' % [uri.scheme, uri.host, ltrim(link, '/')])
          elsif link.index(uri.host)
            links.push(link)
          end
        end
      }
      return links
    end

    def is_valid(url)
      valid = true
      url = url.downcase
      invalid = ['.jpg', '.jpeg', '.png', '.gif', '.ico', '.xml', '.php', '.css', '.js', 'mailto:']
      invalid.each { |ext|
        if url.index(ext)
          valid = false
          break
        end
      }
      return valid
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
