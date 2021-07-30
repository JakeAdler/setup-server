#!/usr/bin/env bash

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

get_new_ssh_key() {
	echo "Generating new SSH key"

	read -p "What would you like to call this key?: " SSH_KEY_NAME
	echo

	SSH_KEY_PATH="$HOME/.ssh/$SSH_KEY_NAME"
	SSH_PUBKEY_PATH="$SSH_KEY_PATH.pub"

	ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH"
}

get_existing_ssh_key() {
	read -ep "Enter path to existing ssh key: " -i "$HOME/.ssh/" SSH_KEY_PATH
	echo
}

get_ssh_key() {

	echo "Adding SSH key to remote machine:"
	echo "0) generate a new one"
	echo "1) use existing"

	read -p '0 or 1? ' USE_EXISTING_KEY
	echo

	[ "$USE_EXISTING_KEY" != 0 ] && [ "$USE_EXISTING_KEY" != 1 ] &&
		clear &&
		echo "ERROR: Enter 1 or 0." &&
		get_ssh_key

	if [ "$USE_EXISTING_KEY" = 0 ]; then
		get_new_ssh_key
	fi

	if [ "$USE_EXISTING_KEY" = 1 ]; then
		get_existing_ssh_key
	fi
}

get_remote_user() {
	echo "Enter the username to use for SSH for $IP_ADDR:"
	read -p "Username: " REMOTE_USER
	echo
}

get_remote_login_method() {
	PS3="Enter a number: "

	select method in "SSH" "Password"
	do
		echo "Selected method: $method"
		REMOTE_METHOD="$method"
		break
	done
}
get_remote_pass() {
	echo "Enter the password for the REMOTE MACHINE $REMOTE_USER@$IP_ADDR:"
	read -sp "Password: " REMOTE_PASS
	echo

}

write_data() {
	# Vars
	cat <<EOF >"$__TEMP_VARS_FILE"
---
sys_packages: [ 'curl', 'vim', 'git', 'gnupg', 'zsh', 'net-tools' ]
docker_packages: ['apt-transport-https', 'ca-certificates', 'software-properties-common' ]
docker_compose_version: 1.29.2

ansible_become_pass: $REMOTE_PASS
create_user_name: $CREATE_USER
create_user_pass: $CREATE_PASS
remote_user_name: $REMOTE_USER
remote_user_pass: $REMOTE_PASS
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
get_remote_user
get_remote_login_method

[ "$REMOTE_METHOD" = "SSH" ] && get_existing_ssh_key
[ "$REMOTE_METHOD" = "Password" ] && get_remote_pass

clear

echo -e "### NEW USER ### \n"

get_user_creds

[ "$REMOTE_METHOD" = "Password" ] && get_ssh_key


clear

write_data

[ "$REMOTE_METHOD" != "SSH" ] &&
	SSHPASS="$REMOTE_PASS" sshpass -e ssh-copy-id -o PubkeyAuthentication=no -fi "$SSH_KEY_PATH" "$REMOTE_USER@$IP_ADDR"

echo "Starting ansible playbook"

[ "$REMOTE_METHOD" = "SSH" ] &&
	ansible-playbook --private-key "$SSH_KEY_PATH" --user "$REMOTE_USER" -e "@$__TEMP_VARS_FILE" -i "$__TEMP_HOSTS_FILE" "$__DIR/playbook.yml"

[ "$REMOTE_METHOD" = "Password" ] &&
	SSHPASS="$REMOTE_PASS" sshpass -e ansible-playbook --ask-pass --user "$REMOTE_USER" -e "@$__TEMP_VARS_FILE" -i "$__TEMP_HOSTS_FILE" "$__DIR/playbook.yml"
