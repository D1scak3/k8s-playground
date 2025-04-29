#!/bin/bash

# check here: https://github.com/projectcalico/calico/issues/7816#issuecomment-1690033806

# Variables
K3S_CONFIG="~/.kube/k3s"
APISERVER="https://192.168.124.11:6443"  # Adjust if your API server is on a different address

# Extract client certificate and key from k3s config
CLIENT_CERT_DATA=$(grep "client-certificate-data" $K3S_CONFIG | awk '{print $2}')
CLIENT_KEY_DATA=$(grep "client-key-data" $K3S_CONFIG | awk '{print $2}')

# Decode and save to temporary files
echo "$CLIENT_CERT_DATA" | base64 -d > /tmp/client.crt
echo "$CLIENT_KEY_DATA" | base64 -d > /tmp/client.key

# Get list of all nodes
NODES=$(kubectl get nodes -o=jsonpath='{.items[*].metadata.name}')

# Loop through each node
for NODE_NAME in $NODES; do
    # Get the conditions of the node in JSON format
    CONDITIONS=$(kubectl get node $NODE_NAME -o=jsonpath='{.status.conditions}')

    # Check if the node has the NodeNetworkUnavailable condition
    if echo "$CONDITIONS" | grep -q "NetworkUnavailable"; then
        # Determine the index of the NodeNetworkUnavailable condition
        CONDITION_INDEX=$(echo "$CONDITIONS" | jq '. | map(.type) | index("NetworkUnavailable")')

        echo "Patching node: $NODE_NAME at index $CONDITION_INDEX"
        curl --cacert /var/lib/rancher/k3s/server/tls/server-ca.crt \
             --cert /tmp/client.crt \
             --key /tmp/client.key \
             -H "Content-Type: application/json-patch+json" \
             -X PATCH $APISERVER/api/v1/nodes/$NODE_NAME/status \
             --data "[{ \"op\": \"remove\", \"path\": \"/status/conditions/$CONDITION_INDEX\"}]"
    else
        echo "Skipping node: $NODE_NAME as it doesn't have the NodeNetworkUnavailable condition"
    fi
done

# Cleanup temporary files
rm /tmp/client.crt /tmp/client.key

echo "Done patching nodes!"