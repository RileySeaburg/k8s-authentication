#!/bin/bash

# Define variables
NAMESPACE="quantumforge-platform"
SERVICE_ACCOUNT_NAME="quantumforge-service-account"
CLUSTER_ROLE_NAME="quantumforge-cluster-role"
CLUSTER_ROLE_BINDING_NAME="quantumforge-cluster-role-binding"

# Create Namespace if it doesn't exist
kubectl get namespace "$NAMESPACE" &> /dev/null || kubectl create namespace "$NAMESPACE"

# Delete the existing ServiceAccount if it exists and recreate it
kubectl delete serviceaccount "$SERVICE_ACCOUNT_NAME" --namespace "$NAMESPACE" --ignore-not-found
kubectl create serviceaccount "$SERVICE_ACCOUNT_NAME" --namespace "$NAMESPACE"

# Create the ClusterRole
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: $CLUSTER_ROLE_NAME
rules:
- apiGroups: ["", "apps", "extensions", "networking.k8s.io"]
  resources: ["deployments", "replicasets", "pods", "services", "ingresses"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
EOF

# Create the ClusterRoleBinding
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $CLUSTER_ROLE_BINDING_NAME
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: $CLUSTER_ROLE_NAME
subjects:
- kind: ServiceAccount
  name: $SERVICE_ACCOUNT_NAME
  namespace: $NAMESPACE
EOF

# Wait for the secret associated with the ServiceAccount to be created by the control plane
sleep 5

# Get the ServiceAccount token
SERVICE_ACCOUNT_SECRET_NAME=$(kubectl get serviceaccount "$SERVICE_ACCOUNT_NAME" --namespace "$NAMESPACE" -o jsonpath='{.secrets[0].name}')
TOKEN=$(kubectl get secret "$SERVICE_ACCOUNT_SECRET_NAME" --namespace "$NAMESPACE" -o jsonpath='{.data.token}' | base64 --decode)

# Output the token
echo "Service Account Token: $TOKEN"
