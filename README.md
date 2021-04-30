# erda-release

The erda release installer  pass the test on following software version:

- Kubernetes 1.18.8
- Docker 19.03.5
- CentOS 7.9

## Quickly Started

### Prepared

- Kuberentes 1.18.8, We recommand you use ACK Pro ( AliCloud Kubernetes Pro)
  - The minimal node resource is 4 CPU 16G Memory
  - At least 4 Node (1 Master and 3 Worker)
  - 200G Storage on `/`
  - **Don't Install the ingress**
- Docker 19.03.5
- CentOS 7
- Helm 3

### Step

1. git clone this repo on your machine

   > git clone https://github.com/erda-project/erda-release.git

2. change directory to the erda-release folder

   > cd erda-release
  
3. package the tar ball

   > bash scripts/build_package.sh

4. copy the tar ball to your  **Kubernetes Master** node and make sure the **kubeconfig** file on the ~/.kube/config, then prepare the following enviroment variables on the **Kubernetes Master Node**.

   >  scp package/erda-release.tar.gz root@<hostip>:/root

   >  tar -xzvf /root/erda-release.tar.gz

   >  cd erda-release

   ```shell
   # specify the kuberentes namepsace to install erda components, default  value is `default`.
   export ERDA_NAMESPACE=default
   
   # specify the erda size to install erda components, demo supported only, default value is `demo`.
   export ERDA_SIZE=demo
   
   # enable the netportal, `enable` and `disable` supported, default is `disable`
   export ERDA_NETPORTAL_ENABLE=enable
   
   # enable the netdata, `enable` and `disable` supported, default is `disable`
   export ERDA_NETDATA_ENABLE=enable
   
   # set necessary label of erda to the Kubernetes, `enable` and `disable` supported, default is `enable`
   export ERDA_LABEL_ENABLE="enable"
   ```

5. Configurate the Kubernetes machine

   > bash scripts/prepare.sh

6. Install the erda with helm package

   ```shell
   # install erda-base
   helm install package/erda-base-0.1.0.tgz --generate-name
   # wating all pods is running with `kubectl`
   kubectl get pods
   
   # install erda-addons
   helm install package/erda-addons-0.1.0.tgz --generate-name
   # wating all pods is running with `kubectl`
   kubectl get pods
   
   # install erda
   helm install package/erda-0.1.0.tgz --generate-name
   # wating all pods is running with `kubectl`
   kubectl get pods
   ```

7. set admin username and password to push the erda extensions
  ```shell
  export ERDA_ADMIN_USERNAME=
  export ERDA_ADMIN_PASSWORD=
  
  bash scripts/push-ext.sh
  ```

8. set `/etc/hosts` with the following urls on **your browser local machine**
   ```
   <SLB_IP> harbor.erda.cloud
   <SLB_IP> nexus.erda-demo.erda.io
   <SLB_IP> sonar.erda-demo.erda.io
   <SLB_IP> dice.erda-demo.erda.io
   <SLB_IP> uc-adaptor.erda-demo.erda.io
   <SLB_IP> soldier.erda-demo.erda.io
   <SLB_IP> gittar.erda-demo.erda.io
   <SLB_IP> collector.erda-demo.erda.io
   <SLB_IP> hepa.erda-demo.erda.io
   <SLB_IP> openapi.erda-demo.erda.io
   <SLB_IP> uc.erda-demo.erda.io
   <SLB_IP> erda-test-org.erda-demo.erda.io
   <SLB_IP> test-java.erda-demo.erda.io
   ```

9. Visit the url `http://dice.erda-demo.erda.io` on your browser
	- open slb 80, 443 and 6443 ports

10. set your kuberentes nodes label with your create orgname
	```shell
	for i in `kubectl get nodes | grep -v NAME | awk '{print $1}'`;
	do
		kubectl label node $i dice/org-<orgname>=true --overwrite
	done
	```