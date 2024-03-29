# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: Apache-2.0

# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "security_group_name" {
  description = "The name of the security group to which we should add the Consul security group rules"
}

variable "resource_group_name" {
  description = "The name of the resource group that the security group belongs to"
}

variable "allowed_inbound_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the Azure Instances will allow connections to Consul"
  type        = "list"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "server_rpc_port" {
  description = "The port used by servers to handle incoming requests from other agents."
  default     = 8300
}

variable "cli_rpc_port" {
  description = "The port used by all agents to handle RPC from the CLI."
  default     = 8400
}

variable "serf_lan_port" {
  description = "The port used to handle gossip in the LAN. Required by all agents."
  default     = 8301
}

variable "serf_wan_port" {
  description = "The port used by servers to gossip over the WAN to other servers."
  default     = 8302
}

variable "http_api_port" {
  description = "The port used by clients to talk to the HTTP API"
  default     = 8500
}

variable "dns_port" {
  description = "The port used to resolve DNS queries."
  default     = 8600
}
