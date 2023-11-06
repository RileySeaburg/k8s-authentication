#!/bin/bash

# Define variables
NAMESPACE="mynamespace"
SERVICE_ACCOUNT_NAME="myserviceaccount"
CLUSTER_ROLE_NAME="myclusterrole"
CLUSTER_ROLE_BINDING_NAME="myclusterrolebinding"

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
  resources: ["deployments", "services", "ingresses", "pods"]
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

# Get the ServiceAccount token
SERVICE_ACCOUNT_SECRET_NAME=$(kubectl get serviceaccount "$SERVICE_ACCOUNT_NAME" --namespace "$NAMESPACE" -o jsonpath='{.secrets[0].name}')
TOKEN=$(kubectl get secret "$SERVICE_ACCOUNT_SECRET_NAME" --namespace "$NAMESPACE" -o jsonpath='{.data.token}' | base64 --decode)

# Output the token
echo "Service Account Token: $TOKEN"
