module ManageiqForeman
  # like the WillPaginate collection
  class PagedResponse
    include Enumerable

    attr_accessor :resource

    attr_accessor :page
    attr_accessor :total
    attr_accessor :size #subtotal
    attr_accessor :results
    # per_page, search, sort
    def initialize(json)
      if json.is_a?(Hash) && json["results"]
        @results = json["results"]
        @total   = json["total"].to_i
        @size    = @results.size
        @page    = json["page"]
      else # Array
        @results = json.is_a?(Hash) ? [json] : json
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
  end
end
