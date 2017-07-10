# Etcd

Etcd is the persistent key-value store for kubernetes. In this transcript we
will explore the etcd database.

## Background

Etcd is used to store state and trigger changes for the kubernetes cluster.
The most important take away is that kubernetes uses etcd **v3**.
Any etcdctl documentation that uses `etcdctl ls` is indicative of v2, and does not work with the
kubernetes v3 store. 

We will install etcd on kube0 and inspect the etcd store.
Although the current version is 3.1.9, and kubernetes is using 3.0.14, this is not significant
as we are only using it to explore the store.

## Tasks

*Transcript*:
```sh
## the etcd store is at 127.0.0.1:2379 on kube0
## this is setup in the etcd-kube0 pod
## on kube0
yum -y install etcd

export ETCDCTL_API=3

## v2 command: guaranteed to fail
etcdctl ls / --recursive

## v3 stores are incompatible with v2: we will see nothing here
## even if we try to force v2
ETCDCTL_API=2 etcdctl ls / --recursive

## --endpoints is superfluous here, as this is the default value;
## included here for illustrative purposes
etcdctl --endpoints 127.0.0.1:2379 get /registry --prefix --keys-only | sort | uniq

## play around with other etcdctl commands

## create a snapshot, creates a file "snapshotdb" in the current directory
etcdctl snapshot save snapshotdb

## check the snapshot file
etcdctl --write-out=table snapshot status snapshotdb
```

Verify:
```
[root@kube0 centos]# rpm -q etcd
etcd-3.1.9-1.el7.x86_64

## try a v2 command, which should fail
[root@kube0 centos]# etcdctl ls / --recursive
Error: unknown command "ls" for "etcdctl"
Run 'etcdctl --help' for usage.
Error:  unknown command "ls" for "etcdctl"

## even using ETCDCTL_API=2, you still cannot inspect the kubernetes store
## because the stores are incompatible

[root@kube0 centos]# ETCDCTL_API=2 etcdctl ls / --recursive
[root@kube0 centos]#  ## nothing to see here, because v2 is incompatible with v3

## run actual v3 commands...
## add superfluous --endpoints option for illustration

[root@kube0 centos]# etcdctl --endpoints http://127.0.0.1:2379 get /registry/ --prefix --keys-only | sort | uniq 

/registry/apiregistration.k8s.io/apiservices/v1.
/registry/apiregistration.k8s.io/apiservices/v1alpha1.rbac.authorization.k8s.io
/registry/apiregistration.k8s.io/apiservices/v1alpha1.settings.k8s.io
/registry/apiregistration.k8s.io/apiservices/v1.authentication.k8s.io
/registry/apiregistration.k8s.io/apiservices/v1.authorization.k8s.io
/registry/apiregistration.k8s.io/apiservices/v1.autoscaling
/registry/apiregistration.k8s.io/apiservices/v1.batch
/registry/apiregistration.k8s.io/apiservices/v1beta1.apiextensions.k8s.io
/registry/apiregistration.k8s.io/apiservices/v1beta1.apps
/registry/apiregistration.k8s.io/apiservices/v1beta1.authentication.k8s.io
/registry/apiregistration.k8s.io/apiservices/v1beta1.authorization.k8s.io
/registry/apiregistration.k8s.io/apiservices/v1beta1.certificates.k8s.io
/registry/apiregistration.k8s.io/apiservices/v1beta1.extensions
/registry/apiregistration.k8s.io/apiservices/v1beta1.policy
/registry/apiregistration.k8s.io/apiservices/v1beta1.rbac.authorization.k8s.io
/registry/apiregistration.k8s.io/apiservices/v1beta1.storage.k8s.io
/registry/apiregistration.k8s.io/apiservices/v1.networking.k8s.io
/registry/apiregistration.k8s.io/apiservices/v1.storage.k8s.io
/registry/certificatesigningrequests/node-csr---7dwBPHIWNtD1HtQ2hPzJ8Rxtat3xYeEpGOUqVh5ao
/registry/certificatesigningrequests/node-csr-_PVaG-oZIUCzA5nTLGCMsLQaAFfEh5-XB4cxZRyLbvQ
/registry/certificatesigningrequests/node-csr-xPVfee56Bm6rLJ4o7g4GMLBJFewHS9vNi9hPFjf-nkY
/registry/clusterrolebindings/cluster-admin

## ... 500 lines omitted ##
## most of the values are opaque binary data
## lets dump one key, and inspect for ascii
## with the sock shop demo still running...

[root@kube0 centos]# etcdctl get /registry/services/specs/sock-shop/rabbitmq | strings
/registry/services/specs/sock-shop/rabbitmq
Service
rabbitmq
        sock-shop"
*$b19e2dd5-62f4-11e7-af14-525400a75c872
name
rabbitmqb
0kubectl.kubernetes.io/last-applied-configuration
{"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"labels":{"name":"rabbitmq"},"name":"rabbitmq","namespace":"sock-shop"},"spec":{"ports":[{"port":5672,"targetPort":5672}],"selector":{"name":"rabbitmq"}}}
name
rabbitmq
10.102.93.119"  ClusterIP:
NoneB

## snapshot
[root@kube0 centos]# rm -f snapshotdb
[root@kube0 centos]# etcdctl snapshot save snapshotdb
Snapshot saved at snapshotdb
[root@kube0 centos]# ls -l snapshotdb
-rw-r--r--. 1 root root 4890656 Jul  8 00:54 snapshotdb

[root@kube0 centos]#  etcdctl --write-out=table snapshot status snapshotdb
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| 32aeb654 |    85232 |        977 | 4.9 MB     |
+----------+----------+------------+------------+
```


