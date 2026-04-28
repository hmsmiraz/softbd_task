output "control_plane_1_public_ip" {
  description = "Public IP of control-plane node 1 (Elastic IP)"
  value       = aws_eip.control_plane_1_eip.public_ip
}

output "control_plane_1_private_ip" {
  description = "Private IP of control-plane node 1"
  value       = aws_instance.control_plane[0].private_ip
}

output "control_plane_2_public_ip" {
  description = "Public IP of control-plane node 2"
  value       = aws_instance.control_plane[1].public_ip
}

output "control_plane_2_private_ip" {
  description = "Private IP of control-plane node 2"
  value       = aws_instance.control_plane[1].private_ip
}

output "worker_1_public_ip" {
  description = "Public IP of worker node 1"
  value       = aws_instance.worker.public_ip
}

output "worker_1_private_ip" {
  description = "Private IP of worker node 1"
  value       = aws_instance.worker.private_ip
}

output "ssh_command_cp1" {
  description = "SSH command for control-plane node 1"
  value       = "ssh -i ~/.ssh/k8s-key ubuntu@${aws_eip.control_plane_1_eip.public_ip}"
}

output "ssh_command_cp2" {
  description = "SSH command for control-plane node 2"
  value       = "ssh -i ~/.ssh/k8s-key ubuntu@${aws_instance.control_plane[1].public_ip}"
}

output "ssh_command_worker" {
  description = "SSH command for worker node 1"
  value       = "ssh -i ~/.ssh/k8s-key ubuntu@${aws_instance.worker.public_ip}"
}