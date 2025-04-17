# Description: This script disables the migration assessment for all Azure Arc SQL servers in a specified resource group.
# Check if the Az module is installed
if (-not (Get-Module -Name Az -ListAvailable)) {
    Write-Host "Az module not found. Installing..."
    Install-Module -Name Az -AllowClobber -Force -Scope CurrentUser
} else {
    Write-Host "Az module is already installed."
}
# First step, connect to an azure account with the necessary permissions
# This script is meant to be run from cloudshell. Uncomment this if running locally.
#Connect-AzAccount

#get-azsubscription | Select-Object name, id | out-gridview -title "Select Subscription" -PassThru | Set-AzContext

# Get all the Azure Arc SQL server instances in a specified resource group
$sqlservers = get-azresource -resourcetype "Microsoft.AzureArcData/SqlServerInstances"

# Use Az CLI to check and disable the migration assessment for each SQL server instance
foreach ($sql in $sqlservers) {
    # Get the current properties of the SQL server instance
    $currentProperties = az resource show --ids $sql.resourceid --query "properties.migration.assessment.enabled" --api-version 2024-02-01-preview | ConvertFrom-Json

    # Check if the migration assessment is enabled
    if ($currentProperties -eq $true) {
        # Disable the migration assessment
        $body = @{
            properties = @{
                 migration = @{
                        assessment = @{
                            enabled = $false
                        }
                    }
            }
        } | ConvertTo-Json -Depth 10

        Invoke-AzRestMethod -Method PATCH -Path "/subscriptions/$($sql.SubscriptionId)/resourceGroups/$($sql.ResourceGroupName)/providers/Microsoft.AzureArcData/SqlServerInstances/$($sql.Name)?api-version=2024-02-01-preview" -Payload $body | Out-Null

        Write-Host "Migration Assessment Disabled on "$sql.Name
    } else {
        Write-Host "Migration Assessment already disabled on "$sql.Name
    }
}
