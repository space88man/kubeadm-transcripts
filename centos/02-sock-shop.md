# Sock Shop Demo

The kubeadm tutorial uses the sock shop demo as a smoke test that the kubernetes cluster is up and running.

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
shipping-2463450563-gj3pq       0/1       ContainerCreating   0          5m
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

## Conclusion

At this stage we have run a smoke test, viz., the sock shop microservices demo. This is the list of images
that the worker nodes have as a result of the sock shop demo:

```sh
[root@kube0 install]# pdsh -g nodes docker images | sed 's/^.......//' | grep -v REPOSITORY | sort | uniq
docker.io/mongo                             latest              57c67caab3d8        11 hours ago        359.1 MB
docker.io/rabbitmq                          3.6.8               8cdcbee37f62        3 months ago        179.4 MB
docker.io/weaveworksdemos/carts             0.4.8               c00473736118        3 months ago        197.6 MB
docker.io/weaveworksdemos/catalogue         0.3.5               0bd359b6d6e8        3 months ago        41.22 MB
docker.io/weaveworksdemos/catalogue-db      0.3.0               9d0c5eb88949        6 months ago        400.1 MB
docker.io/weaveworksdemos/front-end         0.3.12              b54402ef78a5        3 months ago        119.8 MB
docker.io/weaveworksdemos/orders            0.4.7               8275c5b9181b        3 months ago        197.6 MB
docker.io/weaveworksdemos/payment           0.4.3               4f2c23055dcd        3 months ago        32.46 MB
docker.io/weaveworksdemos/queue-master      0.3.1               76f0de7a12ac        4 months ago        178.5 MB
docker.io/weaveworksdemos/shipping          0.4.8               4fc533e8180a        3 months ago        198.6 MB
docker.io/weaveworksdemos/user              0.4.4               ab8af7050996        3 months ago        35.26 MB
docker.io/weaveworksdemos/user-db           0.4.0               196601f91030        6 months ago        716.9 MB
docker.io/weaveworks/weave-kube             2.0.1               d2099d50a03b        7 days ago          100.7 MB
docker.io/weaveworks/weave-npc              2.0.1               4f71bca714a3        7 days ago          54.69 MB
gcr.io/google_containers/kube-proxy-amd64   v1.7.0              d2d44013d0f8        7 days ago          114.7 MB
gcr.io/google_containers/pause-amd64        3.0                 99e59f495ffa        14 months ago       746.9 kB
```