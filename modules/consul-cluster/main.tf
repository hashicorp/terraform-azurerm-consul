terraform {
  required_version = ">= 0.10.0"
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE A LOAD BALANCER FOR TEST ACCESS (SHOULD BE DISABLED FOR PROD)
#---------------------------------------------------------------------------------------------------------------------
resource "azurerm_public_ip" "consul_access" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  name = "${var.cluster_name}_access"
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  public_ip_address_allocation = "static"
  domain_name_label = "${var.cluster_name}"
}

resource "azurerm_lb" "consul_access" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  name = "${var.cluster_name}_access"
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  frontend_ip_configuration {
    name = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.consul_access.id}"
  }
}

resource "azurerm_lb_nat_pool" "consul_lbnatpool" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  resource_group_name = "${var.resource_group_name}"
  name = "ssh"
  loadbalancer_id = "${azurerm_lb.consul_access.id}"
  protocol = "Tcp"
  frontend_port_start = 2200
  frontend_port_end = 2299
  backend_port = 22
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_lb_nat_pool" "consul_lbnatpool_rpc" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  resource_group_name = "${var.resource_group_name}"
  name = "rpc"
  loadbalancer_id = "${azurerm_lb.consul_access.id}"
  protocol = "Tcp"
  frontend_port_start = 8300
  frontend_port_end = 8399
  backend_port = 8300
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_lb_nat_pool" "consul_lbnatpool_http" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  resource_group_name = "${var.resource_group_name}"
  name = "http"
  loadbalancer_id = "${azurerm_lb.consul_access.id}"
  protocol = "Tcp"
  frontend_port_start = 8500
  frontend_port_end = 8599
  backend_port = 8500
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_lb_backend_address_pool" "consul_bepool" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id = "${azurerm_lb.consul_access.id}"
  name = "BackEndAddressPool"
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE A VIRTUAL MACHINE SCALE SET TO RUN CONSUL (WITHOUT LOAD BALANCER)
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_machine_scale_set" "consul" {
  count = "${var.associate_public_ip_address_load_balancer ? 0 : 1}"
  name = "${var.cluster_name}"
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  upgrade_policy_mode = "Manual"

  sku {
    name = "${var.instance_size}"
    tier = "${var.instance_tier}"
    capacity = "${var.cluster_size}"
  }

  os_profile {
    computer_name_prefix = "${var.computer_name_prefix}"
    admin_username = "${var.admin_user_name}"

    #This password is unimportant as it is disabled below in the os_profile_linux_config
    admin_password = "Passwword1234"
    custom_data = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path = "/home/${var.admin_user_name}/.ssh/authorized_keys"
      key_data = "${var.key_data}"
    }
  }

  network_profile {
    name = "ConsulNetworkProfile"
    primary = true

    ip_configuration {
      name = "ConsulIPConfiguration"
      subnet_id = "${var.subnet_id}"
    }
  }

  storage_profile_image_reference {
    id = "${var.image_id}"
  }

  storage_profile_os_disk {
    name = ""
    caching = "ReadWrite"
    create_option = "FromImage"
    os_type = "Linux"
    managed_disk_type = "Standard_LRS"
  }

  tags {
    scaleSetName = "${var.cluster_name}"
  }
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE A VIRTUAL MACHINE SCALE SET TO RUN CONSUL (WITH LOAD BALANCER)
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_machine_scale_set" "consul_with_load_balancer" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  name = "${var.cluster_name}"
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  upgrade_policy_mode = "Manual"

  sku {
    name = "${var.instance_size}"
    tier = "${var.instance_tier}"
    capacity = "${var.cluster_size}"
  }

  os_profile {
    computer_name_prefix = "${var.computer_name_prefix}"
    admin_username = "${var.admin_user_name}"

    #This password is unimportant as it is disabled below in the os_profile_linux_config
    admin_password = "Passwword1234"
    custom_data = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path = "/home/${var.admin_user_name}/.ssh/authorized_keys"
      key_data = "${var.key_data}"
    }
  }

  network_profile {
    name = "ConsulNetworkProfile"
    primary = true

    ip_configuration {
      name = "ConsulIPConfiguration"
      subnet_id = "${var.subnet_id}"
      load_balancer_backend_address_pool_ids = [
        "${azurerm_lb_backend_address_pool.consul_bepool.id}"]
      load_balancer_inbound_nat_rules_ids = ["${element(azurerm_lb_nat_pool.consul_lbnatpool.*.id, count.index)}"]
    }
  }

  storage_profile_image_reference {
    id = "${var.image_id}"
  }

  storage_profile_os_disk {
    name = ""
    caching = "ReadWrite"
    create_option = "FromImage"
    os_type = "Linux"
    managed_disk_type = "Standard_LRS"
  }

  tags {
    scaleSetName = "${var.cluster_name}"
  }
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP AND RULES FOR SSH
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_network_security_group" "consul" {
  name = "${var.cluster_name}"
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_network_security_rule" "ssh" {
  count = "${length(var.allowed_ssh_cidr_blocks)}"

  access = "Allow"
  destination_address_prefix = "*"
  destination_port_range = "22"
  direction = "Inbound"
  name = "SSH${count.index}"
  network_security_group_name = "${azurerm_network_security_group.consul.name}"
  priority = "${100 + count.index}"
  protocol = "Tcp"
  resource_group_name = "${var.resource_group_name}"
  source_address_prefix = "${element(var.allowed_ssh_cidr_blocks, count.index)}"
  source_port_range = "1024-65535"
}

# ---------------------------------------------------------------------------------------------------------------------
# THE CONSUL-SPECIFIC INBOUND/OUTBOUND RULES COME FROM THE CONSUL-SECURITY-GROUP-RULES MODULE
# ---------------------------------------------------------------------------------------------------------------------

module "security_group_rules" {
  source = "../consul-security-group-rules"

  security_group_name = "${azurerm_network_security_group.consul.name}"
  resource_group_name = "${var.resource_group_name}"
  allowed_inbound_cidr_blocks = ["${var.allowed_inbound_cidr_blocks}"]

  server_rpc_port = "${var.server_rpc_port}"
  cli_rpc_port    = "${var.cli_rpc_port}"
  serf_lan_port   = "${var.serf_lan_port}"
  serf_wan_port   = "${var.serf_wan_port}"
  http_api_port   = "${var.http_api_port}"
  dns_port        = "${var.dns_port}"
}
