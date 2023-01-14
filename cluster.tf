resource "aws_eks_cluster" "myeks" {
  name     = "${var.EKS_CLUSTER_NAME}-${var.env}"
  role_arn = aws_iam_role.eks.arn
  #version  = 1.20

  vpc_config {
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = [var.internal_ip_range]
    subnet_ids              = [aws_subnet.private["private-1"].id, aws_subnet.private["private-2"].id, aws_subnet.public["public-1"].id, aws_subnet.public["public-2"].id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.eks-AmazonEKSServicePolicy
  ]

  tags = {
    Environment = var.env
  }
}


#==================NodeGroup======================================

resource "aws_eks_node_group" "private" {
  cluster_name    = aws_eks_cluster.myeks.name
  node_group_name = "private-node-group-${var.env}"
  node_role_arn   = aws_iam_role.node-group-role.arn
  subnet_ids      = [aws_subnet.private["private-1"].id, aws_subnet.private["private-2"].id]

  labels = {
    "type" = "private"
  }

  instance_types = ["t3.small"]
  disk_size      = 25 # default 20G

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node-group-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-group-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-group-AmazonEC2ContainerRegistryReadOnly
  ]

  tags = {
    Environment = var.env
  }
}

resource "aws_eks_node_group" "public" {
  cluster_name    = aws_eks_cluster.myeks.name
  node_group_name = "public-node-group-${var.env}"
  node_role_arn   = aws_iam_role.node-group-role.arn
  subnet_ids      = [aws_subnet.public["public-1"].id, aws_subnet.public["public-2"].id]

  labels = {
    "type" = "public"
  }

  instance_types = ["t3.small"]
  disk_size      = 25 # default 20G

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node-group-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-group-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-group-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Environment = var.env
  }
}