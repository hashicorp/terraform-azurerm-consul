# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE SECURITY GROUP RULES THAT CONTROL WHAT TRAFFIC CAN GO IN AND OUT OF A CONSUL CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_network_security_rule" "allow_server_rpc_inbound" {
  count = "${length(var.allowed_inbound_cidr_blocks)}"

  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "${var.server_rpc_port}"
  direction                   = "Inbound"
  name                        = "ServerRPC${count.index}"
  network_security_group_name = "${var.security_group_name}"
  priority                    = "${200 + count.index}"
  protocol                    = "Tcp"
  resource_group_name         = "${var.resource_group_name}"
  source_address_prefix       = "${element(var.allowed_inbound_cidr_blocks, count.index)}"
  source_port_range           = "1024-65535"
}

resource "azurerm_network_security_rule" "allow_cli_rpc_inbound" {
  count = "${length(var.allowed_inbound_cidr_blocks)}"

  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "${var.cli_rpc_port}"
  direction                   = "Inbound"
  name                        = "CLIRPC${count.index}"
  network_security_group_name = "${var.security_group_name}"
  priority                    = "${250 + count.index}"
  protocol                    = "Tcp"
  resource_group_name         = "${var.resource_group_name}"
  source_address_prefix       = "${element(var.allowed_inbound_cidr_blocks, count.index)}"
  source_port_range           = "1024-65535"
}

resource "azurerm_network_security_rule" "allow_serf_lan_tcp_inbound" {
  count = "${length(var.allowed_inbound_cidr_blocks)}"

  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "${var.serf_lan_port}"
  direction                   = "Inbound"
  name                        = "SerfLan${count.index}"
  network_security_group_name = "${var.security_group_name}"
  priority                    = "${300 + count.index}"
  protocol                    = "Tcp"
  resource_group_name         = "${var.resource_group_name}"
  source_address_prefix       = "${element(var.allowed_inbound_cidr_blocks, count.index)}"
  source_port_range           = "1024-65535"
}

resource "azurerm_network_security_rule" "allow_serf_lan_udp_inbound" {
  count = "${length(var.allowed_inbound_cidr_blocks)}"

  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "${var.serf_lan_port}"
  direction                   = "Inbound"
  name                        = "SerfLanUdp${count.index}"
  network_security_group_name = "${var.security_group_name}"
  priority                    = "${350 + count.index}"
  protocol                    = "Udp"
  resource_group_name         = "${var.resource_group_name}"
  source_address_prefix       = "${element(var.allowed_inbound_cidr_blocks, count.index)}"
  source_port_range           = "1024-65535"
}

resource "azurerm_network_security_rule" "allow_serf_wan_tcp_inbound" {
  count = "${length(var.allowed_inbound_cidr_blocks)}"

  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "${var.serf_wan_port}"
  direction                   = "Inbound"
  name                        = "SerfWan${count.index}"
  network_security_group_name = "${var.security_group_name}"
  priority                    = "${400 + count.index}"
  protocol                    = "Tcp"
  resource_group_name         = "${var.resource_group_name}"
  source_address_prefix       = "${element(var.allowed_inbound_cidr_blocks, count.index)}"
  source_port_range           = "1024-65535"
}

resource "azurerm_network_security_rule" "allow_serf_wan_udp_inbound" {
  count = "${length(var.allowed_inbound_cidr_blocks)}"

  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "${var.serf_wan_port}"
  direction                   = "Inbound"
  name                        = "SerfWanUdp${count.index}"
  network_security_group_name = "${var.security_group_name}"
  priority                    = "${450 + count.index}"
  protocol                    = "Udp"
  resource_group_name         = "${var.resource_group_name}"
  source_address_prefix       = "${element(var.allowed_inbound_cidr_blocks, count.index)}"
  source_port_range           = "1024-65535"
}

resource "azurerm_network_security_rule" "allow_http_api_inbound" {
  count = "${length(var.allowed_inbound_cidr_blocks)}"

  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "${var.http_api_port}"
  direction                   = "Inbound"
  name                        = "HttpApi${count.index}"
  network_security_group_name = "${var.security_group_name}"
  priority                    = "${500 + count.index}"
  protocol                    = "Tcp"
  resource_group_name         = "${var.resource_group_name}"
  source_address_prefix       = "${element(var.allowed_inbound_cidr_blocks, count.index)}"
  source_port_range           = "1024-65535"
}

resource "azurerm_network_security_rule" "allow_dns_tcp_inbound" {
  count = "${length(var.allowed_inbound_cidr_blocks)}"

  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "${var.dns_port}"
  direction                   = "Inbound"
  name                        = "DnsTcp${count.index}"
  network_security_group_name = "${var.security_group_name}"
  priority                    = "${550 + count.index}"
  protocol                    = "Tcp"
  resource_group_name         = "${var.resource_group_name}"
  source_address_prefix       = "${element(var.allowed_inbound_cidr_blocks, count.index)}"
  source_port_range           = "1024-65535"
}

resource "azurerm_network_security_rule" "allow_dns_udp_inbound" {
  count = "${length(var.allowed_inbound_cidr_blocks)}"

  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "${var.dns_port}"
  direction                   = "Inbound"
  name                        = "DnsUdp${count.index}"
  network_security_group_name = "${var.security_group_name}"
  priority                    = "${600 + count.index}"
  protocol                    = "Udp"
  resource_group_name         = "${var.resource_group_name}"
  source_address_prefix       = "${element(var.allowed_inbound_cidr_blocks, count.index)}"
  source_port_range           = "1024-65535"
}

resource "azurerm_network_security_rule" "denyall" {
  access                      = "Deny"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  direction                   = "Inbound"
  name                        = "DenyAll"
  network_security_group_name = "${var.security_group_name}"
  priority                    = 999
  protocol                    = "*"
  resource_group_name         = "${var.resource_group_name}"
  source_address_prefix       = "*"
  source_port_range           = "*"
}
