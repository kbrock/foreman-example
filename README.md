Quick collaboration work to nail down our use cases with the foreman


# Pre-workflows
## Workflow for discovery via ISO

EngOps registers baremetal via ISO (when racking new hardware)
- burn iso
- boot machine with iso
- via cd, foreman discovers machine and creates foreman host record
- ? did the user assign various parameters ?

## Workflow for discovery via foreman

- EngOps emails DevOps IP address and credentials for iDRAC
- DevOps goes into foreman and registers baremetal
    - add BMC interface, primary interface mac address
    - populating unneeded required fields with bogus values

# NO: Discovery in ManageIQ
- EngOps emails DevOps IP address and credentials for iDRAC
- DevOps registers baremetal via ManageIq (in managed_hosts tab)
    - user provides us with IP address and credentials for iDRAC
    - via rest protocol create foreman host record, bmc interface
    - populating unneeded required fields with bogus values (?)

# workflows for another day

## inventory

- get list of all foreman hosts
- determine if we already have a vm for that host record / link them

## register VM via ManageIq (at provisioning time)

- we create VM in VMWare
    - via rest protocol create foreman host record
    - set primary interface mac address
