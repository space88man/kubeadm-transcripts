# Installation

* v0.1 — initial release

In this transcript we install kubeadm  until just before a network add-on.
All pods will be running except for kube-dns (to be expected, since we don't have a network).

We heavily make use of pdsh to run command on all four nodes.

## Prerequisites

* For the rare VM host commands that we run the transcript is written for KVM.
  Adjust for VirtualBox or VMware as necessary.
  The disk images will be qcow2 format. Whenever you see qcow2 replace with VDI or VMDK depending
  on your chosen VM system. The VMs have a single network interface on a host bridged network
  192.168.125.0/24. The host performs NAT for internet access. We use static addressing in the
  VMs so DHCP is optional.
* 4 CentOS VMs, named kube0–3, ip addresses 192.168.125.100-103/24 resp., with internet access, and the
  EPEL repository enabled
* Ensure docker is running and can pull and run basic images on each node.
* root has password-less ssh from kube0 to kube[0-3]
* non-root user: centos has  password-less ssh from kube0 to kube[0-3] and password-less sudo on all nodes.
  This user will stand-in for the kubernetes superuser.
* Install pdsh, pdsh-mod-genders and add the following /etc/genders file:

    ```
    ## store this file as /etc/genders on kube0
    kube[0-3] kubes
    kube[1-3] nodes
    ```
  To run commands on all four nodes: `pdsh -g kubes <command goes here>`.

  To run commands only on the worker nodes: `pdsh -g nodes <command goes here>`.


Verify:

```
[root@kube0 centos]# rpm -q docker
docker-1.12.6-28.git1398f24.el7.centos.x86_64

[root@kube0 centos]# rpm -qa | grep pdsh
pdsh-2.31-1.el7.x86_64
pdsh-mod-genders-2.31-1.el7.x86_64

## test pdsh to all nodes
[root@kube0 centos]# pdsh -g kubes uptime
kube0:  10:58:04 up 47 min,  1 user,  load average: 0.16, 0.31, 0.28
kube3:  10:58:05 up 48 min,  0 users,  load average: 0.02, 0.04, 0.10
kube2:  10:58:05 up 47 min,  0 users,  load average: 0.06, 0.06, 0.20
kube1:  10:58:05 up 47 min,  0 users,  load average: 0.03, 0.02, 0.17

## test pdsh to all workders
[root@kube0 centos]# pdsh -g nodes uptime                                                                                                
kube2:  10:58:46 up 48 min,  0 users,  load average: 0.08, 0.07, 0.19
kube3:  10:58:46 up 48 min,  0 users,  load average: 0.13, 0.08, 0.11
kube1:  10:58:46 up 48 min,  0 users,  load average: 0.07, 0.04, 0.16

[root@kube0 centos]# systemctl status docker
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
[root@kube0 install]# rpm -qa | grep kube
kubectl-1.7.0-0.x86_64
kubernetes-cni-0.5.1-0.x86_64
kubeadm-1.7.0-0.x86_64
kubelet-1.7.0-0.x86_64

[root@kube0 install]# kubectl version
Client Version: version.Info{Major:"1", Minor:"7", GitVersion:"v1.7.0", GitCommit:"d3ada0119e776222f11ec7945e6d860061339aad", GitTreeState:"clean", BuildDate:"2017-06-29T23:15:59Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}

```

## Revert: Nuke-n-Pave

We install a script to revert the system to a pre-kubeadm state. Use this to get out of an
unrecoverable installation or to redo the task.

Install a recovery script. *Transcript*:

```sh
## install a shell script on each node to nuke-n-pave whatever kubeadm does
## this script takes one argument: stop|cleanup|wipe
##     stop: stops ALL containers
##     cleanup: deletes ALL containers, preserves images to avoid having to download them again
##     wipe: removes kubenetes configuration files created by kubeadm

cd /opt/install
curl -o /opt/install/manage.sh https://raw.githubusercontent.com/space88man/kubeadm-transcripts/master/scripts/manage.sh
pdsh -g nodes mkdir -p /opt/install
pdcp -g nodes manage.sh /opt/install/manage.sh
pdsh -g kubes chmod +x /opt/install/manage.sh
```

Usage:

```
## If kubeadm has been run we can use this script to clean up...
[root@kube0 centos] pdsh -g kubes systemctl stop kubelet

## this stops ALL containers
nstall]# pdsh -g kubes /opt/install/manage.sh stop
kube1: k8s_rabbitmq_rabbitmq-241640118-0chx6_sock-shop_3c5f97f2-6647-11e7-96fb-52540021eccc_0
kube0: k8s_sidecar_kube-dns-2425271678-v9ztq_kube-system_bd1634cf-6645-11e7-96fb-52540021eccc_0
kube1: k8s_user_user-1574605338-jhx4x_sock-shop_3ee9ba5c-6647-11e7-96fb-52540021eccc_0
kube3: k8s_user-db_user-db-3152184577-wp981_sock-shop_3de44e75-6647-11e7-96fb-52540021eccc_0

## this deletes ALL containers
[root@kube0 install]# pdsh -g kubes /opt/install/manage.sh cleanup
kube0: k8s_sidecar_kube-dns-2425271678-v9ztq_kube-system_bd1634cf-6645-11e7-96fb-52540021eccc_0
kube2: k8s_shipping_shipping-2463450563-6svf9_sock-shop_3d4053f9-6647-11e7-96fb-52540021eccc_0
kube3: k8s_user-db_user-db-3152184577-wp981_sock-shop_3de44e75-6647-11e7-96fb-52540021eccc_0
kube1: k8s_rabbitmq_rabbitmq-241640118-0chx6_sock-shop_3c5f97f2-6647-11e7-96fb-52540021eccc_0
kube0: k8s_dnsmasq_kube-dns-2425271678-v9ztq_kube-system_bd1634cf-6645-11e7-96fb-52540021eccc_0

## this wipes all configuration created by kubeadm
[root@kube0 install]# pdsh -g kubes /opt/install/manage.sh wipe
kube2: umount: /var/lib/kubelet/pods/3642ad54-6647-11e7-96fb-52540021eccc/containers/carts-db/79c40f2a: not mounted
kube2: umount: /var/lib/kubelet/pods/3642ad54-6647-11e7-96fb-52540021eccc/plugins/kubernetes.io~empty-dir/tmp-volume: not mounted
kube2: umount: /var/lib/kubelet/pods/3642ad54-6647-11e7-96fb-52540021eccc/plugins/kubernetes.io~empty-dir/wrapped_default-token-4zxvh: not mounted
kube0: umount: /var/lib/kubelet/pods/2114fde9-6646-11e7-96fb-52540021eccc/containers/weave/2ad3c710: not mounted

## now we need to reboot the nodes
[root@kube0 install]# pdsh -g nodes reboot
kube3: Connection to kube3 closed by remote host.
pdsh@kube0: kube3: ssh exited with exit code 255
kube2: Connection to kube2 closed by remote host.
pdsh@kube0: kube2: ssh exited with exit code 255
kube1: Connection to kube1 closed by remote host.
pdsh@kube0: kube1: ssh exited with exit code 255
[root@kube0 install]# reboot
```

Alternative: `kubeadm` provides a `reset` argument to undo its configuration. *Transcript*:
```sh
## use kubeadm reset argument
pdsh -g kubes kubeadm reset
```

Output:
```
## here we use kubeadm reset to revert to a clean state
[root@kube0 install]# kubeadm reset
[preflight] Running pre-flight checks
[reset] Stopping the kubelet service
[reset] Unmounting mounted directories in "/var/lib/kubelet"
[reset] Removing kubernetes-managed containers
[reset] Deleting contents of stateful directories: [/var/lib/kubelet /etc/cni/net.d /var/lib/dockershim /var/lib/etcd]
[reset] Deleting contents of config directories: [/etc/kubernetes/manifests /etc/kubernetes/pki]
[reset] Deleting files: [/etc/kubernetes/admin.conf /etc/kubernetes/kubelet.conf /etc/kubernetes/controller-manager.conf /etc/kubernetes/scheduler.conf]
```


## Bootstrap

In this transcript we get kubernetes running prior to a network.

*Transcript*:

```sh
## to make kubeadm happy
pdsh -g kubes modprobe -v br_netfilter
pdsh -g kubes 'echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables'

## make this persistent across boots
cat > netfilter.conf <<EOF
br_netfilter
EOF

pdcp -g kubes netfilter.conf /etc/modules-load.d/netfilter.conf

cat > 10-docker.conf <<EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

pdcp -g kubes 10-docker.conf /etc/sysctl.d/10-docker.conf

## now bootstrap the master node using kubeadm
kubeadm init

```

Output:
```
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
[add-ons] Applied essential add-on: kube-proxy
[add-ons] Applied essential add-on: kube-dns

Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run (as a regular user):

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  http://kubernetes.io/docs/admin/add-ons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join --token 96f75e.440cb6581dc488ba 192.168.125.100:6443
```

Enable non-root cluster admin:

*Transcript*:
```sh
## wait for kubeadm init to finish, then enable non-root cluster-admin user

sudo -u centos bash <<'EOF'
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

At this stage we have successfully bootstraped kubernetes without network. The user 'centos' is a cluster superadmin. This user is authenticated and authorised to kubernetes using the credentials in `~centos/.kube/config`.

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
gcr.io/google_containers/etcd-amd64                      3.0.17              243830dae7dd        4 months ago        168.9 MB
gcr.io/google_containers/pause-amd64                     3.0                 99e59f495ffa        14 months ago       746.9 kB
```
