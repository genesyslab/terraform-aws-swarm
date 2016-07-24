variable "environment_name" {}
variable "key_name" {}
variable "ssh_keypath"{}
variable "owner" {}

# TODO this should be multiple and we should be using a map to spread out the
# masters
/*variable "aws_availability_zone_primary" {}*/
variable "aws_availability_zone" {}

/*variable "aws_availability_zone_secondary" {}*/
variable "aws_region" {}
variable "subnet_id" {}
variable "security_group_ids"{}


/**
 * Note that as of now, we can't actually override
 * this value in the module, so if you want to change the
 * number you must modify it in this file
 */
variable "count" {
  default ="2"
}


variable "instance_type" {
	default = "t2.micro"
}

module "coreos_amis" {
  source = "github.com/terraform-community-modules/tf_aws_coreos_ami"
  region = "${var.aws_region}"
  channel = "stable"
  virttype = "hvm"
}

resource "template_file" "start_consul_sh" {
  template = "${file("${path.module}/consul_server.sh.tpl")}"
  count = "${var.count}"
  vars {
    num_servers = "${var.count}"
    # Script should have both it's own address
    address = "${element(aws_instance.swarm_server.*.private_ip, count.index)}"
    # as well as a root node to run against
    root_address = "${element(aws_instance.swarm_server.*.private_ip, 0)}"
    index = "${count.index}"
  }
}

resource "null_resource" "start_script_provision" {
  count = "${var.count}"

    # Changes to any instance of the cluster requires re-provisioning
    # This is probably wrong and maybe I should just use my own host
   triggers {
     cluster_instance_ids = "${join(",", aws_instance.swarm_server.*.id)}"
   }
   connection {
     host = "${element(aws_instance.swarm_server.*.private_ip, count.index)}"
     user =  "core"
     key_file = "${var.ssh_keypath}"
   }
   provisioner "remote-exec" {
     inline = [

      "cat << 'VPN_START_SCRIPT' > /tmp/consul_start.sh",
      "${element(template_file.start_consul_sh.*.rendered, count.index)}",
      "VPN_START_SCRIPT",
      "sudo mkdir -p /var/consul",
      "sudo mv /tmp/consul_start.sh /var/consul",
      "sudo chmod 755 /var/consul/consul_start.sh",
      "/var/consul/consul_start.sh"

     ]
   }
}

# We have a bootstrap
resource "aws_instance" "swarm_server" {
    availability_zone = "${var.aws_availability_zone}"
    ami = "${module.coreos_amis.ami_id}"
    subnet_id = "${var.subnet_id}"
    instance_type = "${var.instance_type}"
    key_name = "${var.key_name}"

    # TODO
    # Have had lots of issues with this as a variable
    count = "${var.count}"
    vpc_security_group_ids = ["${split(",", var.security_group_ids)}"]
    tags {
      Name = "swarm-master-${count.index}"
      Owner = "${var.owner}"
      Environment = "${var.environment_name}"
    }
    connection {
        user =  "core"
        key_file = "${var.ssh_keypath}"
    }
    provisioner "remote-exec" {
        inline =  [
            "docker pull progrium/consul"
        ]
    }
}


output "instance_0_ip" {
	value ="${aws_instance.swarm_server.0.private_ip}"
}
output "instance_1_ip" {
	value ="${aws_instance.swarm_server.1.private_ip}"
}
