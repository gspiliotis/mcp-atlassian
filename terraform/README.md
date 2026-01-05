# MCP Atlassian AWS Deployment with Bedrock Agent Core

This Terraform configuration deploys the MCP Atlassian server on AWS using ECS Fargate with PrivateLink support, designed to work with AWS Bedrock Agent Core.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                          AWS VPC                                │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Private Subnet (with NAT Gateway)          │    │
│  │                                                         │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │         Network Load Balancer (Internal)        │    │    │
│  │  │         ┌─────────────────────────────┐         │    │    │
│  │  │         │   VPC Endpoint Service      │         │    │    │
│  │  │         │      (PrivateLink)          │         │    │    │
│  │  │         └─────────────────────────────┘         │    │    │
│  │  └───────────────────┬─────────────────────────────┘    │    │
│  │                      │                                  │    │
│  │                      ▼                                  │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │           ECS Fargate Tasks (2+)                │    │    │
│  │  │  ┌────────────────────────────────────────┐     │    │    │
│  │  │  │  ghcr.io/sooperset/mcp-atlassian       │     │    │    │
│  │  │  │  - streamable-http transport           │     │    │    │
│  │  │  │  - Port 9000                           │     │    │    │
│  │  │  │  - User-provided auth via headers      │     │    │    │
│  │  │  └────────────────────────────────────────┘     │    │    │
│  │  └──────────────────┬──────────────────────────────┘    │    │
│  │                     │ (NAT Gateway for outbound)        │    │
│  │                     ▼                                   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Route53 Private Hosted Zone                            │    │
│  │  atlassian-mcp.mydomain.net → NLB                       │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Features

- **PrivateLink Support**: VPC Endpoint Service for secure, private connectivity
- **Auto-scaling**: Automatic scaling based on CPU and memory utilization
- **High Availability**: Multiple ECS tasks across availability zones
- **No Server Authentication**: Users provide their own Atlassian credentials via HTTP headers
- **Container from GHCR**: Uses pre-built containers from GitHub Container Registry
- **Private DNS**: Automatic Route53 record in your private hosted zone
- **CloudWatch Monitoring**: Full logging and Container Insights support

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **Existing Infrastructure**:
   - VPC with private subnet
   - NAT Gateway configured in the subnet
   - Route53 private hosted zone

## Quick Start

### 1. Configure Variables

Copy the example tfvars file and customize it:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set the required values:

```hcl
# Required: Your VPC and networking
vpc_id            = "vpc-xxxxxxxxxxxxxxxxx"
private_subnet_id = "subnet-xxxxxxxxxxxxxxxxx"

# Required: Route53 private hosted zone
route53_zone_id = "Z1234567890ABC"
hostname        = "atlassian-mcp.mydomain.net"

# Optional: Customize other settings as needed
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

### 4. Deploy

```bash
terraform apply
```

### 5. Get Service Endpoint

```bash
terraform output service_endpoint
```

Example output:
```
http://atlassian-mcp.mydomain.net:9000/mcp
```

## Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `vpc_id` | VPC ID where service will be deployed | `vpc-xxxxxxxxxxxxxxxxx` |
| `private_subnet_id` | Private subnet with NAT gateway | `subnet-xxxxxxxxxxxxxxxxx` |
| `route53_zone_id` | Route53 private hosted zone ID | `Z1234567890ABC` |
| `hostname` | Hostname for the service | `atlassian-mcp.mydomain.net` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS region for deployment |
| `service_name` | `mcp-atlassian` | Name for ECS service and resources |
| `container_image` | `ghcr.io/sooperset/mcp-atlassian` | Container image from GHCR |
| `container_image_tag` | `latest` | Container image tag |
| `task_cpu` | `512` | CPU units (256, 512, 1024, 2048, 4096) |
| `task_memory` | `1024` | Memory in MB |
| `desired_count` | `2` | Number of ECS tasks |
| `enable_autoscaling` | `true` | Enable auto-scaling |
| `autoscaling_min_capacity` | `2` | Minimum tasks when auto-scaling |
| `autoscaling_max_capacity` | `10` | Maximum tasks when auto-scaling |
| `privatelink_acceptance_required` | `false` | Require manual acceptance for VPC endpoints |
| `enable_bedrock_permissions` | `false` | Add Bedrock API permissions to task role |

See `variables.tf` for all available configuration options.

## Authentication

This deployment **does not** configure server-level authentication. Instead, users provide their Atlassian credentials per-request via HTTP headers:

### For Atlassian Cloud (OAuth)

```python
headers = {
    "Authorization": f"Bearer {user_oauth_token}",
    "X-Atlassian-Cloud-Id": user_cloud_id
}
```

### For Atlassian Server/Data Center (PAT)

```python
headers = {
    "Authorization": f"Token {user_personal_access_token}"
}
```

## Client Usage Example

### Python Client

```python
import asyncio
from mcp.client.streamable_http import streamablehttp_client
from mcp import ClientSession

user_token = "user-specific-oauth-token"
user_cloud_id = "user-specific-cloud-id"

async def main():
    async with streamablehttp_client(
        "http://atlassian-mcp.mydomain.net:9000/mcp",
        headers={
            "Authorization": f"Bearer {user_token}",
            "X-Atlassian-Cloud-Id": user_cloud_id
        }
    ) as (read_stream, write_stream, _):
        async with ClientSession(read_stream, write_stream) as session:
            await session.initialize()

            # Get a Jira issue
            result = await session.call_tool(
                "jira_get_issue",
                {"issue_key": "PROJ-123"}
            )
            print(result)

