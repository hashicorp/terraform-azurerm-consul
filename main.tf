# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A CONSUL CLUSTER IN AZURE
# These templates show an example of how to use the consul-cluster module to deploy Consul in Azure. We deploy two
# Scale Sets: one with Consul server nodes and one with Consul client nodes. Note that these templates assume
# that the Custom Image you provide via the image_id input variable is built from the
# examples/consul-image/consul.json Packer template.
# ---------------------------------------------------------------------------------------------------------------------

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.secret_access_key}"
  tenant_id = "${var.tenant_id}"
}

terraform {
  required_version = ">= 0.10.0"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE NECESSARY NETWORK RESOURCES FOR THE EXAMPLE
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "consul" {
  name = "consulvn"
  address_space = ["${var.address_space}"]
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_subnet" "consul" {
  name = "consulsubnet"
  resource_group_name = "${var.resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.consul.name}"
  address_prefix = "${var.subnet_address}"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE CONSUL SERVER NODES
# ---------------------------------------------------------------------------------------------------------------------

module "consul_servers" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:hashicorp/terraform-azurerm-consul.git//modules/consul-cluster?ref=v0.0.1"
  source = "./modules/consul-cluster"

  cluster_name = "${var.cluster_name}-server"
  cluster_size = "${var.num_servers}"
  key_data = "${var.key_data}"

  # To make testing easier, we allow Consul and SSH requests from any IP address here but in a production
  # deployment, we strongly recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks = "${var.allowed_ssh_cidr_blocks}"
  allowed_inbound_cidr_blocks = "${var.allowed_inbound_cidr_blocks}"

  resource_group_name = "${var.resource_group_name}"
  storage_account_name = "${var.storage_account_name}"

  location = "${var.location}"
  custom_data = "${data.template_file.user_data_server.rendered}"
  instance_size = "${var.instance_size}"
  image_id = "${var.image_uri}"
  subnet_id = "${azurerm_subnet.consul.id}"

  # When set to true, a load balancer will be created to allow SSH to the instances as described in the 'Connect to VMs by using NAT rules'
  # section of https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-overview
  #
  # For testing and development purposes, set this to true. For production, this should be set to false.
  associate_public_ip_address_load_balancer = true

}

# ---------------------------------------------------------------------------------------------------------------------
# THE CUSTOM DATA SCRIPT THAT WILL RUN ON EACH CONSUL SERVER AZURE INSTANCE WHEN IT'S BOOTING
# This script will configure and start Consul
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_server" {
  template = "${file("${path.module}/custom-data-server.sh")}"

  vars {
    scale_set_name = "${var.cluster_name}-server"
    subscription_id = "${var.subscription_id}"
    tenant_id = "${var.tenant_id}"
    client_id = "${var.client_id}"
    secret_access_key = "${var.secret_access_key}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE CONSUL CLIENT NODES
# Note that you do not have to use the consul-cluster module to deploy your clients. We do so simply because it
# provides a convenient way to deploy a Scale Set for Consul, but feel free to deploy those clients however you choose
# (e.g. a single Azure Compute Instance, a Docker cluster, etc).
# ---------------------------------------------------------------------------------------------------------------------

module "consul_clients" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:hashicorp/terraform-azurerm-consul.git//modules/consul-cluster?ref=v0.0.1"
  source = "./modules/consul-cluster"

  cluster_name = "${var.cluster_name}-client"
  cluster_size = "${var.num_clients}"
  key_data = "${var.key_data}"

  # To make testing easier, we allow Consul and SSH requests from any IP address here but in a production
  # deployment, we strongly recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks = "${var.allowed_ssh_cidr_blocks}"
  allowed_inbound_cidr_blocks = "${var.allowed_inbound_cidr_blocks}"

  resource_group_name = "${var.resource_group_name}"
  storage_account_name = "${var.storage_account_name}"


  location = "${var.location}"
  custom_data = "${data.template_file.user_data_client.rendered}"
  instance_size = "${var.instance_size}"
  image_id = "${var.image_uri}"
  subnet_id = "${azurerm_subnet.consul.id}"

  # When set to true, a load balancer will be created to allow SSH to the instances as described in the 'Connect to VMs by using NAT rules'
  # section of https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-overview
  #
  # For testing and development purposes, set this to true. For production, this should be set to false.
  associate_public_ip_address_load_balancer = true
}

# ---------------------------------------------------------------------------------------------------------------------
# THE CUSTOM DATA SCRIPT THAT WILL RUN ON EACH CONSUL CLIENT AZURE COMPUTE INSTANCE WHEN IT'S BOOTING
# This script will configure and start Consul
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_client" {
  template = "${file("${path.module}/custom-data-client.sh")}"

  vars {
    scale_set_name = "${var.cluster_name}-client"
    subscription_id = "${var.subscription_id}"
    tenant_id = "${var.tenant_id}"
    client_id = "${var.client_id}"
    secret_access_key = "${var.secret_access_key}"
  }
}