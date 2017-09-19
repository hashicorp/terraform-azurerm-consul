# Consul Cluster

This folder contains a [Terraform](https://www.terraform.io/) module to deploy a 
[Consul](https://www.consul.io/) cluster in [Azure](https://azure.microsoft.com/) on top of a Scale Set. This module 
is designed to deploy an [Azure Managed Image](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/build-image-with-packer) 
that has Consul installed via the [install-consul](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/modules/install-consul) module in this Module.

## How do you use this module?

This folder defines a [Terraform module](https://www.terraform.io/docs/modules/usage.html), which you can use in your
code by adding a `module` configuration and setting its `source` parameter to URL of this folder:

```hcl
module "consul_cluster" {
  # TODO: update this to the final URL
  # Use version v0.0.1 of the consul-cluster module
  source = "github.com/hashicorp/terraform-azurerm-consul//modules/consul-cluster?ref=v0.0.1"

  # Specify the ID of the Consul AMI. You should build this using the scripts in the install-consul module.
  ami_id = "ami-abcd1234"
  
  # Add this tag to each node in the cluster
  cluster_tag_key   = "consul-cluster"
  cluster_tag_value = "consul-cluster-example"
  
  # Configure and start Consul during boot. It will automatically form a cluster with all nodes that have that same tag. 
  user_data = <<-EOF
              #!/bin/bash
              /opt/consul/bin/run-consul --server --cluster-tag-key consul-cluster
              EOF
  
  # ... See vars.tf for the other parameters you must define for the consul-cluster module
}
```

Note the following parameters:

* `source`: Use this parameter to specify the URL of the consul-cluster module. The double slash (`//`) is intentional 
  and required. Terraform uses it to specify subfolders within a Git repo (see [module 
  sources](https://www.terraform.io/docs/modules/sources.html)). The `ref` parameter specifies a specific Git tag in 
  this repo. That way, instead of using the latest version of this module from the `master` branch, which 
  will change every time you run Terraform, you're using a fixed version of the repo.

* `image_uri`: Use this parameter to specify the URI of a Vault [Azure Managed Image]
(https://docs.microsoft.com/en-us/azure/virtual-machines/linux/build-image-with-packer) to deploy on each server in the 
cluster. You should install Vault in this image using the scripts in the [install-vault](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/modules/install-vault) module.
  
* `custom_data`: Use this parameter to specify a [Custom 
  Data](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/classic/inject-custom-data) script that each
  server will run during boot. This is where you can use the [run-vault script](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/modules/run-vault) to configure and 
  run Vault. The `run-vault` script is one of the scripts installed by the [install-vault](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/modules/install-vault) 
  module. 

You can find the other parameters in [vars.tf](vars.tf).

Check out the [main example](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/MAIN.md) for fully-working sample code. 


## How do you connect to the Consul cluster?

### Using the HTTP API from your own computer

If you want to connect to the cluster from your own computer, the easiest way is to use the [HTTP 
API](https://www.consul.io/docs/agent/http.html). Note that this only works if the Consul cluster is running in public 
subnets and/or your default VPC (as in the [consul-cluster example](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/examples/consul-cluster)), which is OK for testing
and experimentation, but NOT recommended for production usage.

To use the HTTP API, you first need to get the public IP address of one of the Consul Servers. If you're running the [consul-cluster example](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/examples/consul-cluster), the 
[consul-examples-helper.sh script](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/examples/consul-examples-helper/consul-examples-helper.sh) will do the lookup 
for you automatically (note, you must have the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest), 
[jq](https://stedolan.github.io/jq/), and the [Consul agent](https://www.consul.io/) installed locally):

```
> ../consul-examples-helper/consul-examples-helper.sh

Your Consul servers are running at the following IP addresses:

34.200.218.123
34.205.127.138
34.201.165.11
```

You can use one of these IP addresses with the `members` command to see a list of cluster nodes:

```
> consul members -rpc-addr=11.22.33.44:8400

Node                 Address             Status  Type    Build  Protocol  DC
i-0051c3ea00e9691a0  172.31.35.148:8301  alive   client  0.8.0  2         us-east-1
i-00aea529cce1761d4  172.31.47.236:8301  alive   client  0.8.0  2         us-east-1
i-01bc94ccfa032d82d  172.31.27.193:8301  alive   client  0.8.0  2         us-east-1
i-04271e97808f15d63  172.31.25.174:8301  alive   server  0.8.0  2         us-east-1
i-0483b07abe49ea7ff  172.31.5.42:8301    alive   client  0.8.0  2         us-east-1
i-098fb1ebd5ca443bf  172.31.55.203:8301  alive   client  0.8.0  2         us-east-1
i-0eb961b6825f7871c  172.31.65.9:8301    alive   client  0.8.0  2         us-east-1
i-0ee6dcf715adbff5f  172.31.67.235:8301  alive   server  0.8.0  2         us-east-1
i-0fd0e63682a94b245  172.31.54.84:8301   alive   server  0.8.0  2         us-east-1
```

You can also try inserting a value:

```
> consul kv put -http-addr=11.22.33.44:8500 foo bar

Success! Data written to: foo
```

And reading that value back:
 
```
> consul kv get -http-addr=11.22.33.44:8500 foo

bar
```

Finally, you can try opening up the Consul UI in your browser at the URL `http://11.22.33.44:8500/ui/`.

![Consul UI](https://raw.githubusercontent.com/hashicorp/terraform-azurerm-consul/master/_docs/consul-ui-screenshot.png)


## What's included in this module?

This module creates the following architecture:

![Consul architecture](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/_docs/architecture.png)

## How do you roll out updates?

If you want to deploy a new version of Consul across the cluster, the best way to do that is to:

1. Build a new Azure Image.
1. Set the `image_uri` parameter to the URI of the new Image.
1. Run `terraform apply`.

This updates the Launch Configuration of the Scale Set, so any new Instances in the Scale Set will have your new AMI, 
but it does NOT actually deploy those new instances. To make that happen, you should do the following:

1. Issue an API call to one of the old Instances in the Scale Set to have it leave gracefully. E.g.:

    ```
    curl -X PUT <OLD_INSTANCE_IP>:8500/v1/agent/leave
    ```
    
1. Once the instance has left the cluster, ssh to the instance and terminate it:
 
    ```
    sudo init 0
    ```

1. After a minute or two, the Scale Set should automatically launch a new Instance, with the new Azure Image, to replace the old one.

1. Wait for the new Instance to boot and join the cluster.

1. Repeat these steps for each of the other old Instances in the Scale Set.
   
We will add a script in the future to automate this process (PRs are welcome!).


## What happens if a node crashes?

There are two ways a Consul node may go down:
 
1. The Consul process may crash. In that case, `supervisor` should restart it automatically.
1. The Azure Instance running Consul dies. In that case, the Scale Set should launch a replacement automatically. 
   Note that in this case, since the Consul agent did not exit gracefully, and the replacement will have a different ID,
   you may have to manually clean out the old nodes using the [force-leave
   command](https://www.consul.io/docs/commands/force-leave.html). We may add a script to do this 
   automatically in the future. For more info, see the [Consul Outage 
   documentation](https://www.consul.io/docs/guides/outage.html).



## Security

Here are some of the main security considerations to keep in mind when using this module:

1. [Encryption in transit](#encryption-in-transit)
1. [Encryption at rest](#encryption-at-rest)
1. [Dedicated instances](#dedicated-instances)
1. [Security groups](#security-groups)
1. [SSH access](#ssh-access)


### Encryption in transit

Consul can encrypt all of its network traffic. For instructions on enabling network encryption, have a look at the
[How do you handle encryption documentation](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/modules/run-consul#how-do-you-handle-encryption).


### Encryption at rest

The Azure Instances in the cluster store all their data on the root EBS Volume. To enable encryption for the data at
rest, you must enable encryption in your Consul Azure Image. 
