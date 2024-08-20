resource "aws_vpc_peering_connection" "main_to_host" {
  vpc_id        = aws_vpc.main.id
  peer_vpc_id   = aws_vpc.host.id
  auto_accept   = false
  
  tags = {
    Name = "app-main-to-host-peering"
  }
}

resource "aws_vpc_peering_connection_accepter" "host_accept_main" {
  vpc_peering_connection_id = aws_vpc_peering_connection.main_to_host.id
  auto_accept               = true
  vpc_id                    = aws_vpc.host.id

  tags = {
    Name = "app-host-accept-main-peering"
  }
}