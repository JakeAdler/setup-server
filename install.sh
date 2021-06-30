#!/bin/bash

if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root" && exit
fi

__TEMP_DIR="/tmp/setup-server"

trap "rm -rf $__TEMP_DIR" 0

mkdir "$__TEMP_DIR"


git clone 'https://github.com/JakeAdler/setup-server' "$__TEMP_DIR/repo"

rm -rf "$__TEMP_DIR/repo/.git"

SHARE_DIR="/usr/local/share/setup-server"

echo "Moving shared files into $SHARE_DIR"

if [ ! -d "$SHARE_DIR" ]; then
  mkdir $SHARE_DIR
else
  rm -rf $SHARE_DIR/*
fi

mv $__TEMP_DIR/repo/* /usr/local/share/setup-server/


SCRIPT_FILE="/usr/local/share/setup-server/setup-server.sh"
BIN_PATH="/usr/local/bin/setup-server"

[ ! -f "$BIN_PATH" ] && 
  echo "Linking $SCRIPT_FILE --> $BIN_PATH" && 
  ln -s "$SCRIPT_FILE" "$BIN_PATH"

echo -e "\nDone."
