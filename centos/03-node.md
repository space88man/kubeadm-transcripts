# Node Management

In this transcript, we power off a node and reboot the entire cluster.


## Node Management

We have the sock shop demo running, we power off a node and observe the resurrection
and redistribution of pods.

```
## Start state
# sudo -u centos kubectl get po -n sock-shop -owide
NAME                            READY     STATUS    RESTARTS   AGE       IP           NODE
carts-2469883122-m1hdj          1/1       Running   0          3h        10.42.0.7    kube3
carts-db-1721187500-b9nj7       1/1       Running   0          3h        10.44.0.7    kube1
catalogue-4293036822-r6sjt      1/1       Running   0          3h        10.44.0.8    kube1
catalogue-db-1846494424-d64vz   1/1       Running   0          3h        10.36.0.7    kube2
front-end-2337481689-rr8zc      1/1       Running   0          3h        10.42.0.8    kube3
orders-733484335-sj8hb          1/1       Running   0          3h        10.44.0.9    kube1
orders-db-3728196820-zvfkh      1/1       Running   0          3h        10.42.0.9    kube3
payment-3050936124-ssx0t        1/1       Running   0          3h        10.36.0.8    kube2
queue-master-2067646375-602wf   1/1       Running   0          3h        10.42.0.11   kube3
rabbitmq-241640118-3hr9r        1/1       Running   0          3h        10.44.0.10   kube1
shipping-2463450563-gj3pq       1/1       Running   0          3h        10.42.0.10   kube3
user-1574605338-5phcq           1/1       Running   0          3h        10.44.0.11   kube1
user-db-3152184577-qp5h1        1/1       Running   0          3h        10.36.0.9    kube2
```

Power off a node *Transcript*:
```sh
ssh kube3 poweroff
```

Verify:
```
[root@kube0 install]# sudo -u centos kubectl get nodes
NAME      STATUS     AGE       VERSION
kube0     Ready      5h        v1.7.0
kube1     Ready      4h        v1.7.0
kube2     Ready      4h        v1.7.0
kube3     NotReady   4h        v1.7.0

## NodeLost
Every 2.0s: sudo -u centos kubectl get po -n kube-system                     Fri Jul  7 13:12:11 2017

NAME                            READY     STATUS     RESTARTS   AGE
etcd-kube0                      1/1       Running    0          5h
kube-apiserver-kube0            1/1       Running    0          5h
kube-controller-manager-kube0   1/1       Running    1          5h
kube-dns-2425271678-n3qv2       3/3       Running    0          5h
kube-proxy-45mlv                1/1       Running    0          4h
kube-proxy-72t5t                1/1       Running    0          5h
kube-proxy-ntbvj                1/1       NodeLost   0          4h
kube-proxy-r26dv                1/1       Running    0          4h
kube-scheduler-kube0            1/1       Running    0          5h
weave-net-0lhn5                 2/2       Running    0          4h
weave-net-4b472                 2/2       Running    0          4h
weave-net-f91q1                 2/2       NodeLost   0          4h
weave-net-nttn5                 2/2       Running    0          4h

```

