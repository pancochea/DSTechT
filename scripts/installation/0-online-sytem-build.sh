#!/bin/bash

BASE_PATH="${DEEPSET_BASE_PATH:-/opt/deepset}"

SCRIPTS_PATH="$BASE_PATH/scripts"

source $SCRIPTS_PATH/utils.sh
k0sInstallPath=/usr/local/bin


if ! [ -x "$(command -v docker)" ]; then
    DEB_FILES=("$BINARIES_PATH/docker/*.deb")
    echo "Docker command not found, installing"
    # Add Docker's official GPG key:
    sudo apt-get update -y
    sudo apt-get install ca-certificates curl -y
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
else
    echo "Docker already Installed"
fi

docker ps > /dev/null 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE = 1 ]; then
    set -e
    echo "Cannot run docker from this user, adding $USER to the docker group"
    if ! [ getent group "$GROUP_TO_CHECK" &>/dev/null ]; then
        sudo groupadd docker
    fi

    sudo usermod -aG docker $USER
    newgrp docker
    set +e
fi


if ! [ -x "$(command -v k0s)" ]; then
    echo "Installing k0s"
    curl -sSLf https://get.k0s.sh | sudo sh
    sudo k0s install controller --single
    sudo k0s start

    sleep 3s
    sudo k0s status
    mkdir ~/.kube
    sudo k0s kubeconfig admin > ~/.kube/config
else
    echo "k0s already installed"
fi


if ! [ -x "$(command -v kubectl)" ]; then
    echo "Installing kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
else
    echo "Kubectl command already installed"
fi

if ! [ -x "$(command -v helm)" ]; then
    echo "Installing helm"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | basha
else
    echo "Helm Alreadu installed"
fi
