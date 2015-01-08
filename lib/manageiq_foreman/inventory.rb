module ManageiqForeman
  class Inventory
    attr_accessor :connection
    def initialize(connection)
      @connection = connection
    end

    def connect
      # NOP
    end

    def disconnect
      # NOP
    end

    # generate inventory for the foreman provider
    def refresh
      {
        :hosts             => connection.all(:hosts),
        :hostgroups        => connection.denormalized_hostgroups,
        :operating_systems => connection.operating_system_details,
        :media             => connection.media,
        :ptables           => connection.ptables,
      }
    end

    # expecting: base_url, username, password, :verify_ssl
    def self.from_attributes(connection_attrs)
      new(Connection.new(connection_attrs))
    end
  end
end
