# Etcd

Etcd is the persistent key-value store for kubernetes. In this transcript we
will explore the etcd database.

## Background

Etcd is used to store state and trigger changes for the kubernetes cluster.
The most important take away is that kubernetes uses etcd **v3**.
Any etcdctl documentation that uses `etcdctl ls` is indicative of v2, and does not work with the
kubernetes v3 store. 

We will install etcd on kube0 and inspect the etcd store.
All though the current version is 3.1.9, and kubernetes is using 3.0.14, this is not significant
as we are only using it to explore the store.

*Transcript*:
```sh
## the etcd store is at 127.0.0.1:2379 on kube0
## this is setup in the etcd-kube0 pod
## on kube0
yum -y install etcd

export ETCDCTL_API=3

etcdctl get /registry --prefix --keys-only | sort | uniq

## play around with other etcdctl commands

## create a snapshot, creates a file "snapshotdb" in the current directory
etcdctl --endpoints http://127.0.0.1:2379 snapshot save snapshotdb

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

## at ETCDCTL_API=2, you still cannot inspect the kubernetes store
## because the stores are incompatible

[root@kube0 centos]# ETCDCTL_API=2 etcdctl ls / --recursive
[root@kube0 centos]#  ## nothing to see here, because v2 is incompatible with v3

## run actual v3 commands...

[root@kube0 centos]# etcdctl get /registry/ --prefix --keys-only | sort | uniq 

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

## ...over 200 lines omitted ##
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
[root@kube0 centos]#  etcdctl --write-out=table snapshot status snapshotdb
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| 32aeb654 |    85232 |        977 | 4.9 MB     |
+----------+----------+------------+------------+
```

