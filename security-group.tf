resource "aws_security_group" "eks_cluster" {
  name        = "${var.EKS_CLUSTER_NAME}-${var.env}/ControlPlaneSecurityGroup"
  description = "Communication between the control plane and worker nodegroups"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.EKS_CLUSTER_NAME}-${var.env}/ControlPlaneSecurityGroup"
    Environment = var.env
  }
}

resource "aws_security_group_rule" "cluster_inbound" {
  description              = "Allow unmanaged nodes to communicate with control plane (all ports)"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_eks_cluster.myeks.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.eks_nodes_sec.id
  to_port                  = 0
  type                     = "ingress"
}

#==========================NodeGroup-Security-Group================================

resource "aws_security_group" "eks_nodes_sec" {
  name        = "${var.EKS_CLUSTER_NAME}-${var.env}/ClusterSharedNodeSecurityGroup"
  description = "Communication between all nodes in the cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_eks_cluster.myeks.vpc_config[0].cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.EKS_CLUSTER_NAME}-${var.env}/ClusterSharedNodeSecurityGroup"
    Environment = var.env
  }
}