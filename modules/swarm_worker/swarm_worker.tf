variable "environment_name" {}
variable "key_name" {}
variable "ssh_keypath"{}
variable "owner" {}

# TODO this should be multiple and we should be using a map to spread out the
# masters
/*variable "aws_availability_zone_primary" {}*/
variable "aws_availability_zone" {}

/*variable "aws_availability_zone_secondary" {}*/
variable "ami" {}
variable "subnet_id" {}
variable "security_group_ids"{type = "list"}
variable "swarm_master_ip"{}
variable "swarm_install_dir" {
  default="/var/swarm"
}
variable "account" {
  default = "core"
}

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


resource "template_file" "start_swarm_agent" {
  template = "${file("${path.module}/swarm_start_agent.sh.tpl")}"
  vars {
    consul_server = "${var.swarm_master_ip}"
  }
}

# We have a bootstrap
resource "aws_instance" "swarm_agent" {
    availability_zone = "${var.aws_availability_zone}"
    ami = "${var.ami}"
    subnet_id = "${var.subnet_id}"
    instance_type = "${var.instance_type}"
    key_name = "${var.key_name}"
    # TODO
    # Have had lots of issues with this as a variable
    count = "${var.count}"
    vpc_security_group_ids = "${var.security_group_ids}"
    tags {
      Name = "swarm-agent-${count.index}"
      Owner = "${var.owner}"
      Environment = "${var.environment_name}"
    }

    # Ensure docker service is enabled so that the master
    # can run docker on the agents
    user_data = <<EOC
#cloud-config

coreos:
  units:
    - name: docker-tcp.socket
      command: start
      enable: true
      content: |
        [Unit]
        Description=Docker Socket for the API

        [Socket]
        ListenStream=2375
        BindIPv6Only=both
        Service=docker.service

        [Install]
        WantedBy=sockets.target
  EOC

    connection {
        user =  "${var.account}"
        key_file = "${var.ssh_keypath}"
    }
    provisioner "remote-exec" {
        inline =  [
            "docker pull swarm",
            "sudo mkdir -p ${var.swarm_install_dir}",
            "sudo chown ${var.account} ${var.swarm_install_dir}",
            "cat << 'SWARM_START_SCRIPT' > ${var.swarm_install_dir}/swarm_start_agent.sh",
            "${template_file.start_swarm_agent.rendered}",
            "SWARM_START_SCRIPT",
            "chmod 755 ${var.swarm_install_dir}/swarm_start_agent.sh",
            "${var.swarm_install_dir}/swarm_start_agent.sh"


        ]
    }
}
