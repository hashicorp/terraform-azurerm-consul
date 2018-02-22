# Consul Cluster Example

This folder shows an example of Terraform code that uses the [consul-cluster](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/modules/consul-cluster) module to deploy 
a [Consul](https://www.consul.io/) cluster in [Azure](https://azure.microsoft.com/). The cluster consists of two Virtual
Machine Scale Sets (VMSSs): one with a small number of Consul server nodes, which are responsible for being part of the 
[consensus quorum](https://www.consul.io/docs/internals/consensus.html), and one with a larger number of client nodes, 
which would typically run alongside your apps:

![Consul architecture](https://raw.githubusercontent.com/hashicorp/terraform-azurerm-consul/master/_docs/architecture.png)

You will need to create an Azure Image that has Consul installed, which you can do using the 
[consul-image example](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/examples/consul-image)). Note that to keep this example simple, both the server VMSS and client 
VMSS are running the exact same image. In real-world usage, you'd probably have multiple client VMSSs, and each of those 
VMSSs would run a different image that has the Consul agent installed alongside your apps.

For more info on how the Consul cluster works, check out the [consul-cluster](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/modules/consul-cluster) documentation.


## Quick start

To deploy a Consul Cluster:

1. `git clone` this repo to your computer.
1. Build a Consul Image. See the [consul-image example](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/examples/consul-image) documentation for instructions. Make sure 
   to note the ID of the image.
1. Install [Terraform](https://www.terraform.io/).
1. Create a `terraform.tfvars` file and fill in any other variables that don't have a default, including putting your 
   IMAGE URL into the `image_uri` variable.
1. Run `terraform init`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.
1. Run the [consul-examples-helper.sh script](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/examples/consul-examples-helper/consul-examples-helper.sh) to 
   print out the IP addresses of the Consul servers and some example commands you can run to interact with the cluster:
   `../consul-examples-helper/consul-examples-helper.sh`.

