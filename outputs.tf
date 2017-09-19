output "num_servers" {
  value = "${module.consul_servers.cluster_size}"
}

output "scale_set_name_servers" {
  value = "${module.consul_servers.scale_set_name}"
}

output "load_balancer_ip_address_servers" {
  value = "${module.consul_servers.load_balancer_ip_address}"
}

output "load_balancer_ip_address_clients" {
  value = "${module.consul_clients.load_balancer_ip_address}"
}
