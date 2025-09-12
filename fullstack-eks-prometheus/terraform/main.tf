# --- EKS Cluster ---
data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" { cidr_block = "10.0.0.0/16" }

resource "aws_subnet" "public" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = "1.28"
  subnets         = aws_subnet.public[*].id
  vpc_id          = aws_vpc.main.id
  node_groups = {
    pulsar_nodes = {
      desired_capacity = 3
      max_capacity     = 5
      min_capacity     = 3
      instance_type    = var.node_instance_type
    }
  }
}

# --- Helm: Pulsar ---
resource "helm_release" "pulsar" {
  name       = "sn-platform"
  namespace  = "pulsar"
  repository = "https://charts.streamnative.io"
  chart      = "sn-platform"
  version    = "1.11.4"
  values     = [file("${path.module}/../helm-values/pulsar-values.yaml")]
}

# --- Helm: Prometheus + Grafana ---
resource "helm_release" "prometheus" {
  name       = "kube-prometheus-stack"
  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "45.0.0"
  values     = [file("${path.module}/../helm-values/prometheus-values.yaml")]
}

# --- Kubernetes: ELK Stack ---
resource "kubernetes_namespace" "logging" { metadata { name = "logging" } }

resource "kubernetes_manifest" "elasticsearch_kibana" {
  manifest = yamldecode(file("${path.module}/../k8s-manifests/elasticsearch-kibana.yaml"))
}

resource "kubernetes_config_map" "filebeat" {
  metadata { name = "filebeat-config" namespace = "logging" }
  data = { "filebeat.yml" = file("${path.module}/../helm-values/filebeat-values.yaml") }
}

resource "kubernetes_manifest" "filebeat_daemonset" {
  manifest = yamldecode(file("${path.module}/../k8s-manifests/filebeat-daemonset.yaml"))
}

# --- Helm: Pulsar Producer ---
resource "helm_release" "producer" {
  name       = "producer"
  namespace  = "pulsar"
  chart      = "${path.module}/../helm-values/producer"
  values     = [file("${path.module}/../helm-values/producer-values.yaml")]
}

# --- Helm: Pulsar Consumer ---
resource "helm_release" "consumer" {
  name       = "consumer"
  namespace  = "pulsar"
  chart      = "${path.module}/../helm-values/consumer"
  values     = [file("${path.module}/../helm-values/consumer-values.yaml")]
}
