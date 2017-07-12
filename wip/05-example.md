# Kubernetes By Example

http://kubernetesbyexample.com/pods/

*Transcript*:
```sh
kubectl run sise --image=mhausenblas/simpleservice:0.5.0 --port=9876
```

Output:
```
[root@kube0 centos]# kubectl run sise --image=mhausenblas/simpleservice:0.5.0 --port=9876
deployment "sise" created
```

Verify:
```
[root@kube0 centos]# kubectl get po
NAME                     READY     STATUS              RESTARTS   AGE
sise-2257828502-w3xgk    0/1       ContainerCreating   0          1m

[root@kube0 centos]# kubectl describe pod sise-2257828502-w3xgk | grep IP:
IP:             10.44.0.14

[root@kube0 centos]# curl http://10.44.0.14:9876/info
{"host": "10.44.0.14:9876", "version": "0.5.0", "from": "10.32.0.1"}

```

*Transcript*:
```sh
## we have a deployment created by the kubectl run command, we cannot merely delete the pod
kubectl delete deployment sise

## let's only create a pod
kubectl create -f https://raw.githubusercontent.com/mhausenblas/kbe/master/specs/pods/pod.yaml

kubectl get pods
```

Output:
```
[root@kube0 centos]# kubectl delete deployment sise
deployment "sise" deleted

[root@kube0 centos]# kubectl create \
    -f https://raw.githubusercontent.com/mhausenblas/kbe/master/specs/pods/pod.yaml
pod "twocontainers" created

[root@kube0 centos]# kubectl get po -o wide
NAME            READY     STATUS    RESTARTS   AGE       IP           NODE
twocontainers   2/2       Running   0          5m        10.42.0.13   kube3

## pod only, no deployment
[root@kube0 centos]# kubectl get deploy
No resources found.

## 
[root@kube0 centos]# ssh kube3 docker images | grep mhaus
docker.io/mhausenblas/simpleservice         0.5.0               601917f29430        11 weeks ago        682.6 MB

[root@kube0 centos]# kubectl exec twocontainers -c shell -i -t -- bash
[root@twocontainers /]# curl localhost:9876/info
{"host": "localhost:9876", "version": "0.5.0", "from": "127.0.0.1"}[root@twocontainers /]# 

```
