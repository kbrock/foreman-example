module ProvidersForeman
  # like the WillPaginate collection
  class PagedResponse
    include Enumerable

    attr_accessor :resource
    attr_accessor :remote_filter
    attr_accessor :method

    attr_accessor :page
    attr_accessor :total
    attr_accessor :size #subtotal
    attr_accessor :results
    # per_page, search, sort
    def initialize(json)
      if json.is_a?(Hash)
        @results = json["results"]
        @total   = json["total"].to_i
        @size    = json["subtotal"].to_i
        @page    = json["page"]
      else # Array
        @results = json
        @total = @size = json.size
        @page  = 1
      end
    end

    def each(&block)
      results.each(&block)
    end

    def [](name)
      results[name]
    end

    def empty?
      size == 0 #results.empty?
    end

    def self.prune(results, filter)
      filter = filter.select { |_n,v| !v.nil? } unless filter.nil?
      if filter.nil? || filter.empty?
        results
      else
        results.select do |r|
          !filter.detect { |n, v| r[n] != v }
        end
      end
    end
  end
end
