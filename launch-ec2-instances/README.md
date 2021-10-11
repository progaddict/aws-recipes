This module shows how to launch
a couple of EC2 instances into
VPC created by the `create-vpc`
Terraform module.

It can be used to test
network connectivity
in the created VPC.
In particular, it should be possible to
SSH into the `public_vm` EC2 instance
and from it to SSH into the `private_vm`
EC2 instance.
