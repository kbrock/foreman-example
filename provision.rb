#!/usr/bin/env ruby
require 'yaml'
require 'pry'

require_relative "lib/highline_helper"
require_relative "lib/providers_foreman"

module ProvidersForeman
  class Run
    include HighlineHelper

    attr_accessor :args, :target_host_name
    def initialize(opts = {}, target_host_name = nil)
      @args = opts
      @target_host_name = target_host_name
    end

    def provider
      @provider ||= Provider.new(@args)
    end

    def c
      @c ||= ProvidersForeman::Connection.new(args)
    end

    def print_host_info(h)
      # puts "##{h["id"]} proxy:[#{h["puppet_proxy_id"]} ca: #{h["puppet_ca_proxy_id"]}]"
      #puts "   :: subnet: #{h.subnet.try(:name)}"
      puts "   :: operatingsystem: #{h.operating_system_flavor.try(:name)}"
      #puts "   :: domain: #{h["domain_name"]} (#{h["domain_id"]})" if h["domain_id"]
      #puts "   :: environment: #{h["environment_name"]} (#{h["environment_id"]})" if h["environment_id"]
      #puts "   :: compute_profile: #{h["compute_profile_name"]} (#{h["compute_profile_id"]})" if h["compute_profile_id"]
      puts "   :: ptable: #{h.ptable.try(:name)}"
      puts "   :: medium: #{h.medium.try(:name)}"
      #puts "   :: architecture: #{h["architecture_name"]} (#{h["architecture_id"]})" if h["architecture_id"]
      #puts "   :: realm: #{h["realm_name"]} (#{h["realm_id"]})" if h["realm_id"]
    end

    def print_host(host)
      puts "##{host.foreman_id}: #{host.hostname} (uuid: #{host.uuid})" # #{host.environment_id}:#{host.environment_name}"
      puts "   :: enabled: #{host.enabled} build: #{host.build} managed: #{host.managed}"
      print_host_info(host)
      puts "hostgroup #{host.configuration_profile.try(:name) || "none"}"
    end

    def print_hostgroup(hg)
      # note, these params will only be populated if overriding. need to reference "ancestory" (list of ids) to get values
      puts "##{hg.foreman_id}: #{hg.title}, #{hg.name}" # (#{hg["environment_name"]})
      print_host_info(hg)
    end

    def refresh
      refresher = ProvidersForeman::Inventory.new

      inv = refresher.ems_inv_to_hashes(provider)
      refresher.save_ems_inventory(provider, inv)
    end

    def run
      refresh

      default_host = ConfiguredSystem.find_by_subname(target_host_name)

      host = ask_with_menu("Host",
        ConfiguredSystem.all.each_with_object({}) do |ms, h|
          h["#{ms.name} (#{ms.ip})"] = ms
        end, default_host)

      puts
      puts "Host"
      puts
      print_host(host)
      puts

      default_hostgroup = host.configuration_profile
      default_os = host.operating_system_flavor || default_hostgroup.try(:operating_system_flavor)

      hostgroup = ask_with_menu("Host Group",
        ConfigurationProfile.all.each_with_object({}) do |hg, h|
          hg_title = "#{hg.title}"
#          hg_title << "(#{hg.environment_name})" if hg.environment_name?
          hg_title << " [OS: #{hg.operating_system_flavor.name}]" if hg.operating_system_flavor?
          h[hg_title] = hg
        end, default_hostgroup)

      # [might be set by host group]
      os  = ask_with_menu("OS",
                          OperatingSystemFlavor.all.each_with_object({}) do |o, h|
                            h["#{o.fullname} (#{o.family})"] = o
                          end,
                          default_os)

      puts
      puts "HostGroup"
      puts
      print_hostgroup(hostgroup)
      # print OS?
      puts

      # TODO: client side filtering based upon OS
      default_medium = host.medium || hostgroup.medium
      medium  = ask_with_menu("Media",
                              CustomizationScript.media.each_with_object({}) do |m, h|
                                h[m.name] = m
                              end,
                              default_medium)

      # TODO: client side filtering based upon OS
      default_ptable = host.ptable || hostgroup.ptable
      partition = ask_with_menu("Partition",
        CustomizationScript.ptables.each_with_object({}) do |pt, h|
          h[pt.name] = pt
        end, default_ptable)

      # default_subnet = host["subnet_id"]
      # subnet = ask_with_menu("Subnet",
      #                         c.subnets.each_with_object({}) do |s, h|
      #                           h["#{s["name"]}"] = s
      #                         end,
      #                         default_subnet)

      root_password = ask_for_password("Root Password", "smartvm")
      hostname = ask_for_string("hostname", host.hostname)
      ip_address = ask_for_string("IP Address: ", host.ip)

      # new_host is the new values (remove the ones that are equal to the existing host record)
      new_host = {
        "build"              => true,
        "hostgroup_id"       => hostgroup.foreman_id,
        "ip"                 => ip_address,
        "medium_id"          => medium.foreman_id,
        "name"               => hostname,
        "operatingsystem_id" => os.foreman_id,
        "ptable_id"          => partition.foreman_id,
        "root_pass"          => root_password,
#        "subnet_id"          => subnet.foreman_id,
      }.delete_if { |n, v| host[n] == v }
      new_host["id"] = host.foreman_id


      c.raw_hosts.update(new_host)

      puts
      puts "Host Values"
      puts
      print_host(host)
      puts

      return

      # TODO: where does this go?
      c.raw_hosts.power("id" => host["id"], "power_action" => "off")
      print "Waiting for Power Off."
      loop { break if c.raw_hosts.power("id" => host["id"], "power_action" => "status").first["power"] == "off"; print "."; sleep 1 }
      puts
      puts "Setting boot device to PXE and booting..."
      c.raw_hosts.boot("id" => host["id"], "device" => "pxe")
      c.raw_hosts.power("id" => host["id"], "power_action" => "on")

      print "Waiting for PXE provision to complete"
      loop { break unless c.raw_hosts.show("id" => host["id"]).first["build"]; print "."; sleep 10 }
      puts "Complete!"
      # ? way to leverage callbacks? either generic: please refresh all foreman hosts or please refresh specific foreman host
    end
  end
end

if __FILE__ == $0
  params = YAML.load_file('foreman.yml')
  # Login to Foreman
  c = ProvidersForeman::Run.new(params["creds"], ARGV[0] || params["nodes"]["name"])
  c.run
end
