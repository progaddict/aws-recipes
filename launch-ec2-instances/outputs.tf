output "public_vm_ip" {
  description = "Public IP of the public VM."
  value       = aws_instance.public_vm.public_ip
}

output "private_vm_ip" {
  description = "Private IP of the private VM."
  value       = aws_instance.private_vm.private_ip
}