asyncio.run(main())
```

### Using with AWS Bedrock Agent

When configuring your Bedrock Agent to use this MCP server:

1. Use the service endpoint from `terraform output service_endpoint`
2. Configure the agent to pass user credentials in request headers
3. The VPC Endpoint Service name is available via `terraform output vpc_endpoint_service_name`

## PrivateLink Setup

### For Same-VPC Access

The service is automatically accessible within the VPC at:
```
http://atlassian-mcp.mydomain.net:9000/mcp
```

### For Cross-VPC or Cross-Account Access

1. Get the VPC Endpoint Service name:
   ```bash
   terraform output vpc_endpoint_service_name
   ```

2. Create a VPC Endpoint in the consumer VPC:
   ```bash
   aws ec2 create-vpc-endpoint \
     --vpc-id vpc-consumer \
     --vpc-endpoint-type Interface \
     --service-name <endpoint-service-name> \
     --subnet-ids subnet-consumer1 subnet-consumer2
   ```

3. If `privatelink_acceptance_required = true`, accept the connection:
   ```bash
   aws ec2 accept-vpc-endpoint-connections \
     --service-id <service-id> \
     --vpc-endpoint-ids vpce-xxxxx
   ```

## Monitoring and Debugging

### View Logs

```bash
aws logs tail /ecs/mcp-atlassian --follow
```

Or use CloudWatch Logs Insights:
```bash
terraform output cloudwatch_log_group_name
```

### ECS Exec (Shell Access)

If `enable_ecs_exec = true`, you can connect to a running task:

```bash
# List tasks
aws ecs list-tasks --cluster mcp-atlassian

# Connect to a task
aws ecs execute-command \
  --cluster mcp-atlassian \
  --task <task-arn> \
  --container mcp-atlassian \
  --interactive \
  --command "/bin/sh"
```

### CloudWatch Container Insights

If `enable_container_insights = true`, view metrics in CloudWatch:
- ECS Cluster metrics
- Task-level CPU and memory
- Network metrics

## Auto-scaling

The deployment includes auto-scaling policies based on:
- **CPU utilization**: Target 70%
- **Memory utilization**: Target 80%

Customize these values in `terraform.tfvars`:
```hcl
autoscaling_cpu_target    = 70
autoscaling_memory_target = 80
autoscaling_min_capacity  = 2
autoscaling_max_capacity  = 10
```

## Cost Optimization

### Development/Testing

```hcl
task_cpu               = "256"
task_memory            = "512"
desired_count          = 1
enable_autoscaling     = false
enable_container_insights = false
log_retention_days     = 7
```

### Production

```hcl
task_cpu                    = "512"
task_memory                 = "1024"
desired_count               = 2
enable_autoscaling          = true
autoscaling_max_capacity    = 10
enable_container_insights   = true
enable_deletion_protection  = true
log_retention_days          = 30
```

## Outputs

After deployment, Terraform provides several useful outputs:

```bash
# Service endpoint
terraform output service_endpoint

# VPC Endpoint Service name (for PrivateLink)
terraform output vpc_endpoint_service_name

# ECS cluster name
terraform output ecs_cluster_name

# CloudWatch log group
terraform output cloudwatch_log_group_name

# Usage instructions
terraform output usage_instructions
```

## Security Considerations

1. **No Credentials in Code**: User credentials are provided per-request via headers
2. **Private Subnet**: ECS tasks run in private subnet with NAT gateway for outbound
3. **Security Groups**: Restrictive ingress/egress rules
4. **IAM Roles**: Least-privilege permissions for ECS tasks
5. **PrivateLink**: Optional private connectivity without internet exposure
6. **Encryption**: Use AWS KMS for CloudWatch Logs encryption (add to config if needed)

## Troubleshooting

### Tasks Not Starting

1. Check ECS service events:
   ```bash
   aws ecs describe-services \
     --cluster mcp-atlassian \
     --services mcp-atlassian
   ```

2. Verify security group rules allow NLB → ECS communication

3. Check CloudWatch logs for application errors

### Connection Issues

1. Verify Route53 record resolves:
   ```bash
   nslookup atlassian-mcp.mydomain.net
   ```

2. Test NLB health:
   ```bash
   aws elbv2 describe-target-health \
     --target-group-arn <target-group-arn>
   ```

3. Check security group rules

### Authentication Failures

- Verify users are providing correct headers
- Check CloudWatch logs for authentication errors
- Ensure users have valid Atlassian credentials

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

⚠️ **Warning**: This will delete:
- ECS cluster and services
- Network Load Balancer
- VPC Endpoint Service
- Route53 records
- CloudWatch logs (if retention expired)
- Security groups
- IAM roles

## Additional Resources

- [MCP Atlassian Documentation](../README.md)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [AWS PrivateLink](https://docs.aws.amazon.com/vpc/latest/privatelink/)
- [Model Context Protocol](https://modelcontextprotocol.io/)

## Support

For issues related to:
- **Terraform deployment**: Open an issue in this repository
- **MCP Atlassian functionality**: See the [main README](../README.md)
- **AWS services**: Consult AWS documentation

## License

Same as the main project - see [LICENSE](../LICENSE)
