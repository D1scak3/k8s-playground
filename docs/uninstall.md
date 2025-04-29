# Unistall

## Removing Network

```bash
# Remove the FORWARD rules
sudo iptables -D FORWARD -i virbr0 -o wlp0s20f3 -j ACCEPT
sudo iptables -D FORWARD -i wlp0s20f3 -o virbr0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Remove the MASQUERADE rule
sudo iptables -t nat -D POSTROUTING -s 192.168.124.0/24 -o wlp0s20f3 -j MASQUERADE

# Remove the persistent MASQUERADE rule
sudo firewall-cmd --permanent --direct --remove-rule ipv4 nat POSTROUTING 0 -s 192.168.124.0/24 -o wlp0s20f3 -j MASQUERADE

# Remove the persistent FORWARD rules
sudo firewall-cmd --permanent --direct --remove-rule ipv4 filter FORWARD 0 -i virbr0 -o wlp0s20f3 -j ACCEPT
sudo firewall-cmd --permanent --direct --remove-rule ipv4 filter FORWARD 1 -i wlp0s20f3 -o virbr0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Apply the changes
sudo firewall-cmd --reload
```

## Removing Calico

Check this [GitHub comment](https://github.com/projectcalico/calico/issues/7816#issuecomment-1690033806) for more information.

Run from a place where you can access the VM and have the kubeconfig:

```bash
#!/bin/bash

# Variables
K3S_CONFIG="/etc/rancher/k3s/k3s.yaml"
APISERVER="https://127.0.0.1:6443"  # Adjust if your API server is on a different address

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
```

Run on the server nodes:

```bash
ip route flush proto bird
ip link list | grep cali | awk '{print $2}' | cut -c 1-15 | xargs -I {} ip link delete {}
modprobe -r ipip
rm /etc/cni/net.d/10-calico.conflist && rm /etc/cni/net.d/calico-kubeconfig
systemctl restart k3s
```

Run on the agent nodes:

```bash
ip route flush proto bird
ip link list | grep cali | awk '{print $2}' | cut -c 1-15 | xargs -I {} ip link delete {}
modprobe -r ipip
rm /etc/cni/net.d/10-calico.conflist && rm /etc/cni/net.d/calico-kubeconfig
systemctl restart k3s-agent
```
