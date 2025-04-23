# VM setup

The VMs are created through Gnome Boxes.
By default the VMs should be in the `virbr0` network interface, which in turn should be in `bridge` mode by default.

## DNS masqing and Packet forwarding for SSH

It might happen however, that the `virbr0` interface has dns masquing and packet forwarding disabled by default.
To check this run the following command:

```bash
sudo firewall-cmd --list-all --zone=libvirt

# output of the command should be something like this
libvirt (active)
  target: ACCEPT
  ingress-priority: 0
  egress-priority: 0
  icmp-block-inversion: no
  interfaces: virbr0
  sources: 
  services: dhcp dhcpv6 dns ssh tftp
  ports: 
  protocols: icmp ipv6-icmp
  forward: no   # <--- this
  masquerade: no    # <--- and this
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
    rule priority="32767" reject
```

To enable these settings run the following command:

```bash
# change settings
sudo firewall-cmd --permanent --zone=libvirt --add-masquerade
sudo firewall-cmd --permanent --zone=libvirt --add-forward
sudo firewall-cmd --reload

# restart daemon to apply changes
sudo systemctl restart libvirtd
```

## KVM/QEMU Virtual Machine Internet Connectivity Fix

Virtual machines created with libvirt and QEMU/KVM can connect to the host through the virbr0 NAT interface but cannot access the internet.

### Root Causes
1. Missing MASQUERADE rule for the VM network in the POSTROUTING chain
2. Missing FORWARD rules to allow traffic between VM network interface and external interface
3. Default DROP policy on the FORWARD chain blocking inter-interface traffic

### Solution

#### 1. Add MASQUERADE rule for the VM network
This rule performs NAT for traffic coming from the VM network and going out through the external interface.

```bash
# Replace wlp0s20f3 with your external network interface
sudo iptables -t nat -A POSTROUTING -s 192.168.124.0/24 -o wlp0s20f3 -j MASQUERADE
```

#### 2. Add FORWARD rules to allow traffic between interfaces
These rules allow traffic to flow from the VM network to the external network and vice versa.

```bash
# Allow outbound traffic from VM network to external network
sudo iptables -I FORWARD 1 -i virbr0 -o wlp0s20f3 -j ACCEPT

# Allow return traffic from external network back to VM network
sudo iptables -I FORWARD 2 -i wlp0s20f3 -o virbr0 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

#### 3. Make the rules persistent using firewalld
To ensure rules survive system reboots:

```bash
# Add persistent MASQUERADE rule
sudo firewall-cmd --permanent --direct --add-rule ipv4 nat POSTROUTING 0 -s 192.168.124.0/24 -o wlp0s20f3 -j MASQUERADE

# Add persistent FORWARD rules
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i virbr0 -o wlp0s20f3 -j ACCEPT
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 1 -i wlp0s20f3 -o virbr0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Apply the changes
sudo firewall-cmd --reload
```

#### 4. Verify IP forwarding is enabled
Make sure packet forwarding is enabled at the kernel level:

```bash
# Check current status
sysctl net.ipv4.ip_forward

# Enable if needed
sudo sysctl -w net.ipv4.ip_forward=1

# Make persistent
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-ipforward.conf
```

### Verification
After applying these changes, test connectivity from within the VM:

```bash
# Test basic connectivity
ping -c 4 8.8.8.8

# Test DNS resolution
ping -c 4 google.com

# Check routing
traceroute 8.8.8.8
```

If SELinux is causing issues, you may need to set it to permissive mode temporarily for testing:

```bash
sudo setenforce 0
```

Remember to set it back to enforcing mode after confirming the solution works.


## Give VMs a static IP

### Libvirt

Libvirt also attributes a random IP address to the VMs inside the `default` range of the birbr0 interface.

To overcome this, a new static IP will be attributed to each VM:

```bash
# retrive the mac address of each VM using the VM's name
sudo virsh dumpxml <vm-name> | grep "mac address"
```

After retrieving the mac address of all the VMs, we will need to edit the 


```xml
  <host mac="52:54:00:df:f6:71" name="node1" ip="192.168.124.11"/>
  <host mac="52:54:00:d4:71:0e" name="node2" ip="192.168.124.12"/>
  <host mac="52:54:00:d7:ae:12" name="node3" ip="192.168.124.13"/>
```

### Gnome Boxes

Gnome Boxes attributes a random IP address to the VMs inside the possible default range of the virbr0 interface.
This is not ideal for Kuberentes nodes, a single change to the IP of a node can lead to catastrophic consequences in the cluster.

To overcome this, a new static IP will be given to the VMs.

```bash
# retrive the current IPs and MAC address of the VMs
sudo cat /var/lib/libvirt/dnsmasq/virbr0.status

# TODO
```