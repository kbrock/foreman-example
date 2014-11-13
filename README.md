Quick collaboration work to nail down our use cases with the foreman

# Pre-workflows

  - EngOps registers baremetal via ISO (when racking new hardware)
    + burn iso
    + boot machine with iso
    + via cd, foreman discovers machine and creates foreman host record
  - discovery in foreman
  - discovery via manageiq (no)

  - assign ipmi (iDrac - dell's ipmi hardware)
  - assign primary interface: mac
  - assign os architecture

# Foreman setup (DevOps)

Hostgroup contains:

   - environment, puppet ca, puppet master, network/domain
   - optionally: os (os family), media, partition table

subnet contains:

  - all network information except for ipaddress


# Provision Bare metal (User)

  - Catalog
    + Host Group (ipxe, provision)
    + OS
    + Host Group/OS is replacing pxe
  - Customize:
    + root password
    + host name
    + ip address
    + subnet
    + medium
    + ptable
    + subnet is replacing gateway, dns, ...
    + medium/ptable is replacing template

# workflows for another day

## inventory

  - get list of all foreman hosts
  - determine if we already have a vm for that host record / link them

## register VM via ManageIq (at provisioning time)

  - we create VM in VMWare
    + via rest protocol create foreman host record
    + set primary interface mac address
