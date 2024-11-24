git filter-branch --force --index-filter "git rm --cached --ignore-unmatch temp.ps1" --prune-empty --tag-name-filter cat -- --all


az aks enable-addons --addons azure-keyvault-secrets-provider --name <OrkideAKS --resource-group Automation
kubectl logs -l app=secrets-store-csi-driver -n kube-system
kubectl apply -f SecretProviderClass.yaml
kubectl apply -f devops-roles.yaml

kubectl exec -it <pod-name> -- printenv | grep AZP
kubectl describe pod azdevops-agent-5cff499876-dlpv8
az role assignment list --assignee 3007e93f-aa54-46a3-bbe2-e518e21db921 --scope Treasury --output table
sub id : dd79e1c9-b114-4f67-ba38-70e7a1560dc8
ten id : 03cf716d-2f0e-4a9f-814e-e04b5fb0d41e
az ad sp show --id 3007e93f-aa54-46a3-bbe2-e518e21db921 az ad sp list --display-name <service-principal-name> --query "[].appId" -o tsv
az ad sp list --display-name azurekeyvaultsecretsprovider-orkideaks --query "[].appId" -o tsv
az role assignment list --assignee 3007e93f-aa54-46a3-bbe2-e518e21db921 --scope "/subscriptions/dd79e1c9-b114-4f67-ba38-70e7a1560dc8/resourceGroups/Automation/providers/Microsoft.KeyVault/vaults/Treasury" --output table
az aks update --resource-group Automation --name OrkideAKS --enable-managed-identity --assign-identity <user-assigned-identity-client-id>
az aks show --resource-group Automation --name OrkideAKS --query "nodePools[0].identity" -o table
az role assignment list --assignee 432443c3-62f2-4bfa-951e-51b61ae6496d --scope /subscriptions/dd79e1c9-b114-4f67-ba38-70e7a1560dc8/resourceGroups/Automation/providers/Microsoft.KeyVault/vaults/Treasury --output table
az aks nodepool show --resource-group Automation --cluster-name OrkideAKS --name OrkideAKS-agentpool --query "identity"
az aks nodepool list --resource-group Automation --cluster-name OrkideAKS --output table
az aks nodepool update --resource-group Automation --cluster-name OrkideAKS --name agentpool --assign-identity 3007e93f-aa54-46a3-bbe2-e518e21db921
kubectl get secretproviderclass --all-namespaces
kubectl describe secretproviderclass demo-secret-provider -n default
kubectl get events -n <namespace>


$workloadIdentity="workload-identity"
$workloadClientId=$(az identity create --name $workloadIdentity --resource-group Automation --query clientId -o tsv)
$workloadPrincipalId=$(az identity show --name $workloadIdentity --resource-group Automation --query principalId -o tsv)


az aks show --resource-group Automation --name OrkideAKS --query "oidcIssuerProfile.issuerUrl" -o tsv
az identity federated-credential create --name "aks-federated-credential" --identity-name $workloadIdentity --resource-group Automation --issuer "https://northeurope.oic.prod-aks.azure.com/03cf716d-2f0e-4a9f-814e-e04b5fb0d41e/2fbe33f1-0f77-44ba-9f5f-f75efe8f0556/" --subject "system:serviceaccount:devops:workload-sa"
az role definition create --role-definition acrbuild.json
az role assignment create --assignee $workloadClientId --role 'AcrBuild' --scope $acrId
$acrid = az acr show --name conrepo --query "id" -o tsv
$aksid = az aks show --name OrkideAKS --resource-group automation --query "id" -o tsv
az role assignment create --role "Azure Kubernetes Service Cluster User Role" --assignee $workloadPrincipalId --scope $aksId
az role assignment create --role "Azure Kubernetes Service RBAC Writer" --assignee $workloadPrincipalId --scope $aksId/"namespaces/devops"
az acr build -f Dockerfile.runner -t devops-runner:v1.0.0 -r conrepo -g Automation .

az acr task create --registry $ACR_NAME --name DevopTask3 --image agentrunner:latest --context https://github.com/$GIT_USER/Devops.git --file devoprunner.dockerfile --git-access-token $GIT_PAT 

az acr task run --registry $ACR_NAME --name DevopTask2 
az acr task list --registry $ACR_NAME  --resource-group automation --output table
az acr repository list --name $ACR_NAME --output table

#troubleshooting commands


kubectl describe node aks-agentpool-15507476-vmss000002
kubectl describe pod devops-deployment-7dc66f6fc-72hmk -n devops
kubectl get events -n devops
