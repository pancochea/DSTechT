BASE_PATH="${DEEPSET_BASE_PATH:-/opt/deepset}"

CHARTS_PATH="$BASE_PATH/charts"
MANIFESTS_PATH="$CHARTS_PATH/manifests"
OWNED_HELM_SRC="$CHARTS_PATH/src"
VALUES_PATH="$CHARTS_PATH/values"

RESOURCES_PATH="$BASE_PATH/resources"
CONTAINERS_PATH="$RESOURCES_PATH/containers"
BINARIES_PATH="$RESOURCES_PATH/bin"

install_helm_chart() {
    local chart_name=$1
    local release_name=$2
    local namespace=$3

    local chart_path=$(ls -d $CHARTS_PATH/$chart_name-*)    
    local values_file="$VALUES_PATH/$release_name.yaml"
    local manifests_file="$MANIFESTS_PATH/$release_name.yaml"
    echo $manifests_file
    #If I want this scripts to be idempotent, first I need to check if the 
    if helm list -n "$namespace" | grep -q "^$release_name\b"; then
        echo "Release '$release_name' already installed '$namespace'."
        if [ -f "$values_file" ]; then
            echo "[UPDATING] $chart_name with found values file for $chart_name '$values_file'..."
            helm upgrade "$release_name" "$chart_path" -f "$values_file" --namespace "$namespace" --wait
            echo "--------------------------------------------------------"
        fi
    else
        if [ -f "$values_file" ]; then
            echo "[INSTALLING] $chart_name with found values file for $chart_name '$values_file'..."
            helm install "$release_name" "$chart_path" -f "$values_file" --namespace "$namespace" --create-namespace --wait
            echo "--------------------------------------------------------"
        else
            echo "[INSTALLING] Installing $chart_name"
            helm install "$release_name" "$chart_path" --namespace "$namespace" --create-namespace --wait
            echo "--------------------------------------------------------"
        fi
    fi

    if [ -f "$manifests_file" ]; then
        echo "Detected manifest files for $release_name, applying"
        kubectl apply -f $manifests_file
        echo "--------------------------------------------------------"
    fi
}

detect_arch() {
  arch="$(uname -m)"
  case "$arch" in
    amd64|x86_64) echo "amd64" ;;
    arm64|aarch64) echo "arm64" ;;
    armv7l|armv8l|arm) echo "arm" ;;
    *) echo "Unsupported processor architecture: $arch" 1>&2; return 1 ;;
  esac
  unset arch
}
