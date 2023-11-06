#!/bin/bash

# Define variables
NAMESPACE="quantumforge-platform"
SERVICE_ACCOUNT_NAME="quantumforge-service-account"
CLUSTER_ROLE_NAME="quantumforge-cluster-role"
CLUSTER_ROLE_BINDING_NAME="quantumforge-cluster-role-binding"

# Create Namespace if it doesn't exist
kubectl get namespace "$NAMESPACE" &> /dev/null || kubectl create namespace "$NAMESPACE"

# Create the ServiceAccount in the specified Namespace
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

# Wait for the ServiceAccount secret to be created
SECRETS_CHECK_INTERVAL=5
SECRETS_MAX_CHECKS=10
CURRENT_CHECK=0

echo "Waiting for the ServiceAccount secret to be created..."

while [[ -z "$SERVICE_ACCOUNT_SECRET_NAME" && $CURRENT_CHECK -lt $SECRETS_MAX_CHECKS ]]; do
  SERVICE_ACCOUNT_SECRET_NAME=$(kubectl get serviceaccount "$SERVICE_ACCOUNT_NAME" --namespace "$NAMESPACE" -o jsonpath='{.secrets[0].name}')
  if [[ -z "$SERVICE_ACCOUNT_SECRET_NAME" ]]; then
    sleep $SECRETS_CHECK_INTERVAL
    let CURRENT_CHECK=CURRENT_CHECK+1
  fi
done

if [[ -z "$SERVICE_ACCOUNT_SECRET_NAME" ]]; then
  echo "Service Account secret not found. Exiting."
  exit 1
fi

echo "Service Account secret found: $SERVICE_ACCOUNT_SECRET_NAME"

# Get the ServiceAccount token
TOKEN=$(kubectl get secret "$SERVICE_ACCOUNT_SECRET_NAME" --namespace "$NAMESPACE" -o jsonpath='{.data.token}' | base64 --decode)

# Output the token
echo "Service Account Token: $TOKEN"
