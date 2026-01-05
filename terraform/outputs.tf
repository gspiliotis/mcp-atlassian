# Service Endpoints
output "service_endpoint" {
  description = "Internal endpoint for the MCP Atlassian service"
  value       = "http://${aws_route53_record.main.fqdn}:${var.service_port}/mcp"
}

output "hostname" {
  description = "Private DNS hostname for the service"
  value       = aws_route53_record.main.fqdn
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.main.dns_name
}

# VPC Endpoint Service
output "vpc_endpoint_service_name" {
  description = "Name of the VPC Endpoint Service for PrivateLink connections"
  value       = aws_vpc_endpoint_service.main.service_name
}

output "vpc_endpoint_service_id" {
  description = "ID of the VPC Endpoint Service"
  value       = aws_vpc_endpoint_service.main.id
}

output "vpc_endpoint_service_arn" {
  description = "ARN of the VPC Endpoint Service"
  value       = aws_vpc_endpoint_service.main.arn
}

# ECS Service
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.main.name
}

output "ecs_service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.main.id
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.mcp_atlassian.arn
}

# Security Groups
output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "nlb_security_group_id" {
  description = "Security group ID for the Network Load Balancer"
  value       = aws_security_group.nlb.id
}

# IAM Roles
output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

# CloudWatch
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.mcp_atlassian.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.mcp_atlassian.arn
}

# Load Balancer
output "nlb_arn" {
  description = "ARN of the Network Load Balancer"
  value       = aws_lb.main.arn
}

output "nlb_target_group_arn" {
  description = "ARN of the NLB target group"
  value       = aws_lb_target_group.main.arn
}

# Usage Instructions
output "usage_instructions" {
  description = "Instructions for using the deployed MCP Atlassian service"
  value = <<-EOT
    MCP Atlassian service has been deployed successfully!

    Service Endpoint: http://${aws_route53_record.main.fqdn}:${var.service_port}/mcp

    To connect to this service, clients should use the streamable-http transport and provide
    authentication via HTTP headers:

    For Atlassian Cloud (OAuth):
      Authorization: Bearer <user_oauth_token>
      X-Atlassian-Cloud-Id: <user_cloud_id>

    For Atlassian Server/Data Center (PAT):
      Authorization: Token <user_personal_access_token>

    Example Python client:
      from mcp.client.streamable_http import streamablehttp_client

      async with streamablehttp_client(
          "http://${aws_route53_record.main.fqdn}:${var.service_port}/mcp",
          headers={
              "Authorization": f"Bearer {user_token}",
              "X-Atlassian-Cloud-Id": user_cloud_id
          }
      ) as (read, write, _):
          async with ClientSession(read, write) as session:
              await session.initialize()
              # Use the session...

    VPC Endpoint Service Name: ${aws_vpc_endpoint_service.main.service_name}
    (Use this to create VPC endpoints in other VPCs/accounts)

    CloudWatch Logs: ${aws_cloudwatch_log_group.mcp_atlassian.name}
  EOT
}
