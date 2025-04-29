# VM Setup

Follow along to setup the VMs, network, and dependencies:

1. VM info
2. Network
3. Dependencies

The VMs are created through `libvirt`.
By default the VMs should be in the `virbr0` network interface, which in turn should be in `bridge` mode by default.

## 1. VM info

Each VM has the following specs:

|  VM   |       IP       |     Distro      | CPUs  |  RAM  | DISK  |
| :---: | :------------: | :-------------: | :---: | :---: | :---: |
| node1 | 192.168.164.11 | Rocky Linux 9.5 |   2   |  3Gb  | 25Gb  |
| node2 | 192.168.164.12 | Rocky Linux 9.5 |   2   |  3Gb  | 25Gb  |
| node3 | 192.168.164.13 | Rocky Linux 9.5 |   2   |  3Gb  | 25Gb  |

After each installation, a `dnf update` is executed to update every package.

## 2. Network

In order for the VMs to reach the outside of your computer, you might need to configure the following components:

1. Static IP
2. `virbr0` network interface for ssh access to VMs
3. Firewall rules for VMs to reach the internet

### 2.1 Static IP

By default, libvirt attributes a random IP from the `default` network, a network used by the `virbr0` interface.

To attribute a static IP, you will need to configure the network to define a specific IP based on the MAC address of the VM.

```bash
# get the mac address of the VM
sudo virsh  dumpxml  <vm-name> | grep 'mac address'

# get list of networks
# it should show the "default" network by default
sudo virsh  net-list
sudo virsh  net-edit  default
```

When editing the config, in the `dhcp` block, add the following lines (with your VMs MAC address and intended IP):

```xml
<network>
  <name>default</name>
  <uuid>0ca24bd7-40fa-4550-9c79-72954b356a52</uuid>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:ef:f2:21'/>
  <ip address='192.168.124.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.124.2' end='192.168.124.254'/>
      <!--From here-->
      <host mac='52:54:00:df:f6:71' name='node1' ip='192.168.124.11'/> 
      <host mac='52:54:00:d4:71:0e' name='node2' ip='192.168.124.12'/>
      <host mac='52:54:00:d7:ae:12' name='node3' ip='192.168.124.13'/>
      <!--To here-->
    </dhcp>
  </ip>
</network>
```
Effectively, what we are doing is telling the DHCP server to assign specific IPs to the computers
that hold specific MAC addresses, as it is not possible to tell a computer to have a specific 
IP since IP attribution is made by the DHCP server.

After updating the config, restart the VMs. 
If the VMs still hold the old IP, shutdown all the VMs, destroy the network and recreate it:

```bash
sudo virsh net-destroy default
sudo virsh net-start default
```

This should solve the problem.
If by any change the problem stands, restart your pc.

### 2.2 `virbr0` network interface

In order  for the host to reach the guest, you will need to enable packet-forwarding and dns-masquing.

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

To enable these settings run the following commands:

```bash
# change settings
sudo firewall-cmd --permanent --zone=libvirt --add-masquerade
sudo firewall-cmd --permanent --zone=libvirt --add-forward
sudo firewall-cmd --reload

# restart daemon to apply changes
sudo systemctl restart libvirtd
```

After this, you should be able to ssh into the VMs (if you configured ssh in the VMs, Rocky can do that in the installation GUI).

### 2.3 Firewall rules for VMs to reach the internet

Virtual machines created with libvirt and QEMU/KVM can connect to the host through the `virbr0` NAT interface,
however, the machines might be unable to access the internet.

To resolve this follow along:

This rule performs NAT for traffic coming from the VM network and going out through the external interface.

```bash
# add masquerade rule for the VM network
# this performs NAT for traffic coming from the VM and going out through the external interface
# Replace wlp0s20f3 with your external network interface
sudo iptables -t nat -A POSTROUTING -s 192.168.124.0/24 -o wlp0s20f3 -j MASQUERADE

# add forward rules to allow traffic between interfaces
# Allow outbound traffic from VM network to external network
sudo iptables -I FORWARD 1 -i virbr0 -o wlp0s20f3 -j ACCEPT

# Allow return traffic from external network back to VM network
sudo iptables -I FORWARD 2 -i wlp0s20f3 -o virbr0 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

Make the rules permanent with `firewall-cmd`:

```bash
# Add persistent MASQUERADE rule
sudo firewall-cmd --permanent --direct --add-rule ipv4 nat POSTROUTING 0 -s 192.168.124.0/24 -o wlp0s20f3 -j MASQUERADE

# Add persistent FORWARD rules
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i virbr0 -o wlp0s20f3 -j ACCEPT
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 1 -i wlp0s20f3 -o virbr0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Apply the changes
sudo firewall-cmd --reload
```

Make sure packet forwarding is enabled at the kernel level:

```bash
# Check current status
sysctl net.ipv4.ip_forward

# Enable if needed value was 0
sudo sysctl -w net.ipv4.ip_forward=1

# Make persistent
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-ipforward.conf
```

Finally, after applying these changes, test connectivity from within the VM:

  ```bash
  # Test basic connectivity
  ping -c 4 8.8.8.8

  # Test DNS resolution
  ping -c 4 google.com

  # Check routing
  tracepath 8.8.8.8
  ```

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
  <host mac="52:54:00:b0:50:22" name="node1" ip="192.168.124.11"/>
  <host mac="52:54:00:d4:71:0e" name="node2" ip="192.168.124.12"/>
  <host mac="52:54:00:d7:ae:12" name="node3" ip="192.168.124.13"/>
```

### Gnome Boxes (WIP...)

Gnome Boxes attributes a random IP address to the VMs inside the possible default range of the virbr0 interface.
This is not ideal for Kuberentes nodes, a single change to the IP of a node can lead to catastrophic consequences in the cluster.

To overcome this, a new static IP will be given to the VMs.

```bash
# retrive the current IPs and MAC address of the VMs
sudo cat /var/lib/libvirt/dnsmasq/virbr0.status

# TODO
```