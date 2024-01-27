# Authenticate
Connect-MgGraph -ClientID <yourclientid> -TenantId <yourtenantid> -CertificateThumbprint <thumbprint>


# Define license SKU IDs
$a3LicenseSkuId = "4b590615-0888-425a-a965-b3bf7789848d"
$a1PlusLicenseSkuId = "78e66a63-337a-4a9a-8959-41c6654dfb56"
$a1LicenseSkuId = "94763226-9b3c-4e75-a931-5c89701abe66"

# Create a log file with today's date
$logDate = Get-Date -Format "yyyy-MM-dd"
$logFile = "D:\CRON\Office365\LOG\A1_TO_A3\LicenseChangeLog_$logDate.txt"

# Function to write log
function Write-Log {
    Param ([string]$message)
    "$message" | Out-File -FilePath $logFile -Append
}

# Find disabled users with A3 license
$enabledUsersWithA1 = Get-MgBetaUser -Filter "accountEnabled eq true AND jobtitle eq 'Staff'" -All | Where-Object { $_.AssignedLicenses.SkuId -eq $a1PlusLicenseSkuId }


foreach ($user in $enabledUsersWithA1) {
    
    try {

      # Define the user ID and the SKU IDs for the licenses

        $addLicenseSkuId = "4b590615-0888-425a-a965-b3bf7789848d" # License to add
        $removeLicenseSkuId = "78e66a63-337a-4a9a-8959-41c6654dfb56"  # License to remove

        # Prepare the license update payload as a hashtable
        $licenseUpdate = @{
        AddLicenses = @(@{ SkuId = $addLicenseSkuId })
        RemoveLicenses = @($removeLicenseSkuId)
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
