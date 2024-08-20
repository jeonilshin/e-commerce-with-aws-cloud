resource "aws_ecr_repository" "form" {
  name = "form-ecr"
  force_delete = true
}

resource "aws_ecr_repository" "customer" {
  name = "customer-ecr"
  force_delete = true
}

resource "aws_ecr_repository" "order" {
  name = "order-ecr"
  force_delete = true
}