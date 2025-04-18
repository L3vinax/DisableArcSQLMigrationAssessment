# Description: This script disables the migration assessment for all Azure Arc SQL servers in a specified resource group.
# Check if the Az module is installed
if (-not (Get-Module -Name Az -ListAvailable)) {
    Write-Host "Az module not found. Installing..."
    Install-Module -Name Az -AllowClobber -Force -Scope CurrentUser
} else {
    Write-Host "Az module is already installed."
}

# Get all the Azure Arc SQL server instances that have the migration assessment enabled.
$query = "resources | where type == 'microsoft.azurearcdata/sqlserverinstances' | extend currentStatus = tobool(properties.migration.assessment.enabled) | where currentStatus == true"

$sqlservers = search-azgraph -query $query

# Use Az CLI to check and disable the migration assessment for each SQL server instance
foreach ($sql in $sqlservers) {
        $body = @{
            properties = @{
                 migration = @{
                        assessment = @{
                            enabled = $false
                        }
                    }
            }   
        } | ConvertTo-Json -Depth 10

        Invoke-AzRestMethod -Method PATCH -Path "/subscriptions/$($sql.SubscriptionId)/resourceGroups/$($sql.ResourceGroup)/providers/Microsoft.AzureArcData/SqlServerInstances/$($sql.Name)?api-version=2024-02-01-preview" -Payload $body | Out-Null

        Write-Host "Migration Assessment Disabled on "$sql.Name

}
