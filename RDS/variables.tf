variable "region" {
  type = string
  default = "us-east-1"
}

variable "profile" {
  type = string
  default = "dev"
}

variable "cred_vars" {
  type = map(string)

  default = {
    "username" = "csye6225"
    "password" = "Cloud456!"
    "name" = "csye6225"
    "identifier" = "csye6225"
    "key_name" = "csye6225"
  }
}