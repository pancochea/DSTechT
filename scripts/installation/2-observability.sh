BASE_PATH="${DEEPSET_BASE_PATH:-/opt/deepset}"

SCRIPTS_PATH="$BASE_PATH/scripts"

source $SCRIPTS_PATH/utils.sh

install_helm_chart kube-prometheus-stack prometheus-stack prometheus
install_helm_chart alloy alloy alloy
install_helm_chart loki loki loki
