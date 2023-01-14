resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "main-${var.env}"
    Environment = var.env
  }
}

resource "aws_subnet" "private" {
  for_each = {
    for subnet in local.private_nested_config : "${subnet.name}" => subnet
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = {
    Environment                       = var.env
    Name                              = "${each.value.name}-${var.env}"
    "kubernetes.io/role/internal-elb" = each.value.eks ? "1" : ""
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_subnet" "public" {
  for_each = {
    for subnet in local.public_nested_config : "${subnet.name}" => subnet
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Environment              = var.env
    Name                     = "${each.value.name}-${var.env}"
    "kubernetes.io/role/elb" = each.value.eks ? "1" : ""
  }

  lifecycle {
    ignore_changes = [tags]
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Environment = var.env
    Name        = "igw-${var.env}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Environment = var.env
    Name        = "rt-public-${var.env}"
  }
}

resource "aws_route_table_association" "public" {
  for_each = {
    for subnet in local.public_nested_config : "${subnet.name}" => subnet
  }

  subnet_id      = aws_subnet.public[each.value.name].id
  route_table_id = aws_route_table.public.id
}


#==============NAT-GATEWAY===============

resource "aws_eip" "nat" {
  for_each = {
    for subnet in local.public_nested_config : "${subnet.name}" => subnet
    if subnet.nat_gw == true
  }

  vpc = true

  tags = {
    Environment = var.env
    Name        = "eip-${each.value.name}-${var.env}"
  }
}

resource "aws_nat_gateway" "nat-gw" {
  for_each = {
    for subnet in local.public_nested_config : "${subnet.name}" => subnet
    if subnet.nat_gw == true
  }

  allocation_id = aws_eip.nat[each.value.name].id
  subnet_id     = aws_subnet.public[each.value.name].id

  tags = {
    Environment = var.env
    Name        = "nat-${each.value.name}-${var.env}"
  }
}

resource "aws_route_table" "private" {
  for_each = {
    for subnet in local.public_nested_config : "${subnet.name}" => subnet
    if subnet.nat_gw == true
  }

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw[each.value.name].id
  }

  tags = {
    Environment = var.env
    Name        = "rt-${each.value.name}-${var.env}"
  }
}

resource "aws_route_table_association" "private" {

  for_each = {
    for subnet in local.private_nested_config : "${subnet.name}" => subnet
    if subnet.associated_public_subnet != ""
  }

  subnet_id      = aws_subnet.private[each.value.name].id
  route_table_id = aws_route_table.private[each.value.associated_public_subnet].id
}