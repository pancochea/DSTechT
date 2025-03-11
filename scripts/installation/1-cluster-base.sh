BASE_PATH="${DEEPSET_BASE_PATH:-/opt/deepset}"

SCRIPTS_PATH="$BASE_PATH/scripts"

source $SCRIPTS_PATH/utils.sh

cat $MANIFESTS_PATH/metallb.yaml | grep "#ADD" > /dev/null 
MEATL_LB_CONFIGURED=$?

if ! [ $MEATL_LB_CONFIGURED -eq 0 ]; then
    echo "[ERROR] Metallb not configured, please add your local ip to $MANIFESTS_PATH/metallb.yaml"
    exit 1
fi


if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ]; then
    echo "Running only for $1"
    install_helm_chart $1 $2 $3
    exit $?
fi

install_helm_chart openebs openebs openebs
install_helm_chart metallb metallb metallb
install_helm_chart ingress-nginx ingress-nginx nginx

