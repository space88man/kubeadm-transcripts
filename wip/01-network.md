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

NAME                            READY     STATUS              RESTARTS   AGE
etcd-kube0                      1/1       Running             0          51m
kube-apiserver-kube0            1/1       Running             0          51m
kube-controller-manager-kube0   1/1       Running             1          51m
kube-dns-2425271678-n3qv2       0/3       ContainerCreating   0          51m
kube-proxy-72t5t                1/1       Running             0          51m
kube-scheduler-kube0            1/1       Running             0          50m
weave-net-nttn5                 2/2       Running             0          35s

## Success!!
Every 2.0s: sudo -u centos kubectl get po -n kube-system                                                         Fri Jul  7 08:56:29 2017

NAME                            READY     STATUS    RESTARTS   AGE
etcd-kube0                      1/1       Running   0          52m
kube-apiserver-kube0            1/1       Running   0          52m
kube-controller-manager-kube0   1/1       Running   1          53m
kube-dns-2425271678-n3qv2       3/3       Running   0          52m
kube-proxy-72t5t                1/1       Running   0          52m
kube-scheduler-kube0            1/1       Running   0          52m
weave-net-nttn5                 2/2       Running   0          1m 


```

## Worker Nodes

Finally we can join worker nodes, by default, user pods are not run on the master node.


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
Every 2.0s: sudo -u centos kubectl get po -n kube-system                                                         Fri Jul  7 09:02:04 2017

NAME                            READY     STATUS    RESTARTS   AGE
etcd-kube0                      1/1       Running   0          57m
kube-apiserver-kube0            1/1       Running   0          57m
kube-controller-manager-kube0   1/1       Running   1          58m
kube-dns-2425271678-n3qv2       3/3       Running   0          58m
kube-proxy-45mlv                1/1       Running   0          3m
kube-proxy-72t5t                1/1       Running   0          58m
kube-proxy-ntbvj                1/1       Running   0          3m
kube-proxy-r26dv                1/1       Running   0          3m
kube-scheduler-kube0            1/1       Running   0          57m
weave-net-0lhn5                 2/2       Running   0          3m
weave-net-4b472                 2/2       Running   0          3m
weave-net-f91q1                 2/2       Running   0          3m
weave-net-nttn5                 2/2       Running   0          7m

```

## Conclusion

At this stage we have a fully functioning kubernetes cluster with network.
The weave versions are:

```sh
[root@kube0 install]# docker images | grep weave
docker.io/weaveworks/weave-npc                           2.0.1               4f71bca714a3        7 days ago          54.69 MB
docker.io/weaveworks/weave-kube                          2.0.1               d2099d50a03b        7 days ago          100.7 MB
```