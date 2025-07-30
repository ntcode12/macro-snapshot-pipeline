# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 3
}

# Local values
locals {
  bucket_name = "${var.bucket_name}-${random_id.suffix.hex}"
} 