## Teardown

In this transcript we will teardown the kubeadm etcd.

Kubernetes requires an etcd cluster: how did kubeadm solve this for us?

* kubeadm creates a single-node etcd cluster; the etcd process run in its own
  pod using the host network, so it can be reached at 127.0.0.1:2379.
* the etcd-kube0 pod mounts `/var/lib/etcd` from the docker host, so that
  the data persists across reboots.
  

### Etcd process

*Transcript*:

```sh
## we can observe the actual etcd command line
ps -ef | grep etcd.*listen

## the etcd pod consists of two containers
## note the pause-amd64 image is always part of a kubernetes pod
## so the the etcd-amd64 is the real workhorse
docker ps | grep etcd

## Lets see the host mount: /var/lib/etcd is persistent
## we need to inspect the correct container, i.e, the one
## that is backed by etcd-amd64
docker inspect 5ef0fb8340b6
```

Output:
```
[root@kube0 centos]# ps -ef | grep etcd.*listen
root      2137  2122  0 10:17 ?        00:00:28 etcd --listen-client-urls=http://127.0.0.1:2379 --advertise-client-urls=http://127.0.0.1:2379 --data-dir=/var/lib/etcd

## kubernetes always injects pause-amd64 into the pod
## the real workhorse is etcd-amd64
[root@kube0 centos]# docker ps | grep etcd
5ef0fb8340b6        gcr.io/google_containers/etcd-amd64@sha256:d83d3545e06fb035db8512e33bd44afb55dea007a3abd7b17742d3ac6d235940                      "etcd --listen-client"   About an hour ago   Up About an hour                        k8s_etcd_etcd-kube0_kube-system_9fb4ea9ba2043e46f75eec93827c4ce3_4
89112d52f34a        gcr.io/google_containers/pause-amd64:3.0                                                                                         "/pause"                 About an hour ago   Up About an hour                        k8s_POD_etcd-kube0_kube-system_9fb4ea9ba2043e46f75eec93827c4ce3_4


## Look for host mounts for data persistence
[root@kube0 centos]# docker inspect 5ef0fb8340b6
## we have found how the etcd cluster created by kubeadm persists data
## --cut--
        "Mounts": [
            {
                "Source": "/etc/ssl/certs",
                "Destination": "/etc/ssl/certs",
                "Mode": "",
                "RW": true,
                "Propagation": "rprivate"
            },
            {
                "Source": "/var/lib/etcd",
                "Destination": "/var/lib/etcd",
                "Mode": "",
                "RW": true,
                "Propagation": "rprivate"
            },
            {
                "Source": "/etc/kubernetes",
                "Destination": "/etc/kubernetes",
                "Mode": "ro",
                "RW": false,
                "Propagation": "rprivate"
            },
            {
                "Source": "/var/lib/kubelet/pods/9fb4ea9ba2043e46f75eec93827c4ce3/containers/etcd/6d61cf4f",
                "Destination": "/dev/termination-log",
                "Mode": "Z",
                "RW": true,
                "Propagation": "rprivate"
            }
        ],

## --cut--
```


### Bad disk performance

etcd as installed by kubeadm, is not production ready. It is a single node
cluster using the docker host filesystem for state in `/var/lib/etcd`. This
obviously causes disk contention with docker, and the fact that we are
running in a VM with the vdisk being a file on the host filesystem means
that we will get horrible latencies for fsync — which is what etcd uses to
persist data.

Our VM vdisk was deliberately created on a regular HD. We can now
observe etcd complaining about bad latencies.
*Transcript*

```sh
## the qcow2 image backing kube0 is on a regular HD
## watch etcd complain about horrible disk latences
## you will get a continuous stream of warnings...

sudo -u centos kubelet logs -f etcd-kube0 -n kube-system
```

Output:
```
## non-stop warnings due to crappy latency:
## disk contention with docker, and we are running in a VM
## using a qcow2 backing file on a regular HD
2017-07-09 07:16:49.497594 W | etcdserver: apply entries took too long [561.342142ms for 1 entries]
2017-07-09 07:16:49.497923 W | etcdserver: avoid queries with large range/delete range!
2017-07-09 07:16:59.561454 W | etcdserver: apply entries took too long [225.44197ms for 1 entries]
2017-07-09 07:16:59.561694 W | etcdserver: avoid queries with large range/delete range!
```

