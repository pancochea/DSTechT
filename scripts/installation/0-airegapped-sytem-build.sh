#!/bin/bash

BASE_PATH="${DEEPSET_BASE_PATH:-/opt/deepset}"

SCRIPTS_PATH="$BASE_PATH/scripts"

source $SCRIPTS_PATH/utils.sh
k0sInstallPath=/usr/local/bin

if ! [ "$(detect_arch)" = "amd64" ]; then
    echo "Airgap installation is currently only suported on amd64 architecture, please install the following dependencies:"
    echo "- docker"
    echo "- helm"
    echo "- kubectl"
fi


if ! [ -x "$(command -v docker)" ] && [ "$(detect_arch)" = "amd64" ]; then
    DEB_FILES=("$BINARIES_PATH/docker/*.deb")
    echo "Docker command not found, installing"
    for deb in $DEB_FILES; do
        echo "Installing package $deb..."
        sudo dpkg -i "$deb"
    done
    if [ $? -eq 1 ]; then
        echo "Error installing docker"
        exit 1
    fi
    sudo service docker start
fi

docker ps > /dev/null 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -eq 1 ]; then
    echo "Cannot run docker from this user, adding $USER to the docker group"
    if ! [ getent group "$GROUP_TO_CHECK" &>/dev/null ]; then
        sudo groupadd docker
    fi

    sudo usermod -aG docker $USER
    newgrp docker
fi

echo "Installing local registry"
docker load < $CONTAINERS_PATH/distribution_registry.tar.gz
docker compose -f $SCRIPTS_PATH/docker-compose-registry.yaml up -d


if ! [ -x "$(command -v k0s)" ] && [ "$(detect_arch)" = "amd64" ]; then
    echo "Installing and starting k0s"

    sudo cp "$BINARIES_PATH/$(ls $BINARIES_PATH  | grep k0s)" "$k0sInstallPath/k0s"
    sudo chmod 755 "$k0sInstallPath/k0s"
    sudo k0s install controller --single -c $SCRIPTS_PATH/k0s.yaml
    sudo k0s start
    sleep 3s
    sudo k0s status

    mkdir ~/.kube
    sudo k0s kubeconfig admin > ~/.kube/config
fi


if ! [ -x "$(command -v kubectl)" ] && [ "$(detect_arch)" = "amd64" ]; then
    echo "Installing kubectl"
    sudo install -o root -g root -m 0755 $BINARIES_PATH/kubectl /usr/local/bin/kubectl
fi

if ! [ -x "$(command -v helm)" ] && [ "$(detect_arch)" = "amd64" ]; then
    echo "Installing helm"
    sudo cp $BINARIES_PATH/helm /usr/local/bin/helm
    sudo chmod 755 /usr/local/bin/helm
fi
