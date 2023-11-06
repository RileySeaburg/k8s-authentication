#!/bin/bash

# Define variables
NAMESPACE="quantumforge-platform"
SERVICE_ACCOUNT_NAME="quantumforge-service-account"
CLUSTER_ROLE_NAME="quantumforge-cluster-role"
CLUSTER_ROLE_BINDING_NAME="quantumforge-cluster-role-binding"

# Create Namespace if it doesn't exist
kubectl get namespace "$NAMESPACE" &> /dev/null || kubectl create namespace "$NAMESPACE"

# Create or replace the ServiceAccount in the specified Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $SERVICE_ACCOUNT_NAME
  namespace: $NAMESPACE
EOF

# Create or replace the ClusterRole
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: $CLUSTER_ROLE_NAME
rules:
- apiGroups: ["", "apps", "extensions", "networking.k8s.io"]
  resources: ["deployments", "replicasets", "pods", "services", "ingresses"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
EOF

# Create or replace the ClusterRoleBinding
kubectl apply -f - <<EOF
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

# Wait for the Secret associated with the ServiceAccount to be created
echo "Waiting for ServiceAccount secret to be created..."
for ((i=0; i<10; i++)); do
  SERVICE_ACCOUNT_SECRET_NAME=$(kubectl get serviceaccount "$SERVICE_ACCOUNT_NAME" --namespace "$NAMESPACE" -o jsonpath='{.secrets[0].name}' --ignore-not-found)
  if [ ! -z "$SERVICE_ACCOUNT_SECRET_NAME" ]; then
    echo "Found secret: $SERVICE_ACCOUNT_SECRET_NAME"
    break
  fi
  echo "Secret not ready yet, waiting..."
  sleep 1
done

if [ -z "$SERVICE_ACCOUNT_SECRET_NAME" ]; then
  echo "Failed to find the secret for ServiceAccount $SERVICE_ACCOUNT_NAME in namespace $NAMESPACE after waiting 10 seconds."
  exit 1
fi

# Retrieve the ServiceAccount token
TOKEN=$(kubectl get secret "$SERVICE_ACCOUNT_SECRET_NAME" --namespace "$NAMESPACE" -o jsonpath='{.data.token}' | base64 --decode)

if [ -z "$TOKEN" ]; then
  echo "Failed to retrieve the token for ServiceAccount $SERVICE_ACCOUNT_NAME. Exiting."
  exit 1
fi

# Output the token
echo "Service Account Token: $TOKEN"
