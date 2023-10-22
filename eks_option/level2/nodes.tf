resource "aws_eks_node_group" "this" {
  cluster_name = aws_eks_cluster.this.name
  node_group_name = "${aws_eks_cluster.this.name}-worker"
  node_role_arn = aws_iam_role.managed_nodes.arn
  subnet_ids = data.terraform_remote_state.level1.outputs.private_subnet_ids
  ami_type = "AL2_x86_64"
  capacity_type = "ON_DEMAND"
  disk_size = 30
  instance_types = ["t3.medium"]

  scaling_config {
    min_size = 3
    max_size = 3
    desired_size = 3
  }
}