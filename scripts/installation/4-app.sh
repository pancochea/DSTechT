BASE_PATH="${DEEPSET_BASE_PATH:-/opt/deepset}"

SCRIPTS_PATH="$BASE_PATH/scripts"

source $SCRIPTS_PATH/utils.sh

set -e
helm lint $OWNED_HELM_SRC/haystack
helm package -d $CHARTS_PATH $OWNED_HELM_SRC/haystack
install_helm_chart haystack haystack haystack
