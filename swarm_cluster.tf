

variable "aws_region"{}
# TODO, this should be a list
variable "aws_availability_zone" {}
variable "owner" {}
variable "environment_name"{}
variable "ssh_keypath" {}
variable "key_name" {}
variable "subnet_id" {}
variable "security_group_ids" {
  type = "list"
}
variable "leader_number" {
  default = 2
}
variable "worker_number" {
  default = "3"
}


module "coreos_amis" {
  source = "github.com/terraform-community-modules/tf_aws_coreos_ami"
  region = "${var.aws_region}"
  channel = "stable"
  virttype = "hvm"
}
/
module "master" {
  source = "modules/swarm_master"
  count = "${var.leader_number}"
  ami = "${module.coreos_amis.ami_id}"
  owner = "${var.owner}"
  aws_availability_zone = "${var.aws_availability_zone}"
  environment_name = "${var.environment_name}"
  ssh_keypath = "${var.ssh_keypath}"
  key_name =  "${var.key_name}"
  subnet_id = "${var.subnet_id}"
  # TODO master and worker security group ids should be able to be separate
  security_group_ids = "${var.security_group_ids}"
}


module "worker" {
  source = "modules/swarm_worker"
  count = "3"
  ami = "${module.coreos_amis.ami_id}"
  swarm_master_ip = "${module.master.swarm_master_0}"
  owner = "${var.owner}"
  aws_availability_zone = "${var.aws_availability_zone}"
  environment_name = "${var.environment_name}"
  ssh_keypath = "${var.ssh_keypath}"
  key_name =  "${var.key_name}"
  subnet_id = "${var.subnet_id}"
  security_group_ids = "${var.security_group_ids}"
}

output "swarm_master_0" {
  value = "${module.master.swarm_master_0}"
}
