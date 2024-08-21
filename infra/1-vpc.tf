resource "aws_vpc" "main" {
  cidr_block = "10.100.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "app-vpc"
  }
}

// public

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "app-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "app-public-rt"
  }
}

resource "aws_route" "public" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}

resource "aws_route" "app_to_host" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = aws_vpc.host.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.main_to_host.id
}

resource "aws_subnet" "public_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.100.2.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "app-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.100.3.0/24"
  availability_zone = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "app-public-b"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

// private

resource "aws_eip" "private_a" {
  
}

resource "aws_eip" "private_b" {
  
}

resource "aws_nat_gateway" "private_a" {
  depends_on = [aws_internet_gateway.main]

  allocation_id = aws_eip.private_a.id
  subnet_id = aws_subnet.public_a.id

  tags = {
    Name = "app-natgw-a"
  }
}

resource "aws_nat_gateway" "private_b" {
  depends_on = [aws_internet_gateway.main]

  allocation_id = aws_eip.private_b.id
  subnet_id = aws_subnet.public_b.id

  tags = {
    Name = "app-natgw-b"
  }
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "app-private-a-rt"
  }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "app-private-b-rt"
  }
}

resource "aws_route" "private_a" {
  route_table_id = aws_route_table.private_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.private_a.id
}

resource "aws_route" "app_a_private_to_host" {
  route_table_id            = aws_route_table.private_a.id
  destination_cidr_block    = aws_vpc.host.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.main_to_host.id
}

resource "aws_route" "private_b" {
  route_table_id = aws_route_table.private_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.private_b.id
}

resource "aws_route" "app_b_private_to_host" {
  route_table_id            = aws_route_table.private_b.id
  destination_cidr_block    = aws_vpc.host.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.main_to_host.id
}

resource "aws_subnet" "private_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.100.0.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "app-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.100.1.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "app-private-b"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

// database

resource "aws_route_table" "data" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "app-data-rt"
  }
}

resource "aws_subnet" "data_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.100.4.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "app-data-a"
  }
}

resource "aws_subnet" "data_b" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.100.5.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "app-data-a"
  }
}

resource "aws_route" "data_to_host" {
  route_table_id            = aws_route_table.data.id
  destination_cidr_block    = aws_vpc.host.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.main_to_host.id
}

resource "aws_route_table_association" "data_a" {
  subnet_id = aws_subnet.data_a.id
  route_table_id = aws_route_table.data.id
}

resource "aws_route_table_association" "data_b" {
  subnet_id = aws_subnet.data_b.id
  route_table_id = aws_route_table.data.id
}