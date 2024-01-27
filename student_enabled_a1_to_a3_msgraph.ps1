# Authenticate
Connect-MgGraph -ClientID <yourclientid> -TenantId <yourtenantid> -CertificateThumbprint <thumbprint>

# Define license SKU IDs
$a3LicenseSkuId = "18250162-5d87-4436-a834-d795c15c80f3"
$a1PlusLicenseSkuId = "e82ae690-a2d5-4d76-8d30-7c6e01e6022e" # do not use after 8/1/24
$a1LicenseSkuID = "314c4481-f395-4525-be8b-2ec4bb1e9d91" # use after 8/1/24

# Create a log file with today's date
$logDate = Get-Date -Format "yyyy-MM-dd"
$logFile = "D:\CRON\Office365\LOG\Student\A1_TO_A3\LicenseChangeLog_$logDate.txt"

# Function to write log
function Write-Log {
    Param ([string]$message)
    "$message" | Out-File -FilePath $logFile -Append
}

# Find disabled users with A3 license
$enabledUsersWithA1 = Get-MgBetaUser -Filter "accountEnabled eq true AND jobtitle eq 'Student'" -All | Where-Object { $_.AssignedLicenses.SkuId -eq $a1PlusLicenseSkuId }


foreach ($user in $enabledUsersWithA1) {
    
    try {

      
        # Define the user ID and the SKU IDs for the licenses

        $addLicenseSkuId = "18250162-5d87-4436-a834-d795c15c80f3"  # License to add
        $removeLicenseSkuId = "e82ae690-a2d5-4d76-8d30-7c6e01e6022e"  # License to remove

        # Define the Service Plan IDs to disable - use Exchange Plan #2 for A3 - efb87545-963c-4e0d-99df-69c6916d9eb0 not #1 
        $disabledPlanIds = @("57ff2da0-773e-42df-b2af-ffb7a2317929", "2078e8df-cff6-4290-98cb-5408261a760a", "efb87545-963c-4e0d-99df-69c6916d9eb0", "0feaeb32-d00e-4d66-bd5a-43b5b83db82c")

        # Prepare the license addition object with DisabledPlans

        $licenseToAdd = @{
        SkuId = $addLicenseSkuId
        DisabledPlans = $disabledPlanIds
        }

        # License IDs to remove (array of GUIDs)
        $licensesToRemove = @($removeLicenseSkuId)

       # Prepare the license update payload as a hashtable
        $licenseUpdate = @{
        AddLicenses = @($licenseToAdd)
        RemoveLicenses = $licensesToRemove
        }

        # Update the user's licenses using Set-MgUserLicense
        Set-MgUserLicense -UserId $user.Id -BodyParameter $licenseUpdate

        $userUPN = $user | Select-Object -ExpandProperty UserPrincipalName
        $logMessage = "Removed A1Plus and added A3 for user: $userUPN"

        Write-Log $logMessage
        Write-Host $logMessage
    } catch {
        $errorMessage = "Failed to update license for user: $userUPN . Error: $_"
        Write-Log $errorMessage
        Write-Warning $errorMessage
    }
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph

# Final log message
Write-Log "License update process completed."
