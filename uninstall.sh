#!/bin/bash

if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root" && exit
fi

echo "Removing /usr/local/share/setup-server"

rm -rf /usr/local/share/setup-server

echo "Removing /usr/local/bin/setup-server"

rm -rf /usr/local/bin/setup-server

echo -e "\nDone."
