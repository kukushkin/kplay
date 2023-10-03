# kplay

Run your project in a container inside a `minikube` k8s cluster.


## Prerequisites

To use `kplay` you need to have the following set up on your machine:

* Ruby 2.7+
* [minikube](https://minikube.sigs.k8s.io/docs/)
* Docker image(s) with your development environment, 
  e.g. [like this one](https://github.com/kukushkin/devenv/tree/master/images/dev)

## Installation

Install `kplay` gem for your user only:

```bash
gem i kplay
```

Or system-wide:
```bash
sudo gem i kplay
```

## How to use


Run `kplay help` to list all available commands:
```bash
$ kplay help

Commands:
  kplay config          # Displays local configuration
  kplay help [COMMAND]  # Describe available commands or one specific command
  kplay info            # Displays environment info
  kplay open            # Opens a shell session into the container
  kplay play            # (default) Starts the container and opens a shell session into it
  kplay pod_config      # Displays the pod config
  kplay start           # Starts a container (pod) with the local folder mounted inside
  kplay status          # Displays the cluster and container (pod) status
  kplay stop            # Stops the container (pod) associated with the local folder

Options:
  v, [--verbose], [--no-verbose]

```

### `kplay play` or `kplay` (with no arguments)

Starts a development container, mounts your project in it 
and opens a shell into it.

Change to your projects directory on your machine and run `kplay` with no arguments:

```bash
username:~ $ cd projects/hello
username:hello $ kplay
pod/hello configured
hello:/hello $ 
```

This runs a container using `dev` as the default name of the development 
Docker image. You can pass an argument to use a different Docker image:

```bash
kplay -i my-dev-image
```

When you exit the shell, the container is automatically stopped.

### `kplay start` and `kplay open`

The default behaviour (`kplay play`) opens a shell for you, but after your exit it the container is automatically stopped. This can be a limitation: you may want to keep the container running or you may need to open more than one shell into that container.

In this case you can separately start the container in a "detached" mode:

```bash
username:~ $ cd projects/hello
username:hello $ kplay start
pod/hello configured
username:hello $
```

The container should be running now, which you can verify by listing the k8s pods: 

```bash
username:hello $ kubectl get pods
NAME              READY   STATUS    RESTARTS        AGE
hello             1/1     Running   0               9s
```

Now to open a shell into it, run `kplay open` from the project folder:

```bash
username:hello $ kplay open
hello:hello $ 
```

This way you can open several sessions into the same container! 
Simply run `kplay open` from the project folder in a different terminal
window or tab.

When you exit the shell in the container, it will still keep running. 
If you are done with it, you will need to stop the container explicitly
by running `kplay stop` from your project folder:

```bash
username:hello $ kplay stop
pod "hello" deleted
username:hello $
```

## Configuration

You can pass some parameters as arguments to `kplay` commands, but much
more convenient is to configure the global or project specific defaults.

`kplay` looks for the configuration files in:
* `~/.kplay/config` for global defaults
* `.kplay` in the local (current) folder for project-specific defaults

Settings in the `.kplay` in the local folder supercede the settings
found the global config file.

Each `kplay` configuration file is a YAML document with the following 
structure:

```yaml=

# Name of the Docker image to use for the development container 
image: ruby-dev

# Path inside the container where the project folder is going to be mounted
mount_path: "/${name}"

# Size of the shared memory volume (/dev/shm) inside the container
shm_size: 64Mi

# Command and its args to run inside the container
# when opening a shell into it
shell: "/bin/bash"  
shell_args:
- "-c"
- cd /${name}; exec "${SHELL:-sh}"

# Grace period (seconds) to respect when stopping containers
stop_grace_period: 15

# Custom entries to add to the /etc/hosts file inside the container
etc_hosts:
- "1.1.1.1 test-host-alpha"
- "2.2.2.2 test-host-beta"

# Additional volumes/files to be mounted inside the container
volumes:
- "~/.ssh/id_rsa:/root/.ssh/id_rsa"
- "~/.gitconfig:/root/.gitconfig"
```


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

