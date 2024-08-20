resource "aws_vpc" "host" {
  cidr_block = "10.100.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "host-vpc"
  }
}

// public

resource "aws_internet_gateway" "host" {
  vpc_id = aws_vpc.host.id

  tags = {
    Name = "host-igw"
  }
}

resource "aws_route_table" "host_public" {
  vpc_id = aws_vpc.host.id

  tags = {
    Name = "host-public-rt"
  }
}

resource "aws_route" "host_public" {
  route_table_id = aws_route_table.host_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.host.id
}

resource "aws_subnet" "host_public_a" {
  vpc_id = aws_vpc.host.id
  cidr_block = "10.100.2.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "app-public-a"
  }
}

resource "aws_subnet" "host_public_b" {
  vpc_id = aws_vpc.host.id
  cidr_block = "10.100.3.0/24"
  availability_zone = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "app-public-b"
  }
}

resource "aws_route_table_association" "host_public_a" {
  subnet_id = aws_subnet.public_a.id
  route_table_id = aws_route_table.host_public.id
}

resource "aws_route_table_association" "hostpublic_b" {
  subnet_id = aws_subnet.public_b.id
  route_table_id = aws_route_table.host_public.id
}