### 2nd vdisk backed by SSD

In this transcript, we will move /var/lib/etcd to an SSD drive. We will no longer have disk contention
with docker, and much decreased logging.

If you are able to add a second vdisk with backing file on an SSD; create a filesystem on the second
disk and mount /var/lib/etcd there.

*Transcript*

```sh
## assume you have a second vdisk backed by qcow2 image on a SSD drive
## attach this disk to the VM

## on the KVM host create a backing file etcd-low-latency.qcow2  on an SSD drive
qemu-img create -f qcow2 etcd-low-latency.qcow2 20G
virsh attach kube0 etcd-low-latency.qcow2 /dev/sdb --driver qemu --subdriver=qcow2

## back on kube0; make sure sdb is recognised
ls -l /dev/sdb
## create filesystem
pvcreate /dev/sdb
vgcreate varvg /dev/sdb
lvcreate -n etcd -L10G varvg
mkfs -t xfs /dev/varvg/etcd

## quiesce kube0
systemctl stop docker kubelet
mv /var/lib/etcd /var/lib/etcd.backup
mkdir /var/lib/etcd
mount /dev/varvg/etcd /var/lib/etcd
rsync -avz /var/lib/etcd.backup/ /var/lib/etcd/
## make SELinux happy
restorecon -R /var/lib/etcd/
chcon -u system_u -R /var/lib/etcd

## restart with etcd backed on an SSD
systemctl start docker kubelet

## we need to make this persistent otherwise
## we will not have /var/lib/etcd on reboot
echo '/dev/varvg/etcd /var/lib/etcd   xfs     defaults 1 1' >> /etc/fstab

```

Verify:
```
## we have a second vdisk for our low-latency test
[root@kube0 centos]# ls -l /dev/sd?
brw-rw----. 1 root disk 8,  0 Jul 10 10:10 /dev/sda
brw-rw----. 1 root disk 8, 16 Jul 10 10:10 /dev/sdb

## we have moved /var/lib/etcd to the second vdisk
[root@kube0 centos]# mount | grep etcd
/dev/mapper/varvg-etcd on /var/lib/etcd type xfs (rw,relatime,seclabel,attr2,inode64,noquota)

##
## we still get warnings, but much fewer, once every few mins,
## instead of a continuous stream; note that the bad values
## are still pretty good < 20ms, rather that several tens or hundreds of ms
##
2017-07-10 03:07:35.261819 I | mvcc: store.index: compact 337242
2017-07-10 03:07:35.262082 W | etcdserver: apply entries took too long [13.994439ms for 1 entries]
2017-07-10 03:07:35.262089 W | etcdserver: avoid queries with large range/delete range!
2017-07-10 03:07:35.263143 I | mvcc: finished scheduled compaction at 337242 (took 941.07µs)
2017-07-10 03:12:19.918731 W | etcdserver: apply entries took too long [14.718207ms for 1 entries]
2017-07-10 03:12:19.918753 W | etcdserver: avoid queries with large range/delete range!
2017-07-10 03:12:28.952788 W | etcdserver: apply entries took too long [12.639508ms for 1 entries]
2017-07-10 03:12:28.953021 W | etcdserver: avoid queries with large range/delete range!
2017-07-10 03:12:35.280160 I | mvcc: store.index: compact 337662
2017-07-10 03:12:35.280459 W | etcdserver: apply entries took too long [14.713842ms for 1 entries]
2017-07-10 03:12:35.280468 W | etcdserver: avoid queries with large range/delete range!
2017-07-10 03:12:35.281334 I | mvcc: finished scheduled compaction at 337662 (took 797.631µs)

```

## Conclusion

We have inspected the etcd store using the v3 APIs. We have also had a teardown of the etcd as installed
by kubeadm and experienced the disk latency issue.

etcd disk latency is addressed in:
* [etcd FAQ](https://coreos.com/etcd/docs/latest/faq.html); search for "apply entries took too long"
* [improve disk priority](https://coreos.com/etcd/docs/latest/tuning.html):  `` $ sudo ionice -c2 -n0 -p `pgrep etcd` ``
* 10ms is too stringent: kubernetes 1.7 uses etcd 3.0.14. Even with an SSD backing `/var/lib/etcd` (of course running
  in a VM makes things much worse), we may get latencies > 10ms thus triggering a warning. In newer versions of etcd 3,
  the threshold is now [100ms](https://github.com/kubernetes/kubernetes/issues/43363).
  In our test scenarios, the HD backing file would still have triggered warnings, but the
  SSD backing file would have been fine.  From the etcd team:
  > Ignore the warning. We (etcd team) realized 10ms is a too tight deadline for not beefy machines. We already made that 100ms in the new releases.