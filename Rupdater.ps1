# --- SETTINGS ---
$CranOldUrl = "https://cran.r-project.org/bin/windows/base/"
$TempFolder = "$env:TEMP\RUpdate"
$InstallerPath = "$TempFolder\R-Installer.exe"
$RScriptPath = "$TempFolder\update_packages.R"
$LogFile = "C:\Program Files\R\R_Update_Log_$($env:COMPUTERNAME).txt"

# --- FUNCTION TO WRITE LOGS ---
function Write-Log {
    param (
        [string]$message,
        [string]$level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$level] $message"
    Add-Content -Path $LogFile -Value $logEntry
    Write-Host $logEntry
}

# --- CHECK LOG FILE SIZE ---
# Check if the log file exists and if its size exceeds 5MB (5 * 1024 * 1024 bytes)
if (Test-Path $LogFile) {
    if ((Get-Item $LogFile).length -gt 5MB) {
        Write-Log "Log file size exceeds 5MB. Deleting the existing log file..." "INFO"
        Remove-Item $LogFile -Force  # Delete the log file
        Write-Log "Existing log file deleted due to size exceeding 5MB. New Log file." "INFO"
    }
}

# --- CHECK IF RSTUDIO OR R IS IN USE ---
function Check-RStudioOrRRunning {
    Write-Log "Checking if RStudio or R is currently running..." "INFO"
    
    # Check if RStudio or R is running (correct process name for R: "Rgui" or "Rscript")
    $RStudioProcess = Get-Process -Name "rstudio" -ErrorAction SilentlyContinue
    $RProcessGui = Get-Process -Name "Rgui" -ErrorAction SilentlyContinue  # For R GUI (Rgui.exe)
    $RProcessScript = Get-Process -Name "Rscript" -ErrorAction SilentlyContinue  # For Rscript (Rscript.exe)

    if ($RStudioProcess -or $RProcessGui -or $RProcessScript) {
        Write-Log "RStudio or R (Rgui or Rscript) is currently running. Exiting script." "WARNING"
        exit 0
    } else {
        Write-Log "Neither RStudio nor R (Rgui or Rscript) is running. Proceeding with script." "INFO"
    }
}

# --- INITIAL CHECK: IS RSTUDIO OR R RUNNING? ---
Check-RStudioOrRRunning

# --- PREPARE TEMP FOLDER ---
try {
    if (-Not (Test-Path $TempFolder)) {
        New-Item -ItemType Directory -Path $TempFolder | Out-Null
    }
    Write-Log "Temporary folder prepared: $TempFolder" "SUCCESS"
} catch {
    Write-Log "Could not create temp folder: $_" "ERROR"
    exit 1
}

# --- GET LATEST R VERSION FROM CRAN ---
Write-Log "Fetching latest R version from CRAN..."
try {
    $response = Invoke-WebRequest -Uri $CranOldUrl -UseBasicParsing
    $content = $response.Content

    if ($content -match 'R-([\d\.]+)-win\.exe') {
        $LatestVersion = $Matches[1]
        Write-Log "Latest R Version Found: $LatestVersion" "SUCCESS"
    } else {
        Write-Log "Could not detect R version from CRAN page." "ERROR"
        exit 1
    }
} catch {
    Write-Log "Error fetching CRAN page: $_" "ERROR"
    exit 1
}

# --- CHECK IF LATEST VERSION OF R IS ALREADY INSTALLED ---
Write-Log "Checking installed R versions..."
try {
    $installedRPaths = Get-ChildItem "C:\Program Files\R" -Directory

    if (-Not $installedRPaths) {
        Write-Log "No existing R installations found." "INFO"
    }

    $ExistingVersions = @()
    foreach ($rPath in $installedRPaths) {
        $RExe = Join-Path $rPath.FullName "bin\R.exe"
        if (Test-Path $RExe) {
            $version = (Get-ItemProperty -Path $RExe).VersionInfo.FileVersion
            $shortVersion = $version -replace '(\d+\.\d+\.\d+).*', '$1'
            $ExistingVersions += [PSCustomObject]@{Path = $rPath.FullName; Version = $shortVersion}
        }
    }

    $CurrentVersionInstalled = $ExistingVersions | Where-Object { $_.Version -eq $LatestVersion }

    if ($CurrentVersionInstalled) {
        Write-Log "Latest R version ($LatestVersion) already installed." "SUCCESS"
        $SkipInstall = $true
    } else {
        Write-Log "Latest R version ($LatestVersion) not installed. Installation required." "INFO"
        $SkipInstall = $false
    }
} catch {
    Write-Log "Could not retrieve installed R versions: $_" "ERROR"
    exit 1
}

