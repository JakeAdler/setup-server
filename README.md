# setup-server

An ansible playbook and companion script to setup a fresh Ubuntu server.

### Features

- Installs Docker and Docker-compose
- Creates iptables rules that just work with docker
- Creates a new user with sudo, docker, and ssh privileges
- Sets sane and secure `sshd_config`
- Copies new or existing ssh-key 
- Installs zsh and starship prompt for convenience

## Installation 

Short URL
```console
$ curl -fsSL 'https://git.io/JcZ7D' | sudo bash
```
Full URL
```console
$ curl -fsSL 'https://raw.githubusercontent.com/JakeAdler/setup-server/master/install.sh' | sudo bash
```

You can also run either of the following commands to update the script.

## Usage

```console
$ setup-server
```

## Uninstall

```console
$ sudo /usr/local/share/setup-server/uninstall.sh
```
