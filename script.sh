# Source: https://gist.github.com/4c45fe3307e63f3756eb1b1beb42c201

#########
# TODO: #
#########

# References:
# - Styra: TODO:
# - Crossplane: TODO:

##############
# Demo Steps #
##############

1. V installs Crossplane
2. V creates cluster, deletes cluster
3. A installs OPA
4. V creates cluster, tries to delete cluster. Fails because of maintenance window
5. A explains how the maintenance window workd, A adds maintenance window
6. V deletes cluster
7. V tries to create too many clusters
8. A explains rule preventing that

#########
# Setup #
#########

git clone \
    https://github.com/vfarcic/crossplane-styra-demo

cd crossplane-styra-demo

# TODO: Viktor: Switch to a "real" management cluster
kind create cluster --config kind.yaml

# Creating 2 Namespaces so that we can show different policies for different teams

kubectl create namespace a-team

kubectl create namespace b-team

#############
# Setup AWS #
#############

# TODO: Would you like to switch to a different provider?

# Replace `[...]` with your access key ID`
export AWS_ACCESS_KEY_ID=[...]

# Replace `[...]` with your secret access key
export AWS_SECRET_ACCESS_KEY=[...]

echo "[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
" | tee aws-creds.conf

kubectl create namespace upbound-system

kubectl --namespace upbound-system \
    create secret generic aws-creds \
    --from-file creds=./aws-creds.conf

####################
# Setup Crossplane #
####################

helm repo add upbound \
    https://charts.upbound.io/stable

helm repo update

helm upgrade --install \
    universal-crossplane upbound/universal-crossplane \
    --version 1.3.0-up.0 \
    --namespace upbound-system \
    --create-namespace \
    --wait

kubectl create namespace crossplane-system

kubectl apply --filename crossplane

# If the previous command threw an error `error: unable to recognize "crossplane/providers.yaml"`, the provider is still not up-and-running.
# Wait for a few moments and re-run the previous command.

###############
# Setup Styra #
###############

Use installation instructions from:
https://adamsandor.svc.styra.com/systems/ce69e076ca17433f8cc1a4781c7d6826/settings/install/kubectl

##############
# Scenario 1 #
##############

# TODO: The commands that follow will work without any violations. We should add some failures due to policy violations, fix it, run it again, succeed (or whichever other scenario makes sense).

cat infra/team-a-cluster-1.yaml

kubectl --namespace a-team \
    apply --filename infra/team-a-cluster-1.yaml

# NOTE: It fails. Change it in Git.

kubectl --namespace a-team \
    get clusterclaims,managed,providerconfigs,releases

kubectl --namespace a-team \
    get clusterclaims

kubectl --namespace a-team \
    apply --filename infra/team-a-cluster-2.yaml

kubectl --namespace a-team \
    apply --filename infra/team-a-cluster-3.yaml

# NOTE: It fails.

# Repeat the previous command until the `CONTROLPLANE` column is set to `ACTIVE`

export KUBECONFIG=$PWD/kubeconfig.yaml

aws eks --region us-east-1 \
    update-kubeconfig \
    --name a-team

kubectl apply --filename my-app.yaml

cat my-app.yaml

cat infra/cluster-a-team.yaml

cat crossplane/definition.yaml

cat crossplane/composition-eks.yaml

unset KUBECONFIG

###########
# Destroy #
###########

kubectl --namespace a-team \
    delete --filename infra

kubectl get managed

# Repeat until all the resources are removed

kind delete cluster
