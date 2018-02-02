# heat-kubeadm

Heat stack template for installing Kubernetes with kubeadm.

## Installation

On the machine that will be used to install this stack we need
following packages:

* python-openstackclient - for general OpenStack functions
* python-heatclient - for heat-specific CLI functions
* kubectl - to access Kubernetes cluster
* helm - to install Spinnaker on top of Kubernetes

Basic steps are:

1. Ensure all necessary Floating IPs are created
1. Prepare template config
1. Create stack
1. Wait for it to finish
1. Configure kubectl
1. Install Spinnaker with Helm

### Floating IPs

We assume that floating IPs with necessary parameters are already created.

First you need to find out IDs of these floating IPs:

```
$ openstack floating ip list
+--------------------------------------+---------------------+------------------+------+--------------------------------------+----------------------------------+
| ID                                   | Floating IP Address | Fixed IP Address | Port | Floating Network                     | Project                          |
+--------------------------------------+---------------------+------------------+------+--------------------------------------+----------------------------------+
| 24776f99-7599-4bdd-8a1a-1a551180eb4a | 172.17.50.93        | None             | None | 3e868882-d59e-416a-90a1-48cc04cab723 | bf35dfbf572e41dab0ceb9b8085da879 |
| 851660f0-3648-4560-9403-c68647e4aa99 | 172.17.49.222       | None             | None | 3e868882-d59e-416a-90a1-48cc04cab723 | bf35dfbf572e41dab0ceb9b8085da879 |
| 32cc96ef-8590-4785-b660-c6e773c97f3d | 172.17.48.254       | None             | None | 3e868882-d59e-416a-90a1-48cc04cab723 | bf35dfbf572e41dab0ceb9b8085da879 |
| 6c9d42cb-ad7e-46dd-aca8-9a5cc628e5de | 172.17.49.237       | None             | None | 3e868882-d59e-416a-90a1-48cc04cab723 | bf35dfbf572e41dab0ceb9b8085da879 |
+--------------------------------------+---------------------+------------------+------+--------------------------------------+----------------------------------+
```

Your values here will differ. You need to select IP addresses that you are
going to use for your cluster.

### Prepare template config

Here is an example of environment file (lets call it `env.yaml`) that can be
used to create the stack:

```yaml
parameters:
    key_name: mysshkey
    image: ubuntu-16-04-amd64-cloudimg    
    master_floating_ip: 24776f99-7599-4bdd-8a1a-1a551180eb4a
    slave_floating_ips: 851660f0-3648-4560-9403-c68647e4aa99,32cc96ef-8590-4785-b660-c6e773c97f3d,6c9d42cb-ad7e-46dd-aca8-9a5cc628e5de
    availability_zone: az1
    public_network_id: extnet
```

Here you must specify ID of one floating IP for master in `master_floating_ip`
and 3 comma-separated IDs of floating IPs for slaves in `slave_floating_ips`.

You must also specify name of your SSH key in OpenStack in `key_name`,
name or ID of image to use for nodes in `image` and availability zone for
VMs in `availability_zone`.

All other options and their descriptions can be found at the top of
`stack.yaml` file.

### Create Heat stack

To create Heat stack, issue command:

```bash
$ openstack stack create -t stack.yaml -e env.yaml teststack --wait                                                                                        ~/src/github.com/YorikSar/heat-kubeadm
```

If you do specify `--wait` flag, output should look like this:
```
2018-02-02 13:36:43Z [teststack]: CREATE_IN_PROGRESS  Stack CREATE started
2018-02-02 13:36:44Z [teststack.token_part_2]: CREATE_IN_PROGRESS  state changed
2018-02-02 13:36:44Z [teststack.token_part_2]: CREATE_COMPLETE  state changed
2018-02-02 13:36:45Z [teststack.random_string]: CREATE_IN_PROGRESS  state changed
2018-02-02 13:36:45Z [teststack.random_string]: CREATE_COMPLETE  state changed
2018-02-02 13:36:45Z [teststack.internal_net]: CREATE_IN_PROGRESS  state changed
2018-02-02 13:36:46Z [teststack.internal_net]: CREATE_COMPLETE  state changed
2018-02-02 13:36:46Z [teststack.internal_router]: CREATE_IN_PROGRESS  state changed
2018-02-02 13:36:46Z [teststack.master_config]: CREATE_IN_PROGRESS  state changed
2018-02-02 13:36:46Z [teststack.master_config]: CREATE_COMPLETE  state changed
2018-02-02 13:36:46Z [teststack.internal_subnet]: CREATE_IN_PROGRESS  state changed
2018-02-02 13:36:46Z [teststack.internal_router]: CREATE_COMPLETE  state changed
2018-02-02 13:36:46Z [teststack.master_floatingip]: ADOPT_IN_PROGRESS  state changed
2018-02-02 13:36:46Z [teststack.master_floatingip]: ADOPT_COMPLETE  state changed
2018-02-02 13:36:46Z [teststack.master_floatingip]: CHECK_COMPLETE  CHECK not supported for OS::Neutron::FloatingIP
2018-02-02 13:36:46Z [teststack.internal_subnet]: CREATE_COMPLETE  state changed
2018-02-02 13:36:47Z [teststack.token_part_1]: CREATE_IN_PROGRESS  state changed
2018-02-02 13:36:47Z [teststack.token_part_1]: CREATE_COMPLETE  state changed
2018-02-02 13:36:47Z [teststack.internal_router_interface]: CREATE_IN_PROGRESS  state changed
2018-02-02 13:36:47Z [teststack.token]: CREATE_IN_PROGRESS  state changed
2018-02-02 13:36:47Z [teststack.token]: CREATE_COMPLETE  state changed
2018-02-02 13:36:47Z [teststack.internal_router_interface]: CREATE_COMPLETE  state changed
2018-02-02 13:36:48Z [teststack.master]: CREATE_IN_PROGRESS  state changed
2018-02-02 13:36:58Z [teststack.master]: CREATE_COMPLETE  state changed
2018-02-02 13:36:59Z [teststack.slaves]: CREATE_IN_PROGRESS  state changed
2018-02-02 13:37:14Z [teststack.slaves]: CREATE_COMPLETE  state changed
2018-02-02 13:37:14Z [teststack]: CREATE_COMPLETE  Stack CREATE completed successfully
+---------------------+----------------------------------------+
| Field               | Value                                  |
+---------------------+----------------------------------------+
| id                  | de74c522-57c7-40ab-8111-0deb7ad1d7e2   |
| stack_name          | teststack                              |
| description         | Deploy Kubernetes cluster with kubeadm |
| creation_time       | 2018-02-02T13:36:43Z                   |
| updated_time        | None                                   |
| stack_status        | CREATE_COMPLETE                        |
| stack_status_reason | Stack CREATE completed successfully    |
+---------------------+----------------------------------------+
```

