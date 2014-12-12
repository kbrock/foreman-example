require "active_hash"

#module ProvidersForeman
  class Provider < ActiveHash::Base
    field :base_url
    field :username
    field :password
    field :verify_ssl

    def verify_ssl=(val)
      val = if val == true
              OpenSSL::SSL::VERIFY_PEER
            elsif val == false
              OpenSSL::SSL::VERIFY_NONE
            else
              val
            end
      attributes[:verify_ssl] = val
    end

    def verify_ssl?
      attributes[:verify_ssl] != OpenSSL::SSL::VERIFY_NONE
    end

    def connection_attrs
      {
        :base_url   => base_url,
        :username   => username,
        :password   => password,
        :verify_ssl => verify_ssl
      }
    end

    def raw_connection
      ProvidersForeman::Connection.new(connection_attrs)
    end
  end

  class ComputerSystem < ActiveHash::Base
    include ActiveHash::Associations
    belongs_to :configured_system
  end

  class Hardware < ActiveHash::Base
    include ActiveHash::Associations
    belongs_to :computer_system
  end

  class OperatingSystem < ActiveHash::Base
    include ActiveHash::Associations
    belongs_to :computer_system
  end

  class ConfiguredSystem < ActiveHash::Base
    include ActiveHash::Associations
    field :provider_ref
    field :hostname
    field :uuid
    field :ip # -> computer_system/hardware/nics
    #field :mac # -> computer_system/hardware/nics
    field :configuration_profile_id
    field :operating_system_flavor_id
    field :enabled
    field :build
##    field :power_state # -> computer system
##    field :connection_state # -> computer system
    alias_method :name, :hostname

    belongs_to :configuration_profile
    belongs_to :operating_system_flavor
    belongs_to :ptable, :class_name => 'CustomizationScript'
    belongs_to :medium, :class_name => 'CustomizationScript'
    belongs_to :customization, :class_name => 'CustomizationScript'

    #has_a :computer_system
    def computer_system
      ComputerSystem.find_by_configured_system_id(id)
    end

    def self.find_by_subname(name)
      all.detect { |ms| ms.hostname.include?(name) }
    end
  end

  class ConfigurationProfile < ActiveHash::Base
    include ActiveHash::Associations
    field :provider_ref
    field :name
    field :title
    #field :subnet_id
    field :operating_system_flavor_id
    #field :foreman_environment_id
    field :ptable_id
    field :medium_id
    field :customization_id
    # field :foreman_architecture_id
    # field :foreman_realm_id

    belongs_to :operating_system_flavor
    belongs_to :ptable, :class_name => 'CustomizationScript'
    belongs_to :medium, :class_name => 'CustomizationScript'
    belongs_to :customization, :class_name => 'CustomizationScript'

    def operating_system_flavor?
      operating_system_flavor_id.present?
    end
  end

  class OperatingSystemFlavor < ActiveHash::Base
    field :provider_ref
    field :family
    field :description
    field :fullname
  end

  class CustomizationScript < ActiveHash::Base
    field :provider_ref
    field :type #"ptable, "medium", "provision_template"
    field :name

    def self.media
      all.select {|cs| cs.type == "medium" }
    end

    def self.ptables
      all.select {|cs| cs.type == "ptable" }
    end
  end

  class ForemanSubnet < ActiveHash::Base

  end
#end
