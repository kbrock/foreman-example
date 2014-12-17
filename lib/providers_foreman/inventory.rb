module ProvidersForeman
  class Inventory
    # refreshers/foreman_refresher.rb (extend BaseRefresher)
    def refresh(ems, refresher_options = {})
      ems_inv_to_hashes(ems, refresher_options)
      save_ems_inventory(ems, hashes)
    end

    # call up the provider and generate  hash
    #
    # - ems
    #   - hosts (or hardware)
    #   - hostgroups
    #   - operating_systems (NOTE: keyed operatingsystem_id)
    #   - media
    #   - ptables
    #   - subnets
    def ems_inv_to_hashes(ems, refresher_options = {})

      c = ems.raw_connect
      operating_systems = c.operating_systems #used twice
      {
        :ems => {
          :hosts => c.all(:hosts).map do |h|
            {
              "id"                  => h["id"],
              "name"                => h["name"],
              "ip"                  => h["ip"],
              "mac"                 => h["mac"],
              "hostgroup_id"        => h["hostgroup_id"],
              "uuid"                => h["uuid"],
              #"subnet_id"           => h["subnet_id"],
              "build"               => h["build"],
              "enabled"             => h["enabled"],
#              "managed"             => h["managed"],
              "operatingsystem_id"  => h["operatingsystem_id"],
              "domain_id"           => h["domain_id"],
              "ptable_id"           => h["ptable_id"],
              "medium_id"           => h["medium_id"],
              #"architecture_id"     => h["architecture_id"],
              #"realm_id"            => h["realm_id"],
              # "sp_subnet_id",
              # "ptable_name",
              # "environment_id", "environment_name",
              # "last_report",
              # "realm_id", "realm_name",
              # "sp_mac", "sp_ip", "sp_name",
              # "domain_id", "domain_name",
              # "architecture_id", "architecture_name",
              # "subnet_id", "subnet_name",
              # "sp_subnet_id",
              # "comment", "disk", "installed_at",
              # "model_id", "model_name",
              # "hostgroup_name",
              # "owner_id", "owner_type",
              # "puppet_ca_proxy_id", "use_image",
              # "image_file", "uuid",
              # "compute_resource_id", "compute_resource_name",
              # "compute_profile_id", "compute_profile_name",
              # "capabilities", "provision_method",
              # "puppet_proxy_id", "certname",
              # "image_id", "image_name",
              # "created_at", "updated_at",
              # "last_compile", "last_freshcheck", "serial",
              # "source_file_id", "puppet_status"
            }
          end,
          :hostgroups => c.denormalized_hostgroups.map do |hg|
            {
              "id"                   => hg["id"],
              "name"                 => hg["name"],
              "title"                => hg["title"],
              "subnet_id"            => hg["subnet_id"],
              # "subnet_name"          => hg["subnet_name"],
              "operatingsystem_id"  => hg["operatingsystem_id"],
              # "operatingsystem_name" => hg["operatingsystem_name"],
              # "domain_id"            => hg["domain_id"],
              # "domain_name"          => hg["domain_name"],
              # "ancestry"             => hg["ancestry"],
              "ptable_id"            => hg["ptable_id"],
              # "ptable_name"          => hg["ptable_name"],
              "medium_id"            => hg["medium_id"],
              # "medium_name"          => hg["medium_name"],
              "architecture_id"      => hg["architecture_id"],
              # "architecture_name"    => hg["architecture_name"],
              "realm_id"             => hg["realm_id"],
              # "realm_name"           => hg["realm_name"],

              # "environment_id"       => hg["environment_id"],
              # "environment_name"     => hg["environment_name"],
              # "compute_profile_id"   => hg["compute_profile_id"],
              # "compute_profile_name" => hg["compute_profile_name"],
              # "puppet_proxy_id"      => hg["puppet_proxy_id"],
              # "puppet_ca_proxy_id"   => hg["puppet_ca_proxy_id"],
            }
          end,
          :operating_systems => operating_systems.map do |os|
            {
              "id"          => os["id"],
              "family"      => os["family"],
              "description" => os["description"],
              "fullname"    => os["fullname"],
              # fullname = "#{name} #{major}.#{minor}"
              # "release_name"
            }
          end,
          :operating_system_templates => operating_systems.each_with_object([]) do |os, osta|
            oss = c.operating_system(os["id"])
            oss.first["media"].each do |ma|
              osta << {
                "script_type"               => "media",
                "operatingsystem_id"        => os["id"],
                "configuration_template_id" => ma["id"]
              }
            end
            oss.first["ptables"].each do |pta|
              osta << {
                "script_type"               => "ptable",
                "operatingsystem_id"        => os["id"],
                "configuration_template_id" => pta["id"]
              }
            end
          end,
          :media => c.media.map do |m|
            {
              "id"        => m["id"],
              "name"      => m["name"],
              "path"      => m["path"],
              "os_family" => m["os_family"],
            }
          end,
          :ptables => c.ptable.map do |pt|
            {
              "id"        => pt["id"],
              "name"      => pt["name"],
              "os_family" => pt["os_family"],
            }
          end,
        }
      }
    end

    def save_ems_inventory(ems, hashes, target = nil)
      target ||= ems

      # start with lower level tables, so others can be linked
      hashes[:ems][:operating_systems].each do |osh|
        os = OperatingSystemFlavor.find_by_provider_ref(osh["id"]) ||
             OperatingSystemFlavor.new(:provider_id => ems.id, :provider_ref => osh["id"])
        os.family      = osh["family"]
        os.description = osh["description"]
        os.fullname    = osh["fullname"]
        os.save
      end

      hashes[:ems][:operating_system_templates].each do |osth|
        os = OperatingSystemFlavor.find_by_provider_ref(osth["operatingsystem_id"])
        cs = CustomizationScript.find_by_provider_ref_and_script_type(osth["configuration_template_id"], osth["script_type"])
        oscs = OperatingSystemCustomizationScript.find_by_operating_system_flavor_id_and_customization_script_id(os.id, cs.id) ||
               OperatingSystemCustomizationScript.new(:operating_system_flavor_id => os.id, :customization_script_id => cs.id)
        oscs.save
      end

      hashes[:ems][:ptables].each do |pth|
        pt = CustomizationScript.find_by_provider_ref_and_script_type(pth["id"], "ptable") ||
             CustomizationScript.new(:provider_id => ems.id, :provider_ref => pth["id"], :script_type => "ptable")
        pt.name = pth["name"]
        #pt.os_family
        pt.save
        # TODO: create many osf -> cs based upon family
      end

      hashes[:ems][:media].each do |mh|
        pt = CustomizationScript.find_by_provider_ref_and_script_type(mh["id"], "medium") ||
             CustomizationScript.new(:provider_id => ems.id, :provider_ref => mh["id"], :script_type => "medium")
        pt.name = mh["name"]
        #pt.os_family
        pt.save
        # TODO: create many mh -> cs based upon family
      end

      hashes[:ems][:hostgroups].each do |cph|
        cp = ConfigurationProfile.find_by_provider_ref(cph["id"]) ||
             ConfigurationProfile.new(:provider_id => ems.id, :provider_ref => cph["id"])
        cp.name                        = cph["title"] # hierarchical
        #cp.foreman_subnet_id           = cph["subnet_id"]
        cp.operating_system_flavor     = OperatingSystemFlavor.find_by_provider_ref(cph["operatingsystem_id"])
        #cp.foreman_domain_id           = cph["domain_id"]
        cp.ptable                      = CustomizationScript.find_by_provider_ref_and_script_type(cph["ptable_id"], "ptable")
        cp.medium                      = CustomizationScript.find_by_provider_ref_and_script_type(cph["medium_id"], "medium")
        #cp.foreman_architecture_id     = cph["architecture_id"]
        #cp.foreman_realm_id            = cph["realm_id"]
        cp.save
      end

      hashes[:ems][:hosts].each do |msh|
        ms = ConfiguredSystem.find_by_provider_ref(msh["id"]) ||
             ConfiguredSystem.new(:provider_id => ems.id, :provider_ref => msh["id"])
        ms.hostname                    = msh["name"]
        ms.uuid                        = msh["uuid"]
        ms.ip                          = msh["ip"]
        #ms.mac                         = msh["mac"]
        ms.configuration_profile       = ConfigurationProfile.find_by_provider_ref(msh["hostgroup_id"])
        ms.operating_system_flavor     = OperatingSystemFlavor.find_by_provider_ref(msh["operatingsystem_id"])
        ms.ptable                      = CustomizationScript.find_by_provider_ref_and_script_type(msh["ptable_id"], "ptable")
        ms.medium                      = CustomizationScript.find_by_provider_ref_and_script_type(msh["medium_id"], "medium")
        ms.build                       = msh["build"]
        ms.enabled                     = msh["enabled"]
#        ms.managed                     = msh["managed"]
        # "architecture_id"     => h["architecture_id"],
        ms.save
      end
    end
  end
end
