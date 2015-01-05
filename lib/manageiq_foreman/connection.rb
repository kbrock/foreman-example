module ManageiqForeman
  class Connection
    attr_accessor :connection_attrs

    def initialize(connection_attrs)
      @connection_attrs = connection_attrs
    end

    def api_version
      raw_home.status.first["api_version"]
    end

    def all(method, filter = {})
      expected_size = nil
      page = 0
      all = []

      while expected_size.nil? || all.size < expected_size
        small = public_send(method, filter.merge(:page => (page +=1), :per_page => 50))
        expected_size ||= small.total
        break if small.empty?
        all += small.to_a
      end
      #puts "ut ooh" if expected_size != all.size
      return PagedResponse.new(all)
    end

    # filter: "page" => #, "per_page" => #
    def hosts(filter = {})
      paged_response(raw_hosts.index(filter).first)
    end

    def denormalized_hostgroups(filter = {})
      paged_response(denormalize_hostgroups(all(:hostgroups, filter)))
    end

    def hostgroups(filter = {})
      paged_response(raw_hostgroups.index(filter).first)
    end

    def operating_system(id)
      paged_response(raw_operating_systems.show("id" => id).first)
    end

    def operating_systems(filter = {})
      paged_response(raw_operating_systems.index(filter).first)
    end

    def operating_system_details(filter = {})
      operating_systems(filter).map do |os|
        operating_system(os["id"]).first
      end
    end

    def media(filter = {})
      paged_response(raw_media.index(filter).first)
    end

    def ptables(filter = {})
      paged_response(raw_ptables.index(filter).first)
    end

    def config_templates(filter = {})
      paged_response(raw_config_templates.index(filter).first)
    end

    def subnets(filter = {})
      paged_response(raw_subnets.index(filter).first)
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
    #   accepts "page" => 2, "per_page" => 50, "search" => "field=value", "value"
    def paged_response(resource)
      PagedResponse.new(resource)
    end

    def raw_config_templates
      raw(ForemanApi::Resources::ConfigTemplate)
    end

    def raw_home
      raw(ForemanApi::Resources::Home)
    end

    def raw_hostgroups
      raw(ForemanApi::Resources::Hostgroup)
    end

    def raw_hosts
      raw(ForemanApi::Resources::Host)
    end

    def raw_media
      raw(ForemanApi::Resources::Medium)
    end

    def raw_operating_systems
      raw(ForemanApi::Resources::OperatingSystem)
    end

    def raw_ptables
      raw(ForemanApi::Resources::Ptable)
    end

    def raw_subnets
      raw(ForemanApi::Resources::Subnet)
    end

    def raw(resource)
      resource.new(connection_attrs)
    end
  end
end
