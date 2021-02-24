# infrastructure

## Prerequisite
### Install Terraform
follow the guide from official documentation to download terraform -

https://www.terraform.io/docs/cli/install/apt.html

## Build
### Networking
Open the terminal in the `networking` directory, then:

1. Initialize terraform directory: `terraform init`

2. To get the setup for terraform apply: `terraform plan`

3. To create resources:

```
terraform apply -var 'region=<region>' -var 'profile=<aws_profile>' -var 'vpc_name=<Your VPC name>' 
```
  By default if the variables are not provided: `region=us-east-1`, `profile=dev`, `vpc_name=csye6225`

4. To destroy resources: 
```
terraform destroy -var 'region=<region>' -var 'profile=<aws_profile>' -var 'vpc_name=<Your VPC name>' 
```
