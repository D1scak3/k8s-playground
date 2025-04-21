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

Gnome Boxes attributes a random IP address to the VMs inside the possible default range of the virbr0 interface.
This is not ideal for Kuberentes nodes, a single change to the IP of a node can lead to catastrophic consequences in the cluster.

To overcome this, a new static IP will be given to the VMs.

```bash
# retrive the current IPs and MAC address of the VMs
sudo cat /var/lib/libvirt/dnsmasq/virbr0.status

#
```
