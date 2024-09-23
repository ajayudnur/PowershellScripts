
# Function to check if the OS is Windows 10 Pro
Function Check-WindowsEdition {
    $edition = (Get-WmiObject -Query "SELECT * FROM SoftwareLicensingProduct WHERE LicenseFamily LIKE 'Professional'").LicenseFamily
    if ($edition -notcontains "Professional") {
        Write-Host "Windows edition is not Pro. attempting to convert to Pro.." -ForegroundColor Yellow
        return $false      
    }
    else {
        Write-Host "Windows edition is Pro." -ForegroundColor Green
        return $true
    }
}

# Function to attempt to upgrade Windows Home to Pro
Function ConvertTo-Pro {
    # Dummy key for Windows 10 Pro Edition
    $proKey = "VK7JG-NPHTM-C97JM-9MPGT-3V66T" 
    try {
        $result = Start-Process -FilePath "changepk.exe" -ArgumentList "/ProductKey $proKey" -Wait -PassThru
        if ($result.ExitCode -eq 0) {
            Write-Host "Conversion to Pro was successful." -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "Please ignore the upgrade failed error, The computer must be restarted now. Please run the same command again after a restart."
            
            shutdown -r -t 00
            return $false
        }
    }
    catch {
        Write-Error "An error occurred during conversion: $_"
        return $false
    }
}

# Function to collect Autopilot hash and upload to IIS server
Function CollectAndUpload-AutopilotHash {
    # Collect the Autopilot hash
    try {
        Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        New-Item -Type Directory -Path "C:\HWID" -ErrorAction SilentlyContinue
        Set-Location -Path "C:\HWID"
        $env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
        Install-PackageProvider -Name Nuget -force -Confirm:$false
        Install-Script -Name Get-WindowsAutopilotInfo -Force -Confirm:$false
        Get-WindowsAutopilotInfo -OutputFile "AutopilotHWID_$(get-date -Format ddMMyyyyHHmm).csv"
        Write-Host "Autopilot hash saved in C:\HWID\" -ForegroundColor Green

    }
    catch {
        Write-Error "Failed to collect Autopilot hash: $_"
        return
    }

    # Upload the Autopilot hash to the IIS server
    try {
        Write-Output "Nothing to do here yet."
        <### Needs upload commands.
        $uri = "https://test.com/api/uploadautopilothash" # Your API endpoint
        $body = @{ Hash = $autopilotHash } | ConvertTo-Json
        Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json"
        Write-Host "Autopilot hash uploaded successfully."
        #>
    }
    catch {
        Write-Error "Failed to upload Autopilot hash: $_"
    }
}

# Check if Windows edition is Pro, try to convert if it's not
$isPro = Check-WindowsEdition
if (-not $isPro) {
    $isPro = ConvertTo-Pro
}

# If Windows is now Pro, collect and upload the Autopilot hash
if ($isPro) {
    CollectAndUpload-AutopilotHash
            }
Else{
    # Perform a full reset of the OS to start provisioning from scratch
    try {
        Write-Host "Initiating complete reset of the OS..."
        #Start-Process -FilePath "systemreset.exe" -ArgumentList "-FactoryReset" -Wait
    }
    catch {
        Write-Error "An error occurred while resetting the OS: $_"
    }
    }
