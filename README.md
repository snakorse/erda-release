# Erda Installation Tools

We have successfully installed Erda in the following software:

- Kubernetes 1.18.8
- Docker 19.03.5
- CentOS 7.9
- Helm 3.4.2



## Quickly Started

### Prerequisites

- Kuberentes 1.18.8, We recommand you use ACK Pro ( AliCloud Kubernetes Pro)
  - Each node needs at least 4 core CPU, 16G memory
  - At least 4 Nodes (1 Master and 3 Workers)
  - At least 200G storage in the `/`
  - Need an SLB
  - **Don't Install the ingress component**
- Docker 19.03.5
- CentOS 7 +
- Helm 3.4 +



### Step

1. Git clone the repo on your machine

   > git clone https://github.com/erda-project/erda-release.git


2. Change directory to the erda-release folder

   > cd erda-release


3. Package the tarball

   > bash scripts/build_package.sh

   

4. Copy the tarball to your  **Kubernetes Master** node and make sure the **kubeconfig** file on the ~/.kube/config.

   > scp package/erda-release.tar.gz root@<hostip>:/root

   >  tar -xzvf /root/erda-release.tar.gz

   >  cd erda-release

   

    Then prepare the following environment variables on the **Kubernetes Master Node**.

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
   export ERDA_LABEL_ENABLE=enable
   
   # set the network of registry host mode, `host` and `container` supported, default is `container`
   export ERDA_REGISTRY_NETMODE=host
   ```

   

   **Note:** If you want to use the Erda registry, you need to set the NETMODE to `host` and update the values of  `insecure-registries` in the `/etc/docker/daemon.json` on each node: 

   ```shell
   ...
   	"insecure-registries": [
        "0.0.0.0/0"
       ],
   ...
   ```

   Then restart the docker with `systemctl restart docker`

   

5. Configurate the Kubernetes machine

   > bash scripts/prepare.sh

   
   
6. Install the Erda with helm package

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



7. set admin username and password to push the Erda extensions

   ```shell
   export ERDA_ADMIN_USERNAME=
   export ERDA_ADMIN_PASSWORD=
   
   bash scripts/push-ext.sh
   ```
   
   


8. Write the following URLs to `/etc/hosts` on the **machine where the browser is located**, replace the <SLB> to the real slb ip
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
   <SLB_IP> <orgname>-org.erda-demo.erda.io
   <SLB_IP> test-java.erda-demo.erda.io
   ```


9. Visit the URL `http://dice.erda-demo.erda.io` on your browser machine which set the `/etc/hosts`
   - Note that you need to open the 80, 443 and 6443 ports of SLB




10. set your Kubernetes nodes label with your created organization name
    ```shell
    for i in `kubectl get nodes | grep -v NAME | awk '{print $1}'`;
    do
    	kubectl label node $i dice/org-<orgname>=true --overwrite
    done
    ```