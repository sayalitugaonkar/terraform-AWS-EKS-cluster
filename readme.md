# Terraform EKS creation demo

Amazon Elastic Kubernetes Service (Amazon EKS) is a managed service that eliminates the need to install, operate, and maintain your own Kubernetes control plane on Amazon Web Services (AWS). Kubernetes is an open-source system that automates the management, scaling, and deployment of containerized applications.

This project demonstrates creation EKS cluster and node group

Automation is done using Terraform

### vpc.tf

It creats custom VPC for the EKS cluster.

Details of subnets are fetched via variables defined in `variables.tf`

### cluster.tf

- creates AWS EKS cluster IAM role with required trust policy for the cluster
- creates EKS cluster
- creates EKS node IAM role with required policies attached `AmazonEKSWorkerNodePolicy, AmazonEC2ContainerRegistryReadOnly, AmazonEKS_CNI_Policy`
- creates node group