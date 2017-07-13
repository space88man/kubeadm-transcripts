# Network Transcript

In this transcript, we will install the weave network add-on. All our pods will get IP addresses
on 10.32.0.0/12. Kubernetes will continue to assign services to 10.96.0.0/12 (standard network
setup by kubeadm).

The mapping of externally visible service IP address/port to 10.96.0.0/12 to 10.32.0.0/12
is handled transparently by kubernetes+network add-on.

There are many (too many?) network add-on choices: in this transcript we will use [weave](https://github.com/weaveworks/weave).
In other transcripts, we will try flannel and romana.

## Installation of weave network add-on

Weave recommends using the network add-on rather than integrating kubernetes with an external configured weave SDN.

As we may have rebuild the cluster several time since the previous task here is the start state:

Output:
```
[root@kube0 ~]# sudo -u centos kubectl get po -n kube-system -o wide
NAME                            READY     STATUS    RESTARTS   AGE       IP                NODE
etcd-kube0                      1/1       Running   0          27s       192.168.125.100   kube0
kube-apiserver-kube0            1/1       Running   0          26s       192.168.125.100   kube0
kube-controller-manager-kube0   1/1       Running   0          27s       192.168.125.100   kube0
kube-dns-2425271678-kd1j5       0/3       Pending   0          18s       <none>            <none>
kube-proxy-3gvrl                1/1       Running   0          18s       192.168.125.100   kube0
kube-scheduler-kube0            1/1       Running   0          26s       192.168.125.100   kube0
```

*Transcript*:

```sh
sudo -u centos kubectl apply -f https://git.io/weave-kube-1.6

## less time taken to pull docker images, it takes up to 1 min for the weave pods
## and kube-dns to be functional
```
Output:
```
[root@kube0 install]# sudo -u centos kubectl apply -f https://git.io/weave-kube-1.6
serviceaccount "weave-net" created
clusterrole "weave-net" created
clusterrolebinding "weave-net" created
daemonset "weave-net" created
```

Verify:
```sh
## in another terminal we poll until we see that all pods are Running
watch sudo -u centos kubectl get po -n kube-system


## ...installing...
Every 2.0s: sudo -u centos kubectl get po -n kube-system                                                         Fri Jul  7 08:55:20 2017

NAME                            READY     STATUS              RESTARTS   AGE       IP                NODE
etcd-kube0                      1/1       Running             0          2m        192.168.125.100   kube0
kube-apiserver-kube0            1/1       Running             0          2m        192.168.125.100   kube0
kube-controller-manager-kube0   1/1       Running             0          2m        192.168.125.100   kube0
kube-dns-2425271678-kd1j5       3/3       ContainerCreating   0          2m        10.32.0.10        kube0
kube-proxy-3gvrl                1/1       Running             0          2m        192.168.125.100   kube0
kube-scheduler-kube0            1/1       Running             0          2m        192.168.125.100   kube0
weave-net-txhng                 2/2       Running             0          1m        192.168.125.100   kube0


## Success!!
Every 2.0s: sudo -u centos kubectl get po -n kube-system                                                         Fri Jul  7 08:56:29 2017

NAME                            READY     STATUS    RESTARTS   AGE       IP                NODE
etcd-kube0                      1/1       Running   0          2m        192.168.125.100   kube0
kube-apiserver-kube0            1/1       Running   0          2m        192.168.125.100   kube0
kube-controller-manager-kube0   1/1       Running   0          2m        192.168.125.100   kube0
kube-dns-2425271678-kd1j5       3/3       Running   0          2m        10.32.0.10        kube0
kube-proxy-3gvrl                1/1       Running   0          2m        192.168.125.100   kube0
kube-scheduler-kube0            1/1       Running   0          2m        192.168.125.100   kube0
weave-net-txhng                 2/2       Running   0          1m        192.168.125.100   kube0

```

## Worker Nodes

Finally we can join worker nodes, by default, user pods are not run on the master node.

### Workaround Bug #335

When we join the worker nodes we may hit kubeadm issue [#335](https://github.com/kubernetes/kubeadm/issues/335).

When we try to join a node we will get the following error message:
Output:
```
[root@kube0 install]# pdsh -g nodes kubeadm join --token 3cb88f.5abad237ba22513c 192.168.125.100:6443

kube1: [discovery] Failed to connect to API Server "192.168.125.100:6443": there is no JWS signed token in the cluster-info ConfigMap. This token id "3cb88f" is invalid for this cluster, can't connect
kube2: [discovery] Failed to connect to API Server "192.168.125.100:6443": there is no JWS signed token in the cluster-info ConfigMap. This token id "3cb88f" is invalid for this cluster, can't connect
kube3: [discovery] Failed to connect to API Server "192.168.125.100:6443": there is no JWS signed token in the cluster-info ConfigMap. This token id "3cb88f" is invalid for this cluster, can't connect
```

*Transcript*:
```sh
## we may hit issue #335 and our worker nodes will fail to join
## this is a workaround. On kube0
cd /opt/install
curl -o bug335.yaml https://raw.githubusercontent.com/space88man/kubeadm-transcripts/master/scripts/bug335.yaml
sudo -u centos kubectl apply -f bug335.yaml

```

Output:
```
root@kube0 install]# sudo -u centos kubectl apply -f bug335.yaml 
role "system:controller:bootstrap-signer" created
rolebinding "system:controller:bootstrap-signer" created
```


### Join Worker Nodes

*Transcript*:

```sh
## join 3 worker nodes
## the token comes from the output of kubeadm init in 00-install.md
pdsh -g nodes kubeadm join --token 96f75e.440cb6581dc488ba 192.168.125.100:6443
```

Output:
```
[root@kube0 install]# pdsh -g nodes kubeadm join --token 96f75e.440cb6581dc488ba 192.168.125.100:6443
kube3: [kubeadm] WARNING: kubeadm is in beta, please do not use it for production clusters.
kube3: [preflight] Running pre-flight checks
kube2: [kubeadm] WARNING: kubeadm is in beta, please do not use it for production clusters.
kube2: [preflight] Running pre-flight checks
kube3: [preflight] Starting the kubelet service
kube3: [discovery] Trying to connect to API Server "192.168.125.100:6443"
kube3: [discovery] Created cluster-info discovery client, requesting info from "https://192.168.125.100:6443"
kube2: [preflight] Starting the kubelet service
kube2: [discovery] Trying to connect to API Server "192.168.125.100:6443"
kube2: [discovery] Created cluster-info discovery client, requesting info from "https://192.168.125.100:6443"
kube1: [kubeadm] WARNING: kubeadm is in beta, please do not use it for production clusters.
kube1: [preflight] Running pre-flight checks
kube1: [preflight] Starting the kubelet service
kube1: [discovery] Trying to connect to API Server "192.168.125.100:6443"
kube1: [discovery] Created cluster-info discovery client, requesting info from "https://192.168.125.100:6443"
kube3: [discovery] Cluster info signature and contents are valid, will use API Server "https://192.168.125.100:6443"
kube3: [discovery] Successfully established connection with API Server "192.168.125.100:6443"
kube3: [bootstrap] Detected server version: v1.7.0
kube3: [bootstrap] The server supports the Certificates API (certificates.k8s.io/v1beta1)
kube3: [csr] Created API client to obtain unique certificate for this node, generating keys and certificate signing request
kube3: [csr] Received signed certificate from the API server, generating KubeConfig...
kube3: [kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/kubelet.conf"
kube3: 
kube3: Node join complete:
kube3: * Certificate signing request sent to master and response
kube3:   received.
kube3: * Kubelet informed of new secure connection details.
kube3: 
kube3: Run 'kubectl get nodes' on the master to see this machine join.
kube2: [discovery] Cluster info signature and contents are valid, will use API Server "https://192.168.125.100:6443"
kube2: [discovery] Successfully established connection with API Server "192.168.125.100:6443"
kube2: [bootstrap] Detected server version: v1.7.0
kube2: [bootstrap] The server supports the Certificates API (certificates.k8s.io/v1beta1)
kube2: [csr] Created API client to obtain unique certificate for this node, generating keys and certificate signing request
kube2: [csr] Received signed certificate from the API server, generating KubeConfig...
kube2: [kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/kubelet.conf"
kube2: 
kube2: Node join complete:
kube2: * Certificate signing request sent to master and response
kube2:   received.
kube2: * Kubelet informed of new secure connection details.
kube2: 
kube2: Run 'kubectl get nodes' on the master to see this machine join.
kube1: [discovery] Cluster info signature and contents are valid, will use API Server "https://192.168.125.100:6443"
kube1: [discovery] Successfully established connection with API Server "192.168.125.100:6443"
kube1: [bootstrap] Detected server version: v1.7.0
kube1: [bootstrap] The server supports the Certificates API (certificates.k8s.io/v1beta1)
kube1: [csr] Created API client to obtain unique certificate for this node, generating keys and certificate signing request
kube1: [csr] Received signed certificate from the API server, generating KubeConfig...
kube1: [kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/kubelet.conf"
kube1: 
kube1: Node join complete:
kube1: * Certificate signing request sent to master and response
kube1:   received.
kube1: * Kubelet informed of new secure connection details.
kube1: 
kube1: Run 'kubectl get nodes' on the master to see this machine join.
```

Verify:
```sh
[root@kube0 install]# sudo -u centos kubectl get nodes
NAME      STATUS    AGE       VERSION
kube0     Ready     58m       v1.7.0
kube1     Ready     2m        v1.7.0
kube2     Ready     2m        v1.7.0
kube3     Ready     2m        v1.7.0


## polling for weave-net-* pods to be Running
watch sudo -u centos kubectl get po -n kube-system
Every 2.0s: sudo -u centos kubectl get po -n kube-system                     ul  7 09:02:04 2017
NAME                            READY     STATUS    RESTARTS   AGE       IP                NODE
etcd-kube0                      1/1       Running   0          15m       192.168.125.100   kube0
kube-apiserver-kube0            1/1       Running   0          15m       192.168.125.100   kube0
kube-controller-manager-kube0   1/1       Running   0          15m       192.168.125.100   kube0
kube-dns-2425271678-kd1j5       3/3       Running   0          14m       10.32.0.10        kube0
kube-proxy-3gvrl                1/1       Running   0          14m       192.168.125.100   kube0
kube-proxy-4qdpx                1/1       Running   0          10m       192.168.125.103   kube3
kube-proxy-jjd9w                1/1       Running   0          10m       192.168.125.101   kube1
kube-proxy-t99b2                1/1       Running   0          9m        192.168.125.102   kube2
kube-scheduler-kube0            1/1       Running   0          15m       192.168.125.100   kube0
weave-net-mjz0c                 2/2       Running   1          10m       192.168.125.103   kube3
weave-net-s35tk                 2/2       Running   1          10m       192.168.125.101   kube1
weave-net-txhng                 2/2       Running   0          13m       192.168.125.100   kube0
weave-net-x7fmr                 2/2       Running   0          9m        192.168.125.102   kube2
```


## Smoke Test

In our virgin cluster, we have an application pod, providing the kube-dns service.
 This service provides named ports so we can test SRV resolution as well.

Output:

```
### some output lines omitted 
[root@kube0 install]# sudo -u centos kubectl get svc -n kube-system
NAME       CLUSTER-IP   EXTERNAL-IP   PORT(S)         AGE
kube-dns   10.96.0.10   <none>        53/UDP,53/TCP   17m
[root@kube0 install]# dig @10.96.0.10 kube-dns.kube-system.svc.cluster.local


;; QUESTION SECTION:
;kube-dns.kube-system.svc.cluster.local.	IN A

;; ANSWER SECTION:
kube-dns.kube-system.svc.cluster.local.	30 IN A	10.96.0.10

[root@kube0 install]# dig @10.96.0.10 -t SRV _dns._udp.kube-dns.kube-system.svc.cluster.local


;; QUESTION SECTION:
;_dns._udp.kube-dns.kube-system.svc.cluster.local. IN SRV

;; ANSWER SECTION:
_dns._udp.kube-dns.kube-system.svc.cluster.local. 30 IN	SRV 10 100 53 kube-dns.kube-system.svc.cluster.local.

;; ADDITIONAL SECTION:
kube-dns.kube-system.svc.cluster.local.	30 IN A	10.96.0.10

[root@kube0 install]# dig @10.96.0.10 -t SRV _dns-tcp._tcp.kube-dns.kube-system.svc.cluster.local


;; QUESTION SECTION:
;_dns-tcp._tcp.kube-dns.kube-system.svc.cluster.local. IN SRV

;; ANSWER SECTION:
_dns-tcp._tcp.kube-dns.kube-system.svc.cluster.local. 30 IN SRV	10 100 53 kube-dns.kube-system.svc.cluster.local.

;; ADDITIONAL SECTION:
kube-dns.kube-system.svc.cluster.local.	30 IN A	10.96.0.10

```

A word about IP addresses: service address like 10.96.0.10 are typically not ping-able, as they are handled
by destination NAT (DNAT) only for UDP/TCP. Pod addresses like 10.32.0.10 are ping-able.

Output:
```
[root@kube0 install]# ping -c 5 10.96.0.10
PING 10.96.0.10 (10.96.0.10) 56(84) bytes of data.

--- 10.96.0.10 ping statistics ---
5 packets transmitted, 0 received, 100% packet loss, time 4131ms

[root@kube0 install]# ping -c 5 10.32.0.10
PING 10.32.0.10 (10.32.0.10) 56(84) bytes of data.
64 bytes from 10.32.0.10: icmp_seq=1 ttl=64 time=0.059 ms
64 bytes from 10.32.0.10: icmp_seq=2 ttl=64 time=0.036 ms
64 bytes from 10.32.0.10: icmp_seq=3 ttl=64 time=0.037 ms
64 bytes from 10.32.0.10: icmp_seq=4 ttl=64 time=0.036 ms
64 bytes from 10.32.0.10: icmp_seq=5 ttl=64 time=0.028 ms

--- 10.32.0.10 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4108ms
rtt min/avg/max/mdev = 0.028/0.039/0.059/0.011 ms
```

## Conclusion

At this stage we have a fully functioning kubernetes cluster with network.
The weave versions are:

```sh
[root@kube0 install]# docker images | grep weave
docker.io/weaveworks/weave-npc                           2.0.1               4f71bca714a3        7 days ago          54.69 MB
docker.io/weaveworks/weave-kube                          2.0.1               d2099d50a03b        7 days ago          100.7 MB
```
