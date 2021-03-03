# infrastructure

## Prerequisite
### Install Terraform
follow the guide from official documentation to download terraform -

https://www.terraform.io/docs/cli/install/apt.html

## Build
### 0. Terraform initialzation
1. Initialize terraform directory: 

Do `terraform init` in directories: `ec2`,`iam`,`networking`,`RDS`,`s3`,`SecurityGroups`

2. To get the setup for terraform apply: `terraform plan`
### 1. Build Networking
Open the terminal in the `networking` directory, then:

1. To create resources:

```
terraform apply -var-file="./variables.tfvars" 
```
  By default if the variables are not provided: `region=us-east-1`, `profile=dev`, `vpc_name=csye6225`

2. To destroy resources: 
```
terraform destroy -var-file="./variables.tfvars" 
```
### 2. Build Security Groups
Open the terminal in the `SecurityGroups` directory, then:

1. To create resources:

```
terraform apply -var-file="./variables.tfvars" 
```

2. To destroy resources: 
```
terraform destroy -var-file="./variables.tfvars" 
```
### 3. Build IAM
Open the terminal in the `iam` directory, then:

1. To create resources:

```
terraform apply -var-file="./variables.tfvars" 
```

2. To destroy resources: 
```
terraform destroy -var-file="./variables.tfvars" 
```
### 4. Build RDS & S3 bucket
Open the terminals in the `s3` and `RDS` directory, then:

1. To create resources:

```
terraform apply -var-file="./variables.tfvars" 
```

2. To destroy resources: 
```
terraform destroy -var-file="./variables.tfvars" 
```
### 5. Create EC2 Instance
Open the terminal in the `ec2` directory, then:

1. To create resources:

```
terraform apply -var-file="./variables.tfvars" 
```

2. To destroy resources: 
```
terraform destroy -var-file="./variables.tfvars" 
```