# --- DOWNLOAD R INSTALLER IF NEEDED ---
if (-Not $SkipInstall) {
    $DownloadUrl = "https://cran.r-project.org/bin/windows/base/R-$LatestVersion-win.exe"
    Write-Log "Downloading R installer from $DownloadUrl..."
    try {
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath
        Write-Log "R installer downloaded to $InstallerPath" "SUCCESS"
    } catch {
        Write-Log "Error downloading R installer: $_" "ERROR"
        exit 1
    }

    # --- INSTALL R SILENTLY ---
    Write-Log "Installing R $LatestVersion silently..."
    try {
        Start-Process -FilePath $InstallerPath -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" -Wait
        Write-Log "R installation completed." "SUCCESS"
    } catch {
        Write-Log "Failed to install R silently: $_" "ERROR"
        exit 1
    }
}

# --- DELETE ALL OLD R INSTALLATIONS (EXCEPT THE LATEST) ---
Write-Log "Cleaning up old R installations..."
try {
    foreach ($entry in $ExistingVersions) {
        if ($entry.Version -ne $LatestVersion) {
            if (Test-Path $entry.Path) {
                Remove-Item -Path $entry.Path -Recurse -Force
                Write-Log "Deleted old R installation: $($entry.Path)" "SUCCESS"
            }
        }
    }
} catch {
    Write-Log "Failed to delete old R installation(s): $_" "WARNING"
}

# --- CREATE R SCRIPT TO UPDATE PACKAGES ---
Write-Log "Creating R script to update packages..."
try {
    @"
outdated <- old.packages()
if (is.null(outdated)) {
  cat('No packages needed updating.\n', file='$LogFile', append=TRUE)
} else {
  updated <- rownames(outdated)
  update.packages(ask=FALSE, checkBuilt=TRUE)
  cat('Updated packages: ', paste(updated, collapse=', '), '\n', file='$LogFile', append=TRUE)
}
"@ | Out-File -Encoding UTF8 -FilePath $RScriptPath
    Write-Log "R update script created at $RScriptPath" "SUCCESS"
} catch {
    Write-Log "Could not create R script: $_" "ERROR"
    exit 1
}

# --- LOCATE INSTALLED R ---
Write-Log "Locating installed R..."
try {
    $NewRPath = Get-ChildItem "C:\Program Files\R" -Directory | Where-Object { $_.Name -match $LatestVersion } | Select-Object -First 1

    if (-not $NewRPath) {
        Write-Log "Cannot find installed R folder!" "ERROR"
        exit 1
    }

    $RScriptExe = Join-Path $NewRPath.FullName "bin\Rscript.exe"

    if (-Not (Test-Path $RScriptExe)) {
        Write-Log "Rscript.exe not found in installed R folder!" "ERROR"
        exit 1
    }

    Write-Log "Found Rscript.exe at $RScriptExe" "SUCCESS"
} catch {
    Write-Log "Error locating R installation: $_" "ERROR"
    exit 1
}

# --- RUN R SCRIPT TO UPDATE PACKAGES --- 
Write-Log "Running R script to update packages silently..."
try {
    # Use the -e argument to run the R script without opening a window
    Start-Process -FilePath $RScriptExe -ArgumentList "-e", "source('$RScriptPath')" -Wait -NoNewWindow
    Write-Log "R packages update script executed silently." "SUCCESS"
} catch {
    Write-Log "Failed to run R update script silently: $_" "ERROR"
    exit 1
}

# --- CLEANUP TEMP FILES ---
Write-Log "Cleaning up temporary files..."
try {
    Remove-Item $TempFolder -Recurse -Force
    Write-Log "Temporary files cleaned up." "SUCCESS"
} catch {
    Write-Log "Failed to clean temp files, but script will continue: $_" "WARNING"
}

Write-Log "-----------------------------------------------" "INFO"
Write-Log "[FINAL SUCCESS] R is updated to version $LatestVersion and packages are refreshed!" "FINAL"
Write-Log "-----------------------------------------------" "INFO"
