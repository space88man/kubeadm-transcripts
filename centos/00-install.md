# 00 Installation

In this transcript we install kubeadm  until just before a network addon. All pods will be running except for kube-dns (to be expected, since we don't have a network).

We heavily make use of pdsh to run command on all four nodes.

## Prerequisites

* 4 CentOS VMs, 192.168.125.100-103/24, with internet access, and EPEL repository enabled
* Ensure docker is running and can pull and run basic images on each node.
* root has password-less ssh from kube0 to kube[0-3]
* non-root user: centos has  password-less ssh from kube0 to kube[0-3] and password-less sudo on all nodes
* Install pdsh, pdsh-mod-genders and add the following /etc/genders file:

    ```
    kubes[0-3] kubes
    kubes[1-3] nodes
    ```

Verify:

```
# rpm -q docker
docker-1.12.6-28.git1398f24.el7.centos.x86_64

# systemctl status docker
● docker.service - Docker Application Container Engine
   Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2017-07-07 07:42:57 UTC; 6min ago
     Docs: http://docs.docker.com
 Main PID: 1315 (dockerd-current)
   CGroup: /system.slice/docker.service
           ├─1315 /usr/bin/dockerd-current --add-runtime docker-runc=/usr/libexec/docker/docker-runc-current --default-runtime=docker-...
           └─1320 /usr/bin/docker-containerd-current -l unix:///var/run/docker/libcontainerd/docker-containerd.sock --shim docker-cont...
```

## Installation

All these tasks are performed on kube0, and use pdsh to run commands on the worker nodes.

*Transcript*:

```sh
## Work on kube0, this installs all binaries

## working directory
mkdir -p /opt/install
cd /opt/install

## add kubectl to all nodes (not really necessary)
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl

pdcp -g kubes kubectl /usr/bin/kubectl
pdsh -g kubes chmod +x /usr/bin/kubectl

## install RPMs
cat > kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg

EOF

pdcp -g kubes kubernetes.repo /etc/yum.repos.d/kubernetes.repo

pdsh -g kubes yum -y install kubelet kubeadm
```

Verify:

```
# rpm -qa | grep kube
kubectl-1.7.0-0.x86_64
kubernetes-cni-0.5.1-0.x86_64
kubeadm-1.7.0-0.x86_64
kubelet-1.7.0-0.x86_64

# [root@kube0 install]# kubectl version
Client Version: version.Info{Major:"1", Minor:"7", GitVersion:"v1.7.0", GitCommit:"d3ada0119e776222f11ec7945e6d860061339aad", GitTreeState:"clean", BuildDate:"2017-06-29T23:15:59Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}

```

## Bootstrap

In this transcript we get kubernetes running prior to a network.

*Transcript*:

```sh
## to make kubeadm happy
pdsh -g kubes modprobe -v br_netfilter
pdsh -g kubes 'echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables'

## now bootstrap kubeadm, this is only run on the master: kube0
kubeadm init

```

Verify:
```
### output of kubeadm init
[root@kube0 install]# kubeadm init
[kubeadm] WARNING: kubeadm is in beta, please do not use it for production clusters.
[init] Using Kubernetes version: v1.7.0
[init] Using Authorization modes: [Node RBAC]
[preflight] Running pre-flight checks
[preflight] Starting the kubelet service
[certificates] Generated CA certificate and key.
[certificates] Generated API server certificate and key.
[certificates] API Server serving cert is signed for DNS names [kube0 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 192.168.125.100]
[certificates] Generated API server kubelet client certificate and key.
[certificates] Generated service account token signing key and public key.
[certificates] Generated front-proxy CA certificate and key.
[certificates] Generated front-proxy client certificate and key.
[certificates] Valid certificates and keys now exist in "/etc/kubernetes/pki"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/admin.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/kubelet.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/controller-manager.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/scheduler.conf"
[apiclient] Created API client, waiting for the control plane to become ready
[apiclient] All control plane components are healthy after 55.500900 seconds
[token] Using token: 96f75e.440cb6581dc488ba
[apiconfig] Created RBAC rules
[addons] Applied essential addon: kube-proxy
[addons] Applied essential addon: kube-dns

Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run (as a regular user):

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  http://kubernetes.io/docs/admin/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join --token 96f75e.440cb6581dc488ba 192.168.125.100:6443
```

Enable non-root cluster admin:

*Transcript*:
```sh
## wait for kubeadm init to finish, then enable non-root cluster-admin user

sudo -u centos bash -s <<'EOF'
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
EOF

sudo -u centos kubectl get po -n kube-system
```

Verify:
```
[root@kube0 install]# sudo -u centos kubectl version
Client Version: version.Info{Major:"1", Minor:"7", GitVersion:"v1.7.0", GitCommit:"d3ada0119e776222f11ec7945e6d860061339aad", GitTreeState:"clean", BuildDate:"2017-06-29T23:15:59Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"7", GitVersion:"v1.7.0", GitCommit:"d3ada0119e776222f11ec7945e6d860061339aad", GitTreeState:"clean", BuildDate:"2017-06-29T22:55:19Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}


[root@kube0 install]# sudo -u centos kubectl get po -n kube-system
NAME                            READY     STATUS              RESTARTS   AGE
etcd-kube0                      1/1       Running             0          6m
kube-apiserver-kube0            1/1       Running             0          6m
kube-controller-manager-kube0   1/1       Running             1          7m
kube-dns-2425271678-n3qv2       0/3       ContainerCreating   0          6m
kube-proxy-72t5t                1/1       Running             0          6m
kube-scheduler-kube0            1/1       Running             0          6m
```


## Conclusion

At this stage we have successfully bootstraped kubernetes without network. The user centos, is a non-root cluster-admin. This user is authenticated and authorised to kubernetes using the credentials in `~centos/.kube/config`.

We will go deeper into kubernetes RBAC (role-based access control) later.

At this stage the versions of the images we have are:

```
[root@kube0 install]# docker images
REPOSITORY                                               TAG                 IMAGE ID            CREATED             SIZE
gcr.io/google_containers/kube-proxy-amd64                v1.7.0              d2d44013d0f8        7 days ago          114.7 MB
gcr.io/google_containers/kube-apiserver-amd64            v1.7.0              f0d4b746fb2b        7 days ago          185.2 MB
gcr.io/google_containers/kube-controller-manager-amd64   v1.7.0              36bf73ed0632        7 days ago          137 MB
gcr.io/google_containers/kube-scheduler-amd64            v1.7.0              5c9a7f60a95c        7 days ago          77.16 MB
gcr.io/google_containers/k8s-dns-sidecar-amd64           1.14.4              38bac66034a6        11 days ago         41.81 MB
gcr.io/google_containers/k8s-dns-kube-dns-amd64          1.14.4              a8e00546bcf3        11 days ago         49.38 MB
gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64     1.14.4              f7f45b9cb733        11 days ago         41.41 MB
gcr.io/google_containers/etcd-amd64                      3.0.14-kubeadm      856e39ac7be3        7 months ago        174.9 MB
gcr.io/google_containers/pause-amd64                     3.0                 99e59f495ffa        14 months ago       746.9 kB
```