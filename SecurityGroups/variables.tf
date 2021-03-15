variable "region" {
  type = string
  default = "us-east-1"
}

variable "profile" {
  type = string
  default = "dev"
}

// variable "vpc_id" {
//   type = string
// }


// CIDR blocks
variable "cidr_block_22" {
  type = string
  default = "0.0.0.0/0"
}

variable "cidr_block_80" {
  type = string
  default = "0.0.0.0/0"
}
variable "cidr_block_443" {
  type = string
  default = "0.0.0.0/0"
}
variable "cidr_block_8080" {
  type = string
  default = "0.0.0.0/0"
}
variable "cidr_block_3306" {
  type = string
  default = "0.0.0.0/0"
}