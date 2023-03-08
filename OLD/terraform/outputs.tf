output "publicIP" {
    value = aws_instance.aws.public_ip
    description = "The public address of host"
}

output "privateIP" {
    value = aws_instance.aws.private_ip
    description = "The private address of host"
}