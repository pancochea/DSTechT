BASE_PATH="${DEEPSET_BASE_PATH:-/opt/deepset}"

SCRIPTS_PATH="$BASE_PATH/scripts"

source $SCRIPTS_PATH/utils.sh


install_helm_chart vault vault vault

TOKEN=$(kubectl exec -ti vault-0 -n vault -- vault operator init | awk '/Initial Root Token:/ {print $NF}')
ENCODED_TOKEN=$(echo -n "$TOKEN" | base64);
sed -i "s/#ROOTTOKEN#/$ENCODED_TOKEN/g" $MANIFESTS_PATH/external-secrets.yaml

kubectl exec -ti vault-0 -n vault -- vault operator unseal "QmL8XNjVbOAzK1WYfCpMEgR+7uTI6oJZS3CEyKdxMvo="

install_helm_chart external-secrets external-secrets external-secrets