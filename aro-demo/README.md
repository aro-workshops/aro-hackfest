ARO Demo
========

Pre-requisites
--------------

* Install JQ (`jq`)
* Install Azure CLI (`az`)
* Install Helm v3 (`helm`)
* Install OpenShift CLI (`oc`)
* Login to Azure `az login` and select the correct subscription `az account set -s <subId>`
* Create an ARO cluster
* Login to OpenShift CLI `oc login ...`

* Create resource group for the Azure resources:

```sh
cp demo-env.sh.template demo-env.sh
# Edit the values in demo-env.sh to match your environment

source ./demo-env.sh

az group create -n $RG_NAME -l $LOCATION
```

* Create an Azure Container Registry (not supported by ASO yet):

```sh
az acr create --resource-group $RG_NAME --name $ACR_NAME --admin-enabled true --sku Standard
```

* Install the Azure Service Operator:

```sh
AZURE_TENANT_ID="$(az account show --query tenantId -o tsv)"
AZURE_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"

# Normally you'd use the subscription scope but for the demo let's scope to a resource group.
az ad sp create-for-rbac \
    -n "http://aso-$RG_NAME" \
    --role contributor \
    --scopes /subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$RG_NAME > aso-sp.json

AZURE_CLIENT_ID="$(jq -r .appId < ./aso-sp.json)"
AZURE_CLIENT_SECRET="$(jq -r .password < ./aso-sp.json)"
AZURE_CLOUD_ENV="AzurePublicCloud"

cat <<EOF > azure-service-operator-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: azureoperatorsettings
stringData:
  AZURE_TENANT_ID: ${AZURE_TENANT_ID}
  AZURE_SUBSCRIPTION_ID: ${AZURE_SUBSCRIPTION_ID}
  AZURE_CLIENT_ID: ${AZURE_CLIENT_ID}
  AZURE_CLIENT_SECRET: ${AZURE_CLIENT_SECRET}
  AZURE_CLOUD_ENV: ${AZURE_CLOUD_ENV}
EOF
```

Install ASO via Helm (not currently working from OperatorHub):

```sh
wget https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml
kubectl apply -f cert-manager.yaml
helm repo add azureserviceoperator https://raw.githubusercontent.com/Azure/azure-service-operator/master/charts
helm repo update

helm upgrade --install aso https://github.com/Azure/azure-service-operator/raw/master/charts/azure-service-operator-0.1.0.tgz \
        --create-namespace \
        --namespace=azureoperator-system \
        --set azureSubscriptionID=$AZURE_SUBSCRIPTION_ID \
        --set azureTenantID=$AZURE_TENANT_ID \
        --set azureClientID=$AZURE_CLIENT_ID \
        --set azureClientSecret=$AZURE_CLIENT_SECRET \
        --set image.repository="mcr.microsoft.com/k8s/azureserviceoperator:latest"
```

Deploy the app and its Azure resources:

```sh
./demo.sh up
./demo.sh status
./demo.sh showSecrets

oc get CosmosDB
oc describe CosmosDB service-tracker-db

oc logs azureoperator-controller-manager-xxxxxx-yyyyy manager -n azureoperator-system -f

oc get AppInsights
oc describe AppInsights  appinsights-demo
```

Check the Azure portal: https://portal.azure.com

Run automation script:

```sh
npm install
source ./demo-env.sh
export SERVICE_TRACKER_URL="https://service-tracker.$APPS_DOMAIN/"
npx taiko automate.js --observe
```

Cleanup:

```sh
./demo.sh down
```

Resource
--------

* https://github.com/Azure/azure-service-operator/tree/master/docs/services
