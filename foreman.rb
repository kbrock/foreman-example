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

    def c
      @c ||= ProvidersForeman::Connection.new(args)
    end

    def print_host(host)
      puts "##{host["id"]}: #{host["name"]} #{host["environment_id"]}:#{host["environment_name"]} (uuid: #{host["uuid"]})"
      puts "=> enabled: #{host["enabled"]} build: #{host["build"]} managed: #{host["managed"]}"
      puts "hostgroup #{host["hostgroup_id"]}:#{host["hostgroup_name"]}" if host["hostgroup_id"]
      puts "architecture #{host["architecture_id"]}:#{host["architecture_name"]}" if host["architecture_id"]
      puts "operatingsystem #{host["operatingsystem_id"]}:#{host["operatingsystem_name"]}" if host["operatingsystem_id"]
      puts "ptable #{host["ptable_id"]}:#{host["ptable_name"]}" if host["ptable_id"]
      puts "medium #{host["medium_id"]}:#{host["medium_name"]}" if host["medium_id"]
    end

    def print_hostgroup(hg)
      # note, these params will only be populated if overriding. need to reference "ancestory" (list of ids) to get values
      puts " #{hg["title"]} (#{hg["environment_name"]}) ##{hg["id"]} proxy:[#{hg["puppet_proxy_id"]} ca: #{hg["puppet_ca_proxy_id"]}]"
      puts "   :: subnet: #{hg["subnet_name"]} (#{hg["subnet_id"]})" if hg["subnet_id"]
      puts "   :: operatingsystem: #{hg["operatingsystem_name"]} (#{hg["operatingsystem_id"]})" if hg["operatingsystem_id"]
      puts "   :: domain: #{hg["domain_name"]} (#{hg["domain_id"]})" if hg["domain_id"]
      puts "   :: environment: #{hg["environment_name"]} (#{hg["environment_id"]})" if hg["environment_id"]
      puts "   :: compute_profile: #{hg["compute_profile_name"]} (#{hg["compute_profile_id"]})" if hg["compute_profile_id"]
      puts "   :: ptable: #{hg["ptable_name"]} (#{hg["ptable_id"]})" if hg["ptable_id"]
      puts "   :: medium: #{hg["medium_name"]} (#{hg["medium_id"]})" if hg["medium_id"]
      puts "   :: architecture: #{hg["architecture_name"]} (#{hg["architecture_id"]})" if hg["architecture_id"]
      puts "   :: realm: #{hg["realm_name"]} (#{hg["realm_id"]})" if hg["realm_id"]
    end

    def run
      # get list of foreman hosts
      #puts hosts.collect { |h| " #{h["name"]} #{h["mac"]} ##{h["id"]}" }
      host = c.hosts.detect { |h| h["name"].include?(target_host_name)}
      host ||= c.hosts("page" => 2).detect { |h| h["name"].include?(target_host_name)}

      puts
      puts "Host"
      puts
      print_host(host)
      puts

      # NOTE: host groups will currently store:
      #   environment, puppet ca, puppet master, network/domain, params["ntp"], os architecture
      # it will optionally store: os (os family), media, partition table

      hostgroups           = c.denormalized_hostgroups
      default_hostgroup_id = host["hostgroup_id"]
      default_hostgroup    = hostgroups.detect { |hg| hg["id"] == default_hostgroup_id }

      operating_systems = c.operating_systems
      default_os_id     = host["operatingsystem_id"]
      default_os_id   ||= default_hostgroup["operatingsystem_id"] if default_hostgroup
      default_os        = operating_systems.detect { |o| o["id"] == default_os_id }

      hostgroup = ask_with_menu("Host Group",
        hostgroups.each_with_object({}) do |hg, h|
          hg_title = "#{hg["title"]}"
          hg_title << "(#{hg["environment_name"]})" if hg["environment_name"]
          hg_title << " [OS: #{hg["operating_system_name"]}]" if hg["operating_system_id"]
          h[hg_title] = hg
        end, default_hostgroup)

      # [might be set by host group]
      os  = ask_with_menu("OS",
                          operating_systems.each_with_object({}) do |o, h|
                            h["#{o["fullname"]} (#{o["family"]})"] = o
                          end,
                          default_os)
      puts
      puts "HostGroup"
      puts
      print_hostgroup(hostgroup)
      # print OS?
      puts

      #binding.pry
      # TODO: filter based upon os
      medias = c.media #("search" => "family=#{os["family"]}")
      ptables = c.ptable #({"search" => "family=#{os["family"]}"})

      # TODO: client side filtering based upon OS
      default_medium_id = host["medium_id"] || hostgroup["medium_id"]
      default_medium = medias.detect { |m| m["id"] == default_medium_id }
      medium  = ask_with_menu("Media",
                              medias.each_with_object({}) do |m, h|
                                h["#{m["name"]}"] = m
                              end,
                              default_medium)

      # TODO: client side filtering based upon OS
      default_ptable_id = host["ptable_id"] || hostgroup["ptable_id"]
      default_ptable = ptables.detect { |pt| pt["id"] == default_ptable_id }
      partition = ask_with_menu("Partition",
        ptables.each_with_object({}) do |pt, h|
          h["#{pt["name"]}"] = pt
        end, default_ptable)

      root_password = ask("Root Password: ") { |q| q.echo = '*' }

      default_hostname = host["name"]
      hostname = ask("Hostname: ") { |q| q.default = default_hostname }

      default_ip_address = host["ip"]
      ip_address = ask("IP Address: ") { |q| q.default = default_ip_address }

      # TODO
      # choose subnet [hostgroup?]
      # subnet

      # new_host is the new values (remove the ones that are equal to the existing host record)
      new_host = {
        "build"              => true,
        "hostgroup_id"       => hostgroup["id"],
        "ip"                 => ip_address,
        "medium_id"          => medium["id"],
        "name"               => hostname,
        "operatingsystem_id" => os["id"], #?
        "ptable_id"          => partition["id"],
        "root_pass"          => root_password,
      }.delete_if { |n, v| host[n] == v }
      new_host["id"] = host["id"]


      c.raw_hosts.update(new_host)

      puts
      puts "Host Values"
      puts
      print_host(host)
      puts

      c.raw_hosts.power("id" => host["id"], "power_action" => "off")
      print "Waiting for Power Off."
      loop { break if c.raw_hosts.power("id" => 28, "power_action" => "status").first["power"] == "off"; print "."; sleep 1 }
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
