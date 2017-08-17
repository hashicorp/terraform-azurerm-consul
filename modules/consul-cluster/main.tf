# ---------------------------------------------------------------------------------------------------------------------
# THESE TEMPLATES REQUIRE TERRAFORM VERSION 0.8 AND ABOVE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.9.3"
}

# TODO: Migrate these resources to input variables
resource "azurerm_virtual_network" "consul" {
  name = "consulvn"
  address_space = [
    "10.0.0.0/16"]
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_subnet" "consul" {
  name = "consulsub"
  resource_group_name = "${var.resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.consul.name}"
  address_prefix = "10.0.2.0/24"
}

resource "azurerm_storage_container" "consul" {
  name = "vhds"
  resource_group_name = "${var.resource_group_name}"
  storage_account_name = "${var.storage_account_name}"
  container_access_type = "private"
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE A LOAD BALANCER FOR TEST ACCESS (SHOULD BE DISABLED FOR PROD)
#---------------------------------------------------------------------------------------------------------------------
resource "azurerm_public_ip" "consul_access" {
  #count                        = "${var.associate_public_ip_address_load_balancer==true ? 1 : 0}"
  name                         = "consul_access"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${var.resource_group_name}"
}

resource "azurerm_lb" "consul_access" {
  #count               = "${var.associate_public_ip_address_load_balancer==true ? 1 : 0}"
  name                = "consul_access"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.consul_access.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "consul_bepool" {
  #count               = "${var.associate_public_ip_address_load_balancer==true ? 1 : 0}"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.consul_access.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_nat_pool" "consul_lbnatpool" {
  #count                          = "${var.associate_public_ip_address_load_balancer==true ? var.cluster_size : 0}"
  resource_group_name            = "${var.resource_group_name}"
  name                           = "ssh"
  loadbalancer_id                = "${azurerm_lb.consul_access.id}"
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50099
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE A VIRTUAL MACHINE SCALE SET TO RUN CONSUL
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_machine_scale_set" "consul" {
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
    computer_name_prefix = "consul"
    admin_username = "consuladmin"
    # TODO: convert to variable
    admin_password = "Passwword1234"
    # TODO: convert to variable
    custom_data = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path = "/home/consuladmin/.ssh/authorized_keys"
      key_data = "${file("~/.ssh/id_rsa.pub")}"
      # TODO: convert to variable
    }

  }

  network_profile {
    name = "ConsulNetworkProfile"
    primary = true

    ip_configuration {
      name = "ConsulIPConfiguration"
      subnet_id = "${azurerm_subnet.consul.id}"
      #load_balancer_backend_address_pool_ids = ["${join("", azurerm_lb_backend_address_pool.consul_bepool.*.id)}"]
      #load_balancer_inbound_nat_rules_ids = ["${element(azurerm_lb_nat_pool.consul_lbnatpool.*.id, count.index)}"]
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.consul_bepool.id}"]
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
    #image = "https://gruntworkconsul.blob.core.windows.net/images/pkroskscpz06yff.vhd"
    os_type = "Linux"
    managed_disk_type = "Standard_LRS"
  }

  tags {
    scaleSetName = "${var.cluster_name}"
  }
}