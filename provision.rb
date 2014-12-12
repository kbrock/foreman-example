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
      puts "   :: operatingsystem: #{h.operating_system_flavor.try(:name)}"
      puts "   :: ptable: #{h.ptable.try(:name)}"
      puts "   :: medium: #{h.medium.try(:name)}"
      #puts "   :: subnet: #{h.subnet.try(:name)}"
    end

    def print_host(host)
      puts "##{host.provider_ref}: #{host.hostname} (uuid: #{host.uuid})"
      puts "   :: enabled: #{host.enabled} build: #{host.build}"
      print_host_info(host)
      puts "hostgroup #{host.configuration_profile.try(:name) || "none"}"
    end

    def print_configuration_profile(hg)
      # note, these params will only be populated if overriding. need to reference "ancestory" (list of ids) to get values
      puts "##{hg.provider_ref}: #{hg.title}, #{hg.name}" # (#{hg["environment_name"]})
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

      default_configuration_profile = host.configuration_profile
      default_os = host.operating_system_flavor || default_configuration_profile.try(:operating_system_flavor)

      configuration_profile = ask_with_menu("Host Group",
        ConfigurationProfile.all.each_with_object({}) do |hg, h|
          hg_title = "#{hg.title}"
#          hg_title << "(#{hg.environment_name})" if hg.environment_name?
          hg_title << " [OS: #{hg.operating_system_flavor.name}]" if hg.operating_system_flavor?
          h[hg_title] = hg
        end, default_configuration_profile)

      # [might be set by host group]
      os  = ask_with_menu("OS",
                          OperatingSystemFlavor.all.each_with_object({}) do |o, h|
                            h["#{o.fullname} (#{o.family})"] = o
                          end,
                          default_os)

      puts
      puts "ConfigurationProfile"
      puts
      print_configuration_profile(configuration_profile)
      # print OS?
      puts

      # TODO: client side filtering based upon OS
      default_medium = host.medium || configuration_profile.medium
      medium  = ask_with_menu("Media",
                              CustomizationScript.media.each_with_object({}) do |m, h|
                                h[m.name] = m
                              end,
                              default_medium)

      # TODO: client side filtering based upon OS
      default_ptable = host.ptable || configuration_profile.ptable
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
      # TODO: modify the fields in host, and send them
      new_host = {
        "build"              => true,
        "hostgroup_id"       => configuration_profile.provider_ref,
        "ip"                 => ip_address,
        "medium_id"          => medium.provider_ref,
        "name"               => hostname,
        "operatingsystem_id" => os.provider_ref,
        "ptable_id"          => partition.provider_ref,
        "root_pass"          => root_password,
#        "subnet_id"          => subnet.provider_ref,
      }.delete_if { |n, v| host[n] == v }
      new_host["id"] = host.provider_ref


      c.raw_hosts.update(new_host)

      Provider.first.update_host(host, {"build" => true, } )

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
