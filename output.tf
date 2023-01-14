output "eks-endpoint" {
  value = aws_eks_cluster.myeks.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.myeks.certificate_authority[0].data
}