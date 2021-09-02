# Source: https://gist.github.com/4c45fe3307e63f3756eb1b1beb42c201

#########
# TODO: #
#########

# References:
# - Styra: TODO:
# - Crossplane: TODO:

#########
# Setup #
#########

git clone \
    https://github.com/vfarcic/crossplane-styra-demo

cd crossplane-styra-demo

# TODO: Viktor: Switch to a "real" management cluster
k3d cluster create --config k3d.yaml

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

# TODO: Adam: Commands to install Styra and policies we'll showcase

##############
# Scenario 1 #
##############

# TODO: The commands that follow will work without any violations. We should add some failures due to policy violations, fix it, run it again, succeed (or whichever other scenario makes sense).

cat infra/cluster-a-team.yaml

kubectl --namespace a-team \
    apply --filename infra/cluster-a-team.yaml

kubectl --namespace a-team \
    get clusterclaims,managed,providerconfigs,releases

kubectl --namespace a-team \
    get clusterclaims

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

##############
# Scenario 2 #
##############

# TODO: The commands that follow will work without any violations. We should add some failures due to policy violations, fix it, run it again, succeed (or whichever other scenario makes sense).

cat infra/cluster-b-team.yaml

kubectl --namespace b-team \
    apply --filename infra/cluster-b-team.yaml

###########
# Destroy #
###########

kubectl --namespace a-team \
    delete --filename infra/cluster-a-team.yaml

kubectl --namespace b-team \
    delete --filename infra/cluster-b-team.yaml

kubectl get managed

# Repeat until all the resources are removed

k3d cluster delete crossplane
