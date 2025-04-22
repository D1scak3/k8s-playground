# VM setup

The VMs are created through Gnome Boxes.
By default the VMs should be in the `virbr0` network interface, which in turn should be in `bridge` mode by default.

## DNS masqing and Packet forwarding

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