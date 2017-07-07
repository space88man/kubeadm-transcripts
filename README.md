# Kubernetes

This is a set of transcripts for learning kubernetes via kubeadm on CentOS/RHEL-like systems.

It is intended to supplement the kubeadm tutorial, filling in some gaps, and
expounding on what kubeadm does. We also make reference to the Custom Cluster from Scratch guide
to understand what choices kubeadm makes, and how it deviates from a hand-crafted cluster.

References:

* kubeadm: https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
* https://kubernetes.io/docs/getting-started-guides/scratch/

## Usage

Based on a set of 4 CentOS 7 VMs on single bridged network, you should be able to get a
kubernetes cluster up and running. We target CentOS 7 so that the commands are as explicit as
possible.

Take care of adjusting passwords, IP addresses, and tokens as needed.

## Prerequisites

* 4 x CentOS 7 VMs, with EPEL repository enabled
* hostnames kube[0-3], with hostname resolvable by `/etc/hosts`
* internet access
* The master node is kube0: it has password-less ssh to kube[1-3]
* Non-root user centos, with password-less ssh and sudo privileges
* Install pdsh, pdsh-mod-genders on all nodes, and the following file `/etc/genders`
  to all nodes
  
    ```
    kube[0-3] kubes
    kube[1-3] nodes
    ```
