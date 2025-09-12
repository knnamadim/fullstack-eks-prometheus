## Pulsar EKS Fullstack Deployment

This project deploys a complete Apache Pulsar stack on AWS EKS with integrated monitoring (Prometheus + Grafana), logging (ELK + Filebeat), and sample producer/consumer apps using Terraform and Helm.

## Project Structure

pulsar-eks-fullstack/
├── README.md
├── terraform/
│   ├── provider.tf
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── helm-values/
│   ├── pulsar-values.yaml
│   ├── prometheus-values.yaml
│   ├── filebeat-values.yaml
│   ├── producer-values.yaml
│   └── consumer-values.yaml
└── k8s-manifests/
    ├── elasticsearch-kibana.yaml
    ├── filebeat-configmap.yaml
    └── filebeat-daemonset.yaml

----
## Components Deployed
- EKS Cluster – Managed Kubernetes cluster on AWS.
- Pulsar – Deployed with sn-platform Helm chart.
- Prometheus + Grafana – For cluster and Pulsar metrics.
- ELK Stack (Elasticsearch + Kibana) – For centralized logging.
- Filebeat DaemonSet – Collects container logs and ships them to Elasticsearch.
- Pulsar Producer & Consumer – Sample apps deployed with custom Helm charts.

## Prerequisites
- Terraform ≥ 1.6
- kubectl
- Helm ≥ 3
- AWS CLI configured with IAM user/role for EKS + VPC provisioning.

----
## Deployment steps:

1. Clone the repo
git clone https://github.com/your-repo/pulsar-eks-fullstack.git
cd pulsar-eks-fullstack/terraform

2. Initialize Terraform
terraform init

3. Apply Terraform (creates EKS + deploys all components)
terraform apply -auto-approve

4. Update kubeconfig
aws eks --region us-east-1 update-kubeconfig --name pulsar-monitoring
kubectl get nodes

5. Verify deployments
kubectl get pods -n pulsar
kubectl get pods -n monitoring
kubectl get pods -n logging

## Accessing Dashboards - Grafana
kubectl get svc -n monitoring
Notes: 
Find the LoadBalancer service for Grafana.
Default credentials: admin/prom-operator.

## Accessing Dashboards - Kibana
kubectl get svc -n logging
Notes: 
- kubectl get svc -n logging

## Producer/ Consumer Logs
kubectl logs -f deployment/producer -n pulsar
kubectl logs -f deployment/consumer -n pulsar

Notes:
- Check sample apps in pulsar namespace

## Cleanup - Destroy all resources
cd terraform
terraform destroy -auto-approve

## Future Improvements
- Add CI/CD pipeline to build & push producer/consumer images to ECR.
- Enable HPA (Horizontal Pod Autoscaling) for Pulsar brokers.
- Add alerting rules in Prometheus + Grafana.
