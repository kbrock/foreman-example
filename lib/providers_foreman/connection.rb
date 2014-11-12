module ProvidersForeman
  class Connection
    # url for foreman host. just a hostname works fine
    # I am here  I
    attr_accessor :base_url
    attr_accessor :username
    attr_accessor :password

    # defaults to OpenSSL::SSL::VERIFY_PEER
    # for self signed certs, probably want to do:
    # OpenSSL::SSL::VERIFY_NONE (0 / false)
    attr_accessor :verify_ssl

    def initialize(opts = {})
      opts.each do |n, v|
        public_send("#{n}=", v)
      end
    end

    def verify_ssl=(val)
      @verify_ssl = if val == true
                      OpenSSL::SSL::VERIFY_PEER
                    elsif val == false
                      OpenSSL::SSL::VERIFY_NONE
                    else
                      val
                    end
    end

    def verify_ssl?
      @verify_ssl != OpenSSL::SSL::VERIFY_NONE
    end

    def api_version
      home.status.first["api_version"]
    end

    def hosts(opts = {})
      raw_hosts.index(opts).first["results"]
    end

    def denormalized_host_groups
      denormalize_host_groups(host_groups)
    end

    def host_groups
      raw_host_groups.index.first["results"]
    end

    def operating_systems(filter = {}, local_filter = {})
      paged_response(ForemanApi::Resources::OperatingSystem, filter, local_filter)
    end

    def media(filter = {}, local_filter = {})
      paged_response(ForemanApi::Resources::Medium, filter, local_filter)
    end

    def ptable(filter = {}, local_filter = {})
      paged_response(ForemanApi::Resources::Ptable, filter, local_filter)
    end

    # take all the data from ancestors, and put that into the groups
    def denormalize_host_groups(groups)
      groups.collect do |g|
        (g["ancestry"] || "").split("/").each_with_object({}) do |gid, h|
          h.merge!(groups.detect {|gd| gd["id"].to_s == gid }.select { |_n, v| !v.nil? })
        end.merge!(g.select { |_n, v| !v.nil? })
      end
    end

    # filter:
    #   accepts "page" => 2, "per_page" => , "search" => "field=value", "value"
    # results(ForemanApi::Resources::Host, {"page" => 2, "search" => "family=RedHat"})
    def paged_response(resource, filter = {}, local_filter = {})
      PagedResponse.new(raw(resource).index(filter).first, local_filter)
    end

    def update_record(resource, values)
      PagedResponse.new(raw(resource).update(values).first)
    end

    def raw_home
      ForemanApi::Resources::Home.new(connection_attrs)
    end

    def raw_hosts
      ForemanApi::Resources::Host.new(connection_attrs)
    end

    def raw_host_groups
      ForemanApi::Resources::Hostgroup.new(connection_attrs)
    end

    def raw_operating_systems
      raw(ForemanApi::Resources::OperatingSystem)
    end

    def raw(resource)
      resource.new(connection_attrs)
    end

    def connection_attrs
      {
        :base_url   => @base_url,
        :username   => @username,
        :password   => @password,
        :verify_ssl => @verify_ssl
      }
    end
  end
end
