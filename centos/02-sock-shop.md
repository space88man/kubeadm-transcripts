# Sock Shop Demo

The kubeadm tutorial recommends  sock shop demo as a smoke test that the kubernetes cluster is up and running.

In this transcript, we will install the sock shop demo.

## Sock Shop

*Transcript*:
```sh
sudo -u centos kubectl create namespace sock-shop
sudo -u centos kubectl apply -n sock-shop -f "https://github.com/microservices-demo/microservices-demo/blob/master/
deploy/kubernetes/complete-demo.yaml?raw=true"
```

Output:
```
[root@kube0 install]# sudo -u centos kubectl create namespace sock-shop                                                                  
namespace "sock-shop" created
[root@kube0 install]# sudo -u centos kubectl apply -n sock-shop -f "https://github.com/microservices-demo/microservices-demo/blob/master/
deploy/kubernetes/complete-demo.yaml?raw=true"
deployment "carts-db" created
service "carts-db" created
deployment "carts" created
service "carts" created
deployment "catalogue-db" created
service "catalogue-db" created
deployment "catalogue" created
service "catalogue" created
deployment "front-end" created
service "front-end" created
deployment "orders-db" created
service "orders-db" created
deployment "orders" created
service "orders" created
deployment "payment" created
service "payment" created
deployment "queue-master" created
service "queue-master" created
deployment "rabbitmq" created
service "rabbitmq" created
deployment "shipping" created
service "shipping" created
deployment "user-db" created
service "user-db" created
deployment "user" created
service "user" created
```

Verify:
```sh
## we poll until all pods are Running
watch sudo -u centos kubectl get po -n sock-shop

## ...installing...
Every 2.0s: sudo -u centos kubectl get po -n sock-shop                                                           Fri Jul  7 09:15:03 2017

NAME                            READY     STATUS              RESTARTS   AGE
carts-2469883122-m1hdj          0/1       ContainerCreating   0          42s
carts-db-1721187500-b9nj7       0/1       ContainerCreating   0          42s
catalogue-4293036822-r6sjt      0/1       ContainerCreating   0          39s
catalogue-db-1846494424-d64vz   0/1       ContainerCreating   0          41s
front-end-2337481689-rr8zc      0/1       ContainerCreating   0          38s
orders-733484335-sj8hb          0/1       ContainerCreating   0          35s
orders-db-3728196820-zvfkh      0/1       ContainerCreating   0          36s
payment-3050936124-ssx0t        0/1       ContainerCreating   0          33s
queue-master-2067646375-602wf   0/1       ContainerCreating   0          31s
rabbitmq-241640118-3hr9r        0/1       ContainerCreating   0          29s
shipping-2463450563-gj3pq       0/1       ContainerCreating   0          27s
user-1574605338-5phcq           0/1       ContainerCreating   0          23s
user-db-3152184577-qp5h1        0/1       ContainerCreating   0          24s

## After 4m
NAME                            READY     STATUS              RESTARTS   AGE
carts-2469883122-m1hdj          1/1       Running             0          5m
carts-db-1721187500-b9nj7       1/1       Running             0          5m
catalogue-4293036822-r6sjt      1/1       Running             0          5m
catalogue-db-1846494424-d64vz   1/1       Running             0          5m
front-end-2337481689-rr8zc      1/1       Running             0          5m
orders-733484335-sj8hb          1/1       Running             0          5m
orders-db-3728196820-zvfkh      1/1       Running             0          5m
payment-3050936124-ssx0t        1/1       Running             0          5m
queue-master-2067646375-602wf   0/1       ContainerCreating   0          5m
rabbitmq-241640118-3hr9r        0/1       ContainerCreating   0          5m
shipping-2463450563-gj3pq       0/1       ContainerCreating   0          5mq
user-1574605338-5phcq           0/1       ContainerCreating   0          4m
user-db-3152184577-qp5h1        0/1       ContainerCreating   0          4m

## After 6m
## YMMV: it depends on how long it takes to pull the sock shop images down
NAME                            READY     STATUS    RESTARTS   AGE
carts-2469883122-m1hdj          1/1       Running   0          6m
carts-db-1721187500-b9nj7       1/1       Running   0          6m
catalogue-4293036822-r6sjt      1/1       Running   0          6m
catalogue-db-1846494424-d64vz   1/1       Running   0          6m
front-end-2337481689-rr8zc      1/1       Running   0          6m
orders-733484335-sj8hb          1/1       Running   0          6m
orders-db-3728196820-zvfkh      1/1       Running   0          6m
payment-3050936124-ssx0t        1/1       Running   0          6m
queue-master-2067646375-602wf   1/1       Running   0          6m
rabbitmq-241640118-3hr9r        1/1       Running   0          6m
shipping-2463450563-gj3pq       1/1       Running   0          6m
user-1574605338-5phcq           1/1       Running   0          6m
user-db-3152184577-qp5h1        1/1       Running   0          6m
```

