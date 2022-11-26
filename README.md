# rancher-terraform

This is a terraform template for create Rancher RKE or AKS on Azure.

## How to use 

### RKE

```
cd ./rke
```
Replace the terraform.tfvars.example to terraform.tfvars and fill the column below

- azure_client_id
- azure_client_secret
- azure_subscription_id

Then execute 
``` 
terraform init
```
```
terraform apply --auto-approve
```

### AKS

```
cd ./aks
```
Replace the terraform.tfvars.example to terraform.tfvars and fill the column below

- azure_client_id
- azure_client_secret
- azure_subscription_id

Then execute 
``` 
terraform init
```
```
terraform apply --auto-approve
```




