$ErrorActionPreference = "Stop"

$subscriptionId = "xx"
$resourceGroup  = "rg-xx-playground"
$location       = "westeurope"
$vnetName       = "name of teh vm"
$stamp          = Get-Date -Format "HHmmss"
$diskName       = "disk-pna-test-$stamp"
$nicName        = "nic-pna-test-$stamp"
$vmName         = "vm-pna-test-$stamp"
$vmSize         = "Standard_B2s"
$image          = "Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest"

az account set --subscription $subscriptionId
if ($LASTEXITCODE -ne 0) { throw "Could not select the subscription." }

$subnetId = az network vnet subnet list `
    --resource-group $resourceGroup `
    --vnet-name $vnetName `
    --query "[0].id" `
    --output tsv
if (-not $subnetId) { throw "No subnet found on $vnetName." }

Write-Host "Creating OS disk with public network access disabled..."
az disk create `
    --resource-group $resourceGroup `
    --name $diskName `
    --location $location `
    --os-type Linux `
    --sku StandardSSD_LRS `
    --size-gb 64 `
    --hyper-v-generation V2 `
    --image-reference $image `
    --public-network-access Disabled `
    --network-access-policy DenyAll
if ($LASTEXITCODE -ne 0) { throw "Disk creation failed." }

Write-Host "Creating network interface..."
az network nic create `
    --resource-group $resourceGroup `
    --name $nicName `
    --location $location `
    --subnet $subnetId
if ($LASTEXITCODE -ne 0) { throw "NIC creation failed." }

Write-Host "Creating VM from the existing OS disk..."
az vm create `
    --resource-group $resourceGroup `
    --name $vmName `
    --location $location `
    --size $vmSize `
    --nics $nicName `
    --attach-os-disk $diskName `
    --os-type Linux
if ($LASTEXITCODE -ne 0) { throw "VM creation failed." }

Write-Host ""
Write-Host "Disk network settings:"
az disk show `
    --resource-group $resourceGroup `
    --name $diskName `
    --query "{name:name, publicNetworkAccess:publicNetworkAccess, networkAccessPolicy:networkAccessPolicy}" `
    --output json

Write-Host ""
Write-Host "Created $vmName with OS disk $diskName."
Write-Host "This VM is attached to an existing disk, so it has no admin username or password."
