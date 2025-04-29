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