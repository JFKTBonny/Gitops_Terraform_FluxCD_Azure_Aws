##creating network infrastructure, internet and nat gateways and route tables
#create internet gateway
resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.cluster_vpc.id
  tags = {
    Name = "cluster-internet-gateway"
  }
}
#create route for internet gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.cluster_vpc.id
  route {
    #going to internet use internet gateway
    cidr_block = var.cidr_blocks["internet"]
    gateway_id = aws_internet_gateway.internet_gw.id
  }
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_rt_a" {
  #associate public route to public subnet
  subnet_id      =  aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
  count=2
}

#nat gateway eip
resource "aws_eip" "eip" {
  domain = "vpc"
  tags = {
    Name = "eip"
  }
}

#create nat gateway in the public subnet
resource "aws_nat_gateway" "natgw" {
  subnet_id     = aws_subnet.public_subnets[0].id
  allocation_id = aws_eip.eip.id
  tags = {
    Name = "nat-gateway"
  }
  depends_on = [aws_internet_gateway.internet_gw]
}

resource "aws_route_table" "private_rt" {
  #internet go to nat gateway
  vpc_id = aws_vpc.cluster_vpc.id
  route {
    cidr_block     = var.cidr_blocks["internet"]
    nat_gateway_id = aws_nat_gateway.natgw.id
  }
  tags = {
    Name = "private-rt"
  }
}
resource "aws_route_table_association" "internal_rt_a" {
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
  count = 2
}