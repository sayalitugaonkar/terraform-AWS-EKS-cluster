## create custom VPC
resource "aws_vpc" "main-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "prod"
  }
}


## create public subnets

resource "aws_subnet" "public_subnets" {

 count      = length(var.public_subnet_cidrs)

 vpc_id     = aws_vpc.main-vpc.id

 cidr_block = element(var.public_subnet_cidrs, count.index)
 
 map_public_ip_on_launch = "true"
 tags = {

   Name = "Public Subnet ${count.index + 1}"

 }

}

 ## create public subnets

resource "aws_subnet" "private_subnets" {

 count      = length(var.private_subnet_cidrs)

 vpc_id     = aws_vpc.main-vpc.id

 cidr_block = element(var.private_subnet_cidrs, count.index)

 tags = {

   Name = "Private Subnet ${count.index + 1}"

 }

}

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.main-vpc.id
  tags = {
    Name = "aws_internet_gateway-igw"
  }
}

resource "aws_route_table" "public-crt" {


  vpc_id = aws_vpc.main-vpc.id

  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0" //CRT uses this IGW to reach internet
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "prod-public-rt"
  }
}

#Associate CRT and Subnet
resource "aws_route_table_association" "crta-public-subnet-1" {

  count = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.public-crt.id
}


resource "aws_eip" "nat-gateway-eip" {

  depends_on = [
    aws_route_table_association.crta-public-subnet-1
  ]
  domain = "vpc"
}

resource "aws_nat_gateway" "ngw" {
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.

  depends_on = [
    aws_eip.nat-gateway-eip,
    aws_internet_gateway.igw
  ]
  allocation_id = aws_eip.nat-gateway-eip.id

  subnet_id = aws_subnet.private_subnets[0].id


  tags = {
    Name = "prod-gw-NAT"
  }

}


# Creating a Route Table for the Nat Gateway!
resource "aws_route_table" "NAT-Gateway-RT" {

  depends_on = [
    aws_nat_gateway.ngw
  ]

  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "prod-RT-NAT"
  }

}

# Associating the Route table for NAT Gateway to private Subnet!
# Creating an Route Table Association of the NAT Gateway route 
# table with the Private Subnet!
resource "aws_route_table_association" "Nat-Gateway-RT-Association" {

  depends_on = [
    aws_route_table.NAT-Gateway-RT
  ]

  #  Private Subnet ID for adding this route table to the DHCP server of Private subnet!

  count = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  # Route Table ID
  route_table_id = aws_route_table.NAT-Gateway-RT.id
}