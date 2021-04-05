resource "aws_dynamodb_table" "webapp-dynamodb" {
  name           = "csye6225"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "webapp-dynamodb"
  }

}
