# KVM

For those using libvirt/KVM, kube0.xml can be used to  
create VMs. Adjust the location of the
vdisk inside the XML file that points to your location.


```sh
virsh define kube0.xml
```