Observe:
```
## poll to see what happens to the pods
watch sudo -u centos kubectl get po -n sock-shop -o wide

## pods are resurrecting...
Every 2.0s: sudo -u centos kubectl get po -n sock-shop -o wide                                           Fri Jul  7 13:11:05 2017

NAME                            READY     STATUS              RESTARTS   AGE       IP           NODE
carts-2469883122-4x0gs          1/1       Running             0          42s       10.44.0.12   kube1
carts-2469883122-m1hdj          1/1       Unknown             0          3h        10.42.0.7    kube3
carts-db-1721187500-b9nj7       1/1       Running             0          3h        10.44.0.7    kube1
catalogue-4293036822-r6sjt      1/1       Running             0          3h        10.44.0.8    kube1
catalogue-db-1846494424-d64vz   1/1       Running             0          3h        10.36.0.7    kube2
front-end-2337481689-1fg7x      0/1       ContainerCreating   0          42s       <none>       kube2
front-end-2337481689-rr8zc      1/1       Unknown             0          3h        10.42.0.8    kube3
orders-733484335-sj8hb          1/1       Running             0          3h        10.44.0.9    kube1
orders-db-3728196820-nzjgv      0/1       ContainerCreating   0          41s       <none>       kube2
orders-db-3728196820-zvfkh      1/1       Unknown             0          3h        10.42.0.9    kube3
payment-3050936124-ssx0t        1/1       Running             0          3h        10.36.0.8    kube2
queue-master-2067646375-602wf   1/1       Unknown             0          3h        10.42.0.11   kube3
queue-master-2067646375-cfqjf   0/1       ContainerCreating   0          41s       <none>       kube2
rabbitmq-241640118-3hr9r        1/1       Running             0          3h        10.44.0.10   kube1
shipping-2463450563-gj3pq       1/1       Unknown             0          3h        10.42.0.10   kube3
shipping-2463450563-n7f5f       1/1       Running             0          41s       10.44.0.13   kube1
user-1574605338-5phcq           1/1       Running             0          3h        10.44.0.11   kube1
user-db-3152184577-qp5h1        1/1       Running             0          3h        10.36.0.9    kube2

## ...until all 13 pods are running again, now on kube1, kube2
[root@kube0 install]#  sudo -u centos kubectl get po -n sock-shop -o wide | grep Running
carts-2469883122-4x0gs          1/1       Running   0          3m        10.44.0.12   kube1
carts-db-1721187500-b9nj7       1/1       Running   0          3h        10.44.0.7    kube1
catalogue-4293036822-r6sjt      1/1       Running   0          3h        10.44.0.8    kube1
catalogue-db-1846494424-d64vz   1/1       Running   0          3h        10.36.0.7    kube2
front-end-2337481689-1fg7x      1/1       Running   0          3m        10.36.0.10   kube2
orders-733484335-sj8hb          1/1       Running   0          3h        10.44.0.9    kube1
orders-db-3728196820-nzjgv      1/1       Running   0          3m        10.36.0.11   kube2
payment-3050936124-ssx0t        1/1       Running   0          3h        10.36.0.8    kube2
queue-master-2067646375-cfqjf   1/1       Running   0          3m        10.36.0.12   kube2
rabbitmq-241640118-3hr9r        1/1       Running   0          3h        10.44.0.10   kube1
shipping-2463450563-n7f5f       1/1       Running   0          3m        10.44.0.13   kube1
user-1574605338-5phcq           1/1       Running   0          3h        10.44.0.11   kube1
user-db-3152184577-qp5h1        1/1       Running   0          3h        10.36.0.9    kube2


```

Power up kube3, *Transcript*:
```sh
## we are using KVM, so on the KVM host...
virsh start kube3
```

Verify:
```
[root@kube0 install]#  sudo -u centos kubectl get nodes                                                  
NAME      STATUS    AGE       VERSION
kube0     Ready     5h        v1.7.0
kube1     Ready     4h        v1.7.0
kube2     Ready     4h        v1.7.0
kube3     Ready     4h        v1.7.0

## kubernetes does not rebalance pods

[root@kube0 install]#   sudo -u centos kubectl get po -n sock-shop -o wide 
NAME                            READY     STATUS    RESTARTS   AGE       IP           NODE
carts-2469883122-4x0gs          1/1       Running   0          10m       10.44.0.12   kube1
carts-db-1721187500-b9nj7       1/1       Running   0          4h        10.44.0.7    kube1
catalogue-4293036822-r6sjt      1/1       Running   0          4h        10.44.0.8    kube1
catalogue-db-1846494424-d64vz   1/1       Running   0          4h        10.36.0.7    kube2
front-end-2337481689-1fg7x      1/1       Running   0          10m       10.36.0.10   kube2
orders-733484335-sj8hb          1/1       Running   0          4h        10.44.0.9    kube1
orders-db-3728196820-nzjgv      1/1       Running   0          10m       10.36.0.11   kube2
payment-3050936124-ssx0t        1/1       Running   0          4h        10.36.0.8    kube2
queue-master-2067646375-cfqjf   1/1       Running   0          10m       10.36.0.12   kube2
rabbitmq-241640118-3hr9r        1/1       Running   0          4h        10.44.0.10   kube1
shipping-2463450563-n7f5f       1/1       Running   0          10m       10.44.0.13   kube1
user-1574605338-5phcq           1/1       Running   0          4h        10.44.0.11   kube1
user-db-3152184577-qp5h1        1/1       Running   0          4h        10.36.0.9    kube2

```