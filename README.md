# Secure Web Application on AWS (Terraform)

Cloud Security capstone: VPC + ALB + EC2 + RDS with layered network security,
VPC Flow Logs and CloudTrail.

## Files

| File | Purpose |
|---|---|
| versions.tf | Terraform and AWS provider config |
| variables.tf | Region, CIDRs, sizes (all with defaults) |
| network.tf | VPC, 6 subnets, IGW, NAT GW, route tables |
| security_groups.tf | ALB, App, DB security groups (SG-to-SG rules) |
| alb.tf | Application Load Balancer, target group, listener |
| compute.tf | EC2 app server (private, IMDSv2, SSM, encrypted EBS) |
| database.tf | RDS MySQL (private, encrypted, Secrets Manager password) |
| monitoring.tf | VPC Flow Logs to CloudWatch, CloudTrail to S3 |
| outputs.tf | ALB URL, IDs, endpoints |
| architecture.svg | Architecture diagram |

## Prerequisites

- AWS account and CLI configured (`aws configure`) with permissions for EC2, VPC, ELB, RDS, IAM, S3, CloudTrail, CloudWatch, Secrets Manager
- Terraform >= 1.5

## Deploy

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

Wait 5-10 minutes (RDS is slow), then open the `alb_dns_name` output in a browser.

## Destroy (to avoid charges: NAT Gateway and RDS cost money)

```bash
terraform destroy
```

## Security design

- Only the ALB sits in public subnets; EC2 and RDS have no public IPs.
- DB subnets have no route to the internet at all.
- Security groups chain: Internet -> ALB SG -> App SG -> DB SG. The DB accepts 3306 only from the App SG.
- No SSH. Admin access is via SSM Session Manager.
- IMDSv2 enforced; EBS, RDS and S3 encrypted.
- RDS password is generated and held in Secrets Manager (never in code or state variables).
- Default security group has all rules removed.
- Flow Logs capture ALL traffic; CloudTrail is multi-region with log file validation; the log bucket blocks public access and denies non-TLS.

## Screenshot checklist (for submission)

Take each in the AWS Console (region ap-southeast-2) and add a one-line caption.

1. Terminal: `terraform apply` complete, with the outputs shown
2. VPC > Your VPCs: VPC with CIDR 10.0.0.0/16
3. VPC > Subnets: all 6 subnets (public, private-app, private-db) across 2 AZs
4. VPC > Internet gateways (attached) and NAT gateways (Available, in a public subnet)
5. VPC > Route tables: public (0.0.0.0/0 -> igw), app (0.0.0.0/0 -> nat), db (local only)
6. EC2 > Load balancers: ALB, scheme "internet-facing", Active; and its Target group showing the instance **healthy**
7. Browser: the ALB DNS URL showing the app page
8. EC2 > Instances: app server with **no public IPv4 address**, in a private-app subnet
9. EC2 > Security groups: inbound rules of alb-sg, app-sg (source = alb-sg), db-sg (source = app-sg)
10. RDS > Databases: instance with **Publicly accessible = No**, in the DB subnet group
11. Proof the DB is private: from your laptop `nc -zv <rds_endpoint> 3306` times out (screenshot the failure)
12. Proof the DB works from the app: Session Manager shell on the EC2, then `nc -zv <rds_endpoint> 3306` succeeds
13. VPC > Your VPCs > Flow logs tab: Flow log with Status Active, destination CloudWatch
14. CloudWatch > Log groups > `/aws/vpc/secure-webapp-flow-logs`: log events (ACCEPT/REJECT)
15. CloudTrail > Trails: `secure-webapp-trail`, multi-region, logging ON, log file validation enabled
16. CloudTrail > Event history, or the S3 bucket showing delivered log files
17. S3 > the CloudTrail bucket > Permissions: "Block all public access: On"

## Optional improvements (mention in your report)

- HTTPS listener with ACM certificate and HTTP->HTTPS redirect
- Auto Scaling Group across both app subnets instead of one EC2 (true scalability)
- Multi-AZ RDS and one NAT Gateway per AZ
- AWS WAF on the ALB, GuardDuty, CloudWatch alarms on REJECT spikes
- Remote Terraform state in S3 with DynamoDB locking
