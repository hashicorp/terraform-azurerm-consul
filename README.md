# Consul AWS Module

This repo contains a Module for deploying a [Consul](https://www.consul.io/) cluster on 
[Azure](https://azure.microsoft.com/) using [Terraform](https://www.terraform.io/). Consul is a distributed, highly-available 
tool that you can use for service discovery and key/value storage. A Consul cluster typically includes a small number
of server nodes, which are responsible for being part of the [consensus 
quorum](https://www.consul.io/docs/internals/consensus.html), and a larger number of client nodes, which you typically 
run alongside your apps:

![Consul architecture](/_docs/architecture.png)

## How to use this Module

Each Module has the following folder structure:

* [modules](https://github.com/gruntwork-io/terraform-consul-azure/modules): This folder contains the reusable code for this Module, broken down into one or more modules.
* [examples](https://github.com/gruntwork-io/terraform-consul-azure/examples): This folder contains examples of how to use the modules.
* [test](https://github.com/gruntwork-io/terraform-consul-azure/test): Automated tests for the modules and examples.

To deploy Consul servers using this Module:

1. Create a Consul Image using a Packer template that references the [install-consul module](https://github.com/gruntwork-io/terraform-consul-azure/modules/install-consul).
   Here is an [example Packer template](https://github.com/gruntwork-io/terraform-consul-azure/examples/consul-ami#quick-start).  
   
1. Deploy that Image in a Scale Set using the Terraform [consul-cluster module](https://github.com/gruntwork-io/terraform-consul-azure/modules/consul-cluster) 
   and execute the [run-consul script](https://github.com/gruntwork-io/terraform-consul-azure/modules/run-consul) with the `--server` flag during boot on each 
   Instance in the Scale Set to form the Consul cluster. Here in the root is [an example Terraform 
   configuration](MAIN.md#quick-start) to provision a Consul cluster.

To deploy Consul clients using this Module:
 
1. Use the [install-consul module](https://github.com/gruntwork-io/terraform-consul-azure/modules/install-consul) to install Consul alongside your application code.
1. Before booting your app, execute the [run-consul script](https://github.com/gruntwork-io/terraform-consul-azure/modules/run-consul) with `--client` flag.
1. Your app can now using the local Consul agent for service discovery and key/value storage. 
1. Optionally, you can use the [install-dnsmasq module](https://github.com/gruntwork-io/terraform-consul-azure/modules/install-dnsmasq) to configure Consul as the DNS for a
   specific domain (e.g. `.consul`) so that URLs such as `foo.service.consul` resolve automatically to the IP 
   address(es) for a service `foo` registered in Consul (all other domain names will be continue to resolve using the
   default resolver on the OS).
   
## What's a Module?

A Module is a canonical, reusable, best-practices definition for how to run a single piece of infrastructure, such 
as a database or server cluster. Each Module is created using [Terraform](https://www.terraform.io/), and
includes automated tests, examples, and documentation. It is maintained both by the open source community and 
companies that provide commercial support. 

Instead of figuring out the details of how to run a piece of infrastructure from scratch, you can reuse 
existing code that has been proven in production. And instead of maintaining all that infrastructure code yourself, 
you can leverage the work of the Module community to pick up infrastructure improvements through
a version number bump.
  
 
## Who maintains this Module?

This Module is maintained by [Gruntwork](http://www.gruntwork.io/). If you're looking for help or commercial 
support, send an email to [modules@gruntwork.io](mailto:modules@gruntwork.io?Subject=Consul%20Module). 
Gruntwork can help with:

* Setup, customization, and support for this Module.
* Modules for other types of infrastructure, such as VPCs, Docker clusters, databases, and continuous integration.
* Modules that meet compliance requirements, such as HIPAA.
* Consulting & Training on AWS, Terraform, and DevOps.


## Code included in this Module:

* [install-consul](https://github.com/gruntwork-io/terraform-consul-azure/modules/install-consul): This module installs Consul using a
  [Packer](https://www.packer.io/) template to create a Consul 
  [Azure Image](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/capture-image).

* [consul-cluster](https://github.com/gruntwork-io/terraform-consul-azure/modules/consul-cluster): The module includes Terraform code to deploy a Consul Image in a [Virtual 
Machine Scale Set](https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/). 
  
* [run-consul](https://github.com/gruntwork-io/terraform-consul-azure/modules/run-consul): This module includes the scripts to configure and run Consul. It is used
  by the above Packer module at build-time to set configurations, and by the Terraform module at runtime 
  with Custom Data to create the cluster.

* [install-dnsmasq module](https://github.com/gruntwork-io/terraform-consul-azure/modules/install-dnsmasq): Install [Dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html)
  and configure it to forward requests for a specific domain to Consul. This allows you to use Consul as a DNS server
  for URLs such as `foo.service.consul`.

* [consul-security-group-rules](https://github.com/gruntwork-io/terraform-consul-azure/modules/consul-security-group-rules): Defines the security group rules used by a 
  Consul cluster to control the traffic that is allowed to go in and out of the cluster.

## How do I contribute to this Module?

Contributions are very welcome! Check out the [Contribution Guidelines](https://github.com/gruntwork-io/terraform-consul-azure/CONTRIBUTING.md) for instructions.


## How is this Module versioned?

This Module follows the principles of [Semantic Versioning](http://semver.org/). You can find each new release, 
along with the changelog, in the [Releases Page](../../releases). 

During initial development, the major version will be 0 (e.g., `0.x.y`), which indicates the code does not yet have a 
stable API. Once we hit `1.0.0`, we will make every effort to maintain a backwards compatible API and use the MAJOR, 
MINOR, and PATCH versions on each release to indicate any incompatibilities. 


## License

This code is released under the Apache 2.0 License. Please see [LICENSE](https://github.com/gruntwork-io/terraform-consul-azure/LICENSE) and [NOTICE](https://github.com/gruntwork-io/terraform-consul-azure/NOTICE) for more 
details.

