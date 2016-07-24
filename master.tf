

variable "bucket_name" {
  default = "terraform-versioned-state"
}
variable "bucket_region"{}
variable "bucket_key"{}
variable "aws_region"{}
variable "aws_availability_zone" {}
variable "owner" {}

resource "terraform_remote_state" "lab" {
    backend = "s3"
    config {
        bucket = "${var.bucket_name}"
        # The bucket is in us east wher we store the state
        # (we actually don't have control of where the bucket will be created)
        region = "${var.bucket_region}"
        # But the key by convention includes the region the lab is setup for"
        key = "${var.bucket_key}"
    }
}

module "master" {
  source = "modules/swarm_master"
  owner = "${var.owner}"
  aws_availability_zone = "${var.aws_availability_zone}"
  aws_region = "${var.aws_region}"
  environment_name = "${terraform_remote_state.lab.output.environment_name}"
  ssh_keypath = "${terraform_remote_state.lab.output.key_file}"
  key_name =  "${terraform_remote_state.lab.output.key_name}"
  subnet_id = "${terraform_remote_state.lab.output.private_subnet_id}"
  security_group_ids = "${terraform_remote_state.lab.output.security_group_ids}"
}


output "swarm_master_0" {
  value = "${module.master.swarm_master_0}"
}
/*
aws_region         = us-east-1
  bastion_ip         = 52.23.190.80
  bastion_user       = centos
  bucket_key         = us-east-1/vpc/terraform.tfstate
  environment_name   = infratest
  key_file           = /home/vagrant/.ssh/deploy_key.pem
  key_name           = deploy_key
  private_subnet_id  = subnet-c72aca8e
  security_group_ids = sg-cbcdc5b0
  vpc_cidr           = 10.60.0.0/16
module "vpn" {
  source = "../modules/vpn"
  host_address = "${terraform_remote_state.lab.output.bastion_ip}"
  host_user = "${terraform_remote_state.lab.output.bastion_user}"
  ssh_keypath = "${terraform_remote_state.lab.output.key_file}"
  vpn_cidr = "${terraform_remote_state.lab.output.vpc_cidr}"
}*/
