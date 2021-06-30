#!/bin/bash

__DIR=$(dirname $0)
__TEMP_DIR="/tmp/setup-server"
__TEMP_VARS_FILE="$__TEMP_DIR/extra.yml"
__TEMP_HOSTS_FILE="$__TEMP_DIR/hosts.yml"

trap "rm -rf $__TEMP_DIR" 0

valid_ip() {
	local ip=$1
	local stat=1

	if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		OIFS=$IFS
		IFS='.'
		ip=($ip)
		IFS=$OIFS
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 &&
			${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
		stat=$?
	fi
	return $stat
}

get_ip_addr() {

	read -p 'Enter the IP address of the remote server: ' IP_ADDR
	echo

	[ -z "$IP_ADDR" ] && get_ip_addr

	valid_ip "$IP_ADDR"

	[ "$?" != 0 ] && echo "ERROR: Invalid IP address" &&
		echo && get_ip_addr

}

get_user_name() {
	read -p 'Username: ' CREATE_USER
}

get_user_pass() {

	read -sp 'Password: ' CREATE_PASS
	echo
	read -sp 'Confirm Password: ' CREATE_PASS_CONFIRM
	echo

	if [ "$CREATE_PASS" != "$CREATE_PASS_CONFIRM" ]; then
		echo "ERROR: Passwords did not match"
		get_user_pass
	fi
}

get_user_creds() {
	echo "Enter the credentials for the user that will be created:"
	get_user_name
	get_user_pass
}

get_ssh_key() {

	echo "SSH Key:"
	echo "0) generate a new one"
	echo "1) use existing"

	read -p '0 or 1? ' USE_EXISTING_KEY
	echo

	[ "$USE_EXISTING_KEY" != 0 ] && [ "$USE_EXISTING_KEY" != 1 ] &&
		clear &&
		echo "ERROR: Enter 1 or 0." &&
		get_ssh_key

	if [ "$USE_EXISTING_KEY" = 0 ]; then

		echo "Generating new SSH key"

		read -p "What would you like to call this key?: " SSH_KEY_NAME
		echo

		SSH_KEY_PATH="$HOME/.ssh/$SSH_KEY_NAME"
		SSH_PUBKEY_PATH="$SSH_KEY_PATH.pub"

		ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH"
	fi

	if [ "$USE_EXISTING_KEY" = 1 ]; then
		read -ep "Enter path to existing ssh key: " -i "$HOME/.ssh/" SSH_KEY_PATH
		echo
	fi
}

get_remote_pass() {
	echo "Enter the password for root@$IP_ADDR:"
	read -sp "Password: " REMOTE_PASS
	echo

}

write_data() {
	# Vars
	cat <<EOF >"$__TEMP_VARS_FILE"
---
sys_packages: [ 'curl', 'vim', 'git', 'gnupg', 'zsh' ]
docker_packages: ['apt-transport-https', 'ca-certificates', 'software-properties-common' ]
docker_compose_version: 1.29.2

create_user_name: $CREATE_USER
create_user_pass: $CREATE_PASS
EOF

	# Host
	cat <<EOF >"$__TEMP_HOSTS_FILE"
	$IP_ADDR 
EOF

}

[ ! -d "$__TEMP_DIR" ] && mkdir "$__TEMP_DIR"

clear

echo -e "### REMOTE MACHINE ### \n"

get_ip_addr
get_remote_pass

clear

echo -e "### NEW USER ### \n"

get_ssh_key
get_user_creds

clear 

write_data

SSHPASS="$REMOTE_PASS" sshpass -e ssh-copy-id -o PubkeyAuthentication=no -fi "$SSH_KEY_PATH" "root@$IP_ADDR"

echo "Starting ansible playbook"

SSHPASS="$REMOTE_PASS" sshpass -e ansible-playbook --ask-pass --user root -e "@$__TEMP_VARS_FILE" -i "$__TEMP_HOSTS_FILE" "$__DIR/playbook.yml"
