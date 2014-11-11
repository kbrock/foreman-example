module ProvidersForeman
  # like the WillPaginate collection
  class PagedResponse
    include Enumerable

    attr_accessor :json
    attr_accessor :page
    attr_accessor :results

    # total, subtotal, per_page
    def initialize(json, filter = nil)
      # able to pass a PagedResponse in
      @json = json.is_a?(PagedResponse) ? json.json : json

      @results = @json["results"]
      @page = @json["page"]
      @results = self.class.prune(@results, filter)
    end

    def each(&block)
      results.each(&block)
    end

    def [](name)
      results[name]
    end

    def empty?
      results.empty?
    end

    # in the future, this should happen in the actual api call
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
