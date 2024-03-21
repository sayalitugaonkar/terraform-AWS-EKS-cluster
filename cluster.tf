data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_cluster-role" {
  name               = "eks_cluster-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster-role-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster-role.name
}


resource "aws_iam_role_policy_attachment" "eks_cluster-role-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster-role.name
}

###aws_eks_cluster
resource "aws_eks_cluster" "EKS-Cluster" {
  name     = "EKS-Cluster"
  role_arn = aws_iam_role.eks_cluster-role.arn

  vpc_config {
    subnet_ids = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id, aws_subnet.public_subnets[2].id, aws_subnet.private_subnets[0].id, aws_subnet.private_subnets[1].id, aws_subnet.private_subnets[2].id]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster-role-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster-role-AmazonEKSVPCResourceController,
  ]
}

###aws_eks_node_group

resource "aws_iam_role" "EKS_node-group" {
  name = "eks-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "EKS_node-group-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.EKS_node-group.name
}

resource "aws_iam_role_policy_attachment" "EKS_node-group-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.EKS_node-group.name
}

resource "aws_iam_role_policy_attachment" "EKS_node-group-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.EKS_node-group.name
}



resource "aws_eks_node_group" "EKS" {
  cluster_name    = aws_eks_cluster.EKS-Cluster.name
  node_group_name = "EKS"
  node_role_arn   = aws_iam_role.EKS_node-group.arn
  subnet_ids      = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id, aws_subnet.public_subnets[2].id]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.EKS_node-group-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.EKS_node-group-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.EKS_node-group-AmazonEC2ContainerRegistryReadOnly,
  ]
}