Where are the sock shop microservices running? Notice that all the IP addresses are in the weave space 10.32.0.0/12.
```
[root@kube0 install]#  sudo -u centos kubectl get po -n sock-shop -o wide
NAME                            READY     STATUS    RESTARTS   AGE       IP           NODE
carts-2469883122-m1hdj          1/1       Running   0          8m        10.42.0.7    kube3
carts-db-1721187500-b9nj7       1/1       Running   0          8m        10.44.0.7    kube1
catalogue-4293036822-r6sjt      1/1       Running   0          8m        10.44.0.8    kube1
catalogue-db-1846494424-d64vz   1/1       Running   0          8m        10.36.0.7    kube2
front-end-2337481689-rr8zc      1/1       Running   0          8m        10.42.0.8    kube3
orders-733484335-sj8hb          1/1       Running   0          8m        10.44.0.9    kube1
orders-db-3728196820-zvfkh      1/1       Running   0          8m        10.42.0.9    kube3
payment-3050936124-ssx0t        1/1       Running   0          8m        10.36.0.8    kube2
queue-master-2067646375-602wf   1/1       Running   0          8m        10.42.0.11   kube3
rabbitmq-241640118-3hr9r        1/1       Running   0          8m        10.44.0.10   kube1
shipping-2463450563-gj3pq       1/1       Running   0          8m        10.42.0.10   kube3
user-1574605338-5phcq           1/1       Running   0          7m        10.44.0.11   kube1
user-db-3152184577-qp5h1        1/1       Running   0          7m        10.36.0.9    kube2
```

Where is the sock shop frontend (external entry point)? Notice that all the IP addresses are in the service space 10.96.0.0/12.
```
[root@kube0 install]# kubectl --kubeconfig ~centos/.kube/config get svc --namespace=sock-shop
NAME           CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
carts          10.104.232.60    <none>        80/TCP         9m
carts-db       10.99.96.44      <none>        27017/TCP      9m
catalogue      10.97.54.173     <none>        80/TCP         9m
catalogue-db   10.110.125.181   <none>        3306/TCP       9m
front-end      10.101.12.11     <nodes>       80:30001/TCP   9m
orders         10.97.224.81     <none>        80/TCP         8m
orders-db      10.100.130.51    <none>        27017/TCP      9m
payment        10.99.94.153     <none>        80/TCP         8m
queue-master   10.96.242.83     <none>        80/TCP         8m
rabbitmq       10.102.93.119    <none>        5672/TCP       8m
shipping       10.97.8.75       <none>        80/TCP         8m
user           10.105.1.80      <none>        80/TCP         8m
user-db        10.101.48.252    <none>        27017/TCP      8m
```

The user facing IP address is kubeX:30001, i.e. 192.168.100-103:30001. You should
be able to browse to any of kube[0-3]:30001 to reach the demo.