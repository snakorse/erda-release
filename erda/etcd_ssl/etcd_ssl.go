package main

import (
	"context"
	"fmt"
	"io/ioutil"
	v1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"os"
	"os/exec"
	"sigs.k8s.io/yaml"
	"time"

	//
	// Uncomment to load all auth plugins
	// _ "k8s.io/client-go/plugin/pkg/client/auth"
	//
	// Or uncomment to load specific auth plugins
	// _ "k8s.io/client-go/plugin/pkg/client/auth/azure"
	// _ "k8s.io/client-go/plugin/pkg/client/auth/gcp"
	// _ "k8s.io/client-go/plugin/pkg/client/auth/oidc"
	// _ "k8s.io/client-go/plugin/pkg/client/auth/openstack"
)

func main() {
	// creates the in-cluster config
	config, err := rest.InClusterConfig()
	if err != nil {
		panic(err.Error())
	}
	// creates the clientset
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err.Error())
	}

	if err = createSecretsFile(); err != nil {
		fmt.Printf("Error: %v\n", err)
		panic(err.Error())
	}

	createEtcdSecretsByK8sClient(clientset, "./etcd-server-secret.yaml")
	createEtcdSecretsByK8sClient(clientset, "./etcd-client-secret.yaml")
}

func createSecretsFile() error {
	ctx, calcel := context.WithTimeout(context.Background(), 30 * time.Second)
	defer calcel()

	cmd := exec.CommandContext(ctx, "./generate_ssl.sh")
	err := cmd.Start()
	if err != nil {
		panic(err.Error())
	}
	fmt.Printf("Waiting for generate ssl files for etcd...\n")
	err = cmd.Wait()
	return err

}

func createEtcdSecretsByK8sClient(cli *kubernetes.Clientset, filename string) {
	_, err := os.Stat(filename)
	if err != nil {
		if os.IsNotExist(err) {
			fmt.Printf("Error creating etcd secrets: file %s not exist.\n", filename)
			panic(err.Error())
		} else {
			fmt.Printf("Error creating etcd secrets: %v.\n", err)
			panic(err.Error())
		}
	}

	yamlFile, err := ioutil.ReadFile(filename)
	if err != nil {
		fmt.Println(err.Error())
		panic(err.Error())
	}
	var secret v1.Secret

	err = yaml.Unmarshal(yamlFile, &secret)
	if err != nil {
		fmt.Println(err.Error())
		panic(err.Error())
	}

	_, err = cli.CoreV1().Secrets(secret.Namespace).Get(context.TODO(), secret.Name, metav1.GetOptions{})
	if err == nil {
		fmt.Printf("Error creating etcd secrets: secret %s has existed in namespace %s \n", secret.Name, secret.Namespace)
		panic("Error creating etcd secrets: secret %s has existed in namespace %s \n")
	} else {
		if errors.IsNotFound(err) {
			_, err = cli.CoreV1().Secrets(secret.Namespace).Create(context.TODO(), &secret, metav1.CreateOptions{})
			if err != nil {
				panic(err.Error())
			}
			fmt.Printf("Create secret %s in namespace %s by file %s successfully.\n", secret.Name, secret.Namespace, filename)
		} else if err != nil {
			panic(fmt.Errorf("Error creating etcd secrets: can not detect secret %s in namespace %s exist or not", secret.Name, secret.Namespace).Error())
		}
	}

}