#!/bin/bash

buildApp() {
    source ./demo-env.sh

    az acr build -t hackfest/data-api:$DATA_API_TAG -r $ACR_NAME --no-logs -o json ./app/data-api
    az acr build -t hackfest/flights-api:$FLIGHTS_API_TAG -r $ACR_NAME --no-logs -o json ./app/flights-api
    az acr build -t hackfest/quakes-api:$QUAKES_API_TAG -r $ACR_NAME --no-logs -o json ./app/quakes-api
    az acr build -t hackfest/weather-api:$WEATHER_API_TAG -r $ACR_NAME --no-logs -o json ./app/weather-api
    az acr build -t hackfest/service-tracker-ui:$SERVICE_TRACKER_UI_TAG -r $ACR_NAME --no-logs -o json ./app/service-tracker-ui
}

addAcrPullSecret() {

    source ./demo-env.sh
    
    ACR_LOGIN_SERVER="$(az acr show --name $ACR_NAME --resource-group $RG_NAME --query loginServer -o tsv)"
    ACR_USERNAME="$(az acr credential show --resource-group $RG_NAME --name $ACR_NAME --query username -o tsv)"
    ACR_PASSWORD="$(az acr credential show --resource-group $RG_NAME --name $ACR_NAME --query passwords[0].value -o tsv)"

    oc create secret docker-registry arodemoscb-acr --docker-server=$ACR_LOGIN_SERVER \
            --docker-username=$ACR_USERNAME --docker-password=$ACR_PASSWORD \
            --docker-email=noone@example.com

    oc get secrets arodemoscb-acr

    oc patch serviceaccount default -p '{"imagePullSecrets": [{"name": "arodemoscb-acr"}]}'
}

removeAcrPullSecret() {
    source ./demo-env.sh

    oc delete secret arodemoscb-acr
    oc patch serviceaccount default -p '{"imagePullSecrets": []}'
}

deployApp() {
    source ./demo-env.sh

    helm upgrade --install data-api charts/data-api --set deploy.acrServer=$ACR_LOGIN_SERVER --set deploy.imageTag=$DATA_API_TAG
    helm upgrade --install flights-api charts/flights-api --set deploy.acrServer=$ACR_LOGIN_SERVER --set deploy.imageTag=$FLIGHTS_API_TAG
    helm upgrade --install quakes-api charts/quakes-api --set deploy.acrServer=$ACR_LOGIN_SERVER --set deploy.imageTag=$QUAKES_API_TAG
    helm upgrade --install weather-api charts/weather-api --set deploy.acrServer=$ACR_LOGIN_SERVER --set deploy.imageTag=$WEATHER_API_TAG
    helm upgrade --install service-tracker-ui charts/service-tracker-ui --set deploy.acrServer=$ACR_LOGIN_SERVER --set deploy.imageTag=$SERVICE_TRACKER_UI_TAG

    oc create route edge --service=service-tracker-ui --hostname=service-tracker.$APPS_DOMAIN

    oc get route
}

removeApp() {
    source ./demo-env.sh

    helm delete data-api
    helm delete quakes-api
    helm delete weather-api
    helm delete flights-api
    helm delete service-tracker-ui

    oc delete route service-tracker-ui
}

deployAzureResources() {
    source ./demo-env.sh

    oc apply -f ./aro-demo/aso-cosmosdb.yaml
    oc apply -f aro-demo/aso-appinsights.yaml
}

removeAzureResources() {
    source ./demo-env.sh

    oc delete -f ./aro-demo/aso-cosmosdb.yaml
    oc delete -f aro-demo/aso-appinsights.yaml
}

up() {
    source ./demo-env.sh

    addAcrPullSecret
    deployApp
    deployAzureResources
}

down() {
    source ./demo-env.sh

    removeAcrPullSecret
    removeApp
    removeAzureResources

    # oc delete project $PROJECT_NAME
}

status() {
    source ./demo-env.sh

    az aro list -o table
    az acr list -g $RG_NAME -o table

    oc get all
    oc get CosmosDB
    oc get AppInsights
}

showSecrets() {
    source ./demo-env.sh

    oc get secret service-tracker-db -o json | jq -r .data.PrimaryMongoDBConnectionString | base64 -d
    oc get secret appinsights-aro-demo-appinsights-demo -o json | jq -r .data.instrumentationKey | base64 -d
}

subcommand=$1

case "$subcommand" in

    up)
        up
    ;;
    
    down)
        down
    ;;

    buildApp)
        buildApp
    ;;

    status)
        status
    ;;

    secrets)
        showSecrets
    ;;

    deployApp)
        deployApp
    ;;

    removeApp)
        removeApp
    ;;

    *)
        echo "$0 up|down|status|showSecrets|buildApp|deployApp|removeApp"
    ;;
esac
