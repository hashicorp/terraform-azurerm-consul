output "scale_set_name" {
  value = "${element(concat(azurerm_virtual_machine_scale_set.consul_with_load_balancer.*.name, azurerm_virtual_machine_scale_set.consul.*.name), 0)}"
}

output "cluster_size" {
  value = "${var.cluster_size}"
}

output "load_balancer_ip_address" {
  value = "${azurerm_public_ip.consul_access.*.ip_address}"
}

output "load_balancer_id" {
  value = "${azurerm_lb.consul_access.*.id}"
}

output "backend_pool_id" {
  value = "${azurerm_lb_backend_address_pool.consul_bepool.*.id}"
}
