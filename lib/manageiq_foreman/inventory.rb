module ManageiqForeman
  class Inventory
    # call up the provider and generate  hash
    def ems_inv_to_hashes(ems, refresher_options = {})

      c = ems.raw_connect
      operating_systems = c.operating_systems #used twice

      {
        :ems => {
          :hosts => ems_hosts(c.all(:hosts)),
          :hostgroups => ems_hostgroups(c.denormalized_hostgroups),
          :operating_systems => ems_operating_systems(operating_systems),
          :operating_system_templates => ems_operating_system_templates(operating_systems),
          :media => ems_media(c.media),
          :ptables => ems_ptables(c.ptable),
        }
      }
    end

    def ems_hosts(hosts)
      hosts.map do |h|
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
      end
    end

    def ems_hostgroups(hostgroups)
      hostgroups.map do |hg|
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
      end
    end

    def ems_operating_systems(operating_systems)
      operating_systems.map do |os|
        {
          "id"          => os["id"],
          "family"      => os["family"],
          "description" => os["description"],
          "fullname"    => os["fullname"],
          # fullname = "#{name} #{major}.#{minor}"
          # "release_name"
        }
      end
    end

    def ems_operating_system_templates(operating_systems)
      operating_systems.each_with_object([]) do |os, osta|
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
      end
    end

    def ems_media(media)
      media.map do |m|
        {
          "id"        => m["id"],
          "name"      => m["name"],
          "path"      => m["path"],
          "os_family" => m["os_family"],
        }
      end
    end

    def ems_ptables(ptables)
      ptables.map do |pt|
        {
          "id"        => pt["id"],
          "name"      => pt["name"],
          "os_family" => pt["os_family"],
        }
      end
    end
  end
end
