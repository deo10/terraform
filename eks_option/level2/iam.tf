resource "aws_iam_role" "cluster" {
  name = var.cluster_name

  assume_role_policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
        {
         "Effect": "Allow",
         "Principal": {
            "Service": "eks.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
        }
    ]
  }
POLICY
}

resource "aws_iam_role_policy_attachment" "aws_eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "aws_eks_service" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role = aws_iam_role.cluster.name
}

resource "aws_iam_role" "managed_nodes" {
  name = "managed-node-group"

  assume_role_policy = jsondecode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_eks_worker_node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.managed_nodes.name
}

resource "aws_iam_role_policy_attachment" "aws_ec2_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPolicy"
  role = aws_iam_role.managed_nodes.name
}

resource "aws_iam_role_policy_attachment" "aws_eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.managed_nodes.name
}