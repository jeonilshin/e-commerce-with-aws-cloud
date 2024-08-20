resource "aws_security_group" "db" {
  name        = "app-sg-db"
  description = "Allow database traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 3307
    to_port          = 3307
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_db_subnet_group" "db" {
  name = "app-db-subnets"
  subnet_ids = [
    aws_subnet.data_a.id,
    aws_subnet.data_b.id,
  ]
}

resource "aws_rds_cluster" "db" {
  cluster_identifier          = "app-db"
  database_name               = "ecommerce_db"
  availability_zones        = ["ap-northeast-2a", "ap-northeast-2b"]
  db_subnet_group_name = aws_db_subnet_group.db.name
  master_username             = "admin"
  manage_master_user_password = true
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot = true
  engine = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.05.2"
}

resource "aws_rds_cluster_instance" "db" {
  count = 2
  cluster_identifier = aws_rds_cluster.db.id
  instance_class         = "db.t3.medium"
  identifier             = "app-db-${count.index}"
  engine = "aurora-mysql"
}