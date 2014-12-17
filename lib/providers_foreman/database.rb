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

    def raw_connect
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
    field :provider_id
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
    field :provider_id
    field :provider_ref
    field :name
    #field :subnet_id
    field :operating_system_flavor_id
    #field :environment_id
    field :ptable_id
    field :medium_id
    field :customization_id
    # field :architecture_id
    # field :realm_id

    belongs_to :operating_system_flavor
    belongs_to :ptable, :class_name => 'CustomizationScript'
    belongs_to :medium, :class_name => 'CustomizationScript'
    belongs_to :customization, :class_name => 'CustomizationScript'

    def operating_system_flavor?
      operating_system_flavor_id.present?
    end
  end

  class OperatingSystemFlavor < ActiveHash::Base
    include ActiveHash::Associations
    field :provider_id
    field :provider_ref
    field :family
    field :description
    field :fullname
    belongs_to :provision_template, :class_name => 'CustomizationScript'
    belongs_to :pxe_template, :class_name => 'CustomizationScript'
    has_many :operating_system_customization_scripts
    has_many :customization_scripts, :through => :operating_system_customization_scripts
    has_many :ptables, :through => :operating_system_customization_scripts, :where => {:script_type => "ptables"}
    has_many :media, :through => :operating_system_customization_scripts, :where => {:script_type => "medium"}
  end

  class OperatingSystemCustomizationScript < ActiveHash::Base
    include ActiveHash::Associations
    field :operating_system_flavor_id
    field :customization_script_id

    belongs_to :operating_system_flavor_id
    belongs_to :customization_script_id
  end

  class CustomizationScript < ActiveHash::Base
    include ActiveHash::Associations
    field :provider_id
    field :provider_ref
    field :script_type #"ptable, "medium", "provision_template"
    field :name

    # named scope
    def self.media
      all.select {|cs| cs.script_type == "medium" }
    end

    def self.ptables
      all.select {|cs| cs.script_type == "ptable" }
    end
  end

#end
