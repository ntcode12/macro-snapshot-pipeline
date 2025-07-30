variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "bucket_name" {
  type    = string
  default = "macro-snapshot"
}

variable "db_password" {
  type     = string
  sensitive = true
}

variable "project_tag" {
  type    = string
  default = "macro-snapshot"
}
#