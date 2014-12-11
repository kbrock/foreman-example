module ProvidersForeman
  class Connection
    attr_accessor :connection_attrs

    def initialize(connection_attrs)
      @connection_attrs = connection_attrs
    end

    def api_version
      raw_home.status.first["api_version"]
    end

    def all(method)
      expected_size = nil
      page = 0
      all = []

      while expected_size.nil? || all.size < expected_size
        small = public_send(method, :page => (page +=1), :per_page => 50)
        expected_size ||= small.total
        break if small.empty?
        all += small.to_a
        #puts "page #{page}: #{all.size}/#{expected_size}"
      end
      puts "ut ooh" if expected_size != all.size
      all
    end

    # filter: "page" => #, "per_page" => #
    def hosts(filter = {}, local_filter = {})
      paged_response(ForemanApi::Resources::Host, "index", filter, local_filter)
    end

    def denormalized_hostgroups(filter = {}, local_filter = {})
      #denormalize_hostgroups(hostgroups(filter, local_filter))
      hg = raw_hostgroups.index(filter).first["results"]
      hg = denormalize_hostgroups(hg)
      PagedResponse.prune(hg, local_filter)
    end

    def hostgroups(filter = {}, local_filter = {})
      paged_response(ForemanApi::Resources::Hostgroup, "index", filter, local_filter)
    end

    def operating_systems(filter = {}, local_filter = {})
      paged_response(ForemanApi::Resources::OperatingSystem, "index", filter, local_filter)
    end

    def media(filter = {}, local_filter = {})
      paged_response(ForemanApi::Resources::Medium, "index", filter, local_filter)
    end

    def ptable(filter = {}, local_filter = {})
      paged_response(ForemanApi::Resources::Ptable, "index", filter, local_filter)
    end

    def config_templates(filter = {}, local_filter = {})
      paged_response(ForemanApi::Resources::ConfigTemplate, "index", filter, local_filter)
    end

    def subnets(filter = {}, local_filter = {})
      paged_response(ForemanApi::Resources::Subnet, "index", filter, local_filter)
    end

    # take all the data from ancestors, and put that into the groups
    # assumes all groups are in groups array
    def denormalize_hostgroups(groups)
      groups.collect do |g|
        (g["ancestry"] || "").split("/").each_with_object({}) do |gid, h|
          h.merge!(groups.detect {|gd| gd["id"].to_s == gid }.select { |_n, v| !v.nil? })
        end.merge!(g.select { |_n, v| !v.nil? })
      end
    end

    # filter:
    #   accepts "page" => 2, "per_page" => , "search" => "field=value", "value"
    # results(ForemanApi::Resources::Host, {"page" => 2, "search" => "family=RedHat"})
    def paged_response(resource, method, filter = {}, local_filter = {})
      PagedResponse.new(raw(resource).send(method, filter).first, local_filter)
      #PagedResponse.new(raw(resource), filter, "index", local_filter)
    end

    def update_record(resource, values)
      PagedResponse.new(raw(resource).update(values).first)
    end

    def raw_home
      raw(ForemanApi::Resources::Home)
    end

    def raw_hosts
      raw(ForemanApi::Resources::Host)
    end

    def raw_hostgroups
      raw(ForemanApi::Resources::Hostgroup)
    end

    def raw_operating_systems
      raw(ForemanApi::Resources::OperatingSystem)
    end

    def raw(resource)
      resource.new(connection_attrs)
    end
  end
end
