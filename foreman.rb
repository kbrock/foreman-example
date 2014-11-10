require 'foreman_api'
require 'yaml'

module ProvidersForeman
  class Connection
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

    def find_host_by_foreman_id(id)
    end

    def all_hosts
      hosts.index.first
    end

    def home
      ForemanApi::Resources::Home.new(connection_attrs)
    end

    def hosts
      ForemanApi::Resources::Host.new(connection_attrs)
    end

    private

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

# EngOps registers baremetal via ISO (when racking new hardware)
#   burn iso
#   boot machine with iso
#   via cd, foreman discovers machine and creates foreman host record
#   ? did the user assign various parameters ?

# EngOps emails DevOps IP address and credentials for iDRAC
# DevOps goes into foreman and registers baremetal
#   add BMC interface, primary interface mac address
#     populating unneeded required fields with bogus values

# EngOps emails DevOps IP address and credentials for iDRAC
# DevOps registers baremetal via ManageIq (in managed_hosts tab)
#   user provides us with IP address and credentials for iDRAC
#   via rest protocol create foreman host record, bmc interface
#     populating unneeded required fields with bogus values (?)

if __FILE__ == $0
  params = YAML.load_file('foreman.yml')
  # Login to Foreman
  c = ProvidersForeman::Connection.new(
    params["creds"]
  )
  # get list of foreman hosts
  hosts = c.all_hosts
  puts hosts["results"].map { |n| " #{n["name"]} #{n["mac"]}" }
  # user chooses host to provision
  mac=params["nodes"]["mac"] #external_id => foreman_id
  # get host record parameter choices (host groups, os, media, partition table) ? can we force these for host group?
  # host groups -> environment, puppet ca, puppet master, network/domain, params["ntp"], os architecture,
  # os (os family) (can default from host groups)
  # media (can default from host groups)
  # partition table (can default from host groups)
  # root password (can default from host groups)
  # build mode (set to true)

  # get foreman host / display it for verification
  # save foreman host with new values
  # restart foreman host to provision

  # poll (fetch foreman host by external id and wait until "build" => false
  # ? way to leverage callbacks? either generic: please refresh all foreman hosts or please refresh specific foreman host
  #pp hosts["results"].first.delete_if { |n, v| v.nil? } ; nil# name => value
end

# TANGENTS (that we need to do sooner or later)

# inventory
# get list of all foreman hosts
# determine if we already have a vm for that host record / link them

# register VM via ManageIq (at provisioning time)
#   we create VM in VMWare
#   via rest protocol create foreman host record
#     set primary interface mac address