The line `[teststack]: CREATE_COMPLETE  Stack CREATE completed successfully`
means that stack has been created successfully.

### Wait for Kubernetes to be installed

After stack creation is completed, you can SSH to master node with key you've
specified in environment file:

```bash
ssh -i mysshkey ubuntu@172.17.50.93
```

There you can check if Kubernetes deploymentis is in progress:

```bash
$ journalctl -fu kubeadm-install
```

This command will output lines from log of kubernetes installation. Last lines
are expected to be like these:

```
Feb 02 13:38:25 k8s-qyyenxoh-master bash[3612]: + kubectl apply -f /root/tiller.yaml
Feb 02 13:38:25 k8s-qyyenxoh-master bash[3612]: serviceaccount "tiller" created
Feb 02 13:38:25 k8s-qyyenxoh-master bash[3612]: clusterrolebinding "tiller" created
Feb 02 13:38:25 k8s-qyyenxoh-master bash[3612]: deployment "tiller-deploy" created
Feb 02 13:38:25 k8s-qyyenxoh-master bash[3612]: service "tiller-deploy" created
```

Press Ctrl-C to exit the command.

### Configure kubectl

First fetch config from master node:

```bash
$ scp ubuntu@172.17.50.93:.kube/config kubeconfig
```

Then you need to replace IP address in the config from internal IP to floating
IP:

```bash
$ sed -i 's#https://.*:#https://172.17.50.93:#' kubeconfig
```

Now you can verify that config is working:

```bash
$ export KUBECONFIG=kubeconfig
$ kubectl get nodes
NAME                   STATUS    AGE       VERSION
k8s-qyyenxoh-master    Ready     17m       v1.8.7
k8s-qyyenxoh-slave-0   Ready     16m       v1.8.7
k8s-qyyenxoh-slave-1   Ready     16m       v1.8.7
k8s-qyyenxoh-slave-2   Ready     16m       v1.8.7
```

If you don't see all nodes there or some of them are in NotReady state, it
means that cluster is not up yet. You should repeat `kubectl get nodes` again
untill you see all nodes in Ready state.

### Install Spinnaker with Helm

Tiller (Helm server component) is already installed on the cluster, so you need
to initialize only client side:

```bash
$ helm init --client-only
Creating /home/ubuntu/.helm
Creating /home/ubuntu/.helm/repository
Creating /home/ubuntu/.helm/repository/cache
Creating /home/ubuntu/.helm/repository/local
Creating /home/ubuntu/.helm/plugins
Creating /home/ubuntu/.helm/starters
Creating /home/ubuntu/.helm/cache/archive
Creating /home/ubuntu/.helm/repository/repositories.yaml
$HELM_HOME has been configured at /home/ubuntu/.helm.
Not installing Tiller due to 'client-only' flag having been set
Happy Helming!
```

Then you need to add Mirantis chart repository:

```bash
$ helm repo add mirantisworkloads https://mirantisworkloads.storage.googleapis.com/
"mirantisworkloads" has been added to your repositories
```

Now you can install Spinnaker from Helm chart:

```bash
$ helm install --set jenkins.Master.NeverDownloadPlugins=true,rbac.enabled=true --name spinnaker mirantisworkloads/spinnaker --wait
```

It will run for some time and then output information about created release
object as well as all resources created in Kubernetes for it.

After it finishes, you can determine NodePort assigned to its UI using:
```bash
$ kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services spinnaker-spinnaker-deck
31860
```

Now you can use it with one of your floating IPs to see Spinnaker UI in your
browser: `http://172.17.50.93:31860`
