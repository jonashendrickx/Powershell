[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)]
    [string]
    $ChromeDriverOutputPath,    
    [Parameter(Mandatory = $false)]
    [string]
    $ChromeVersion, 
    [Parameter(Mandatory = $false)]
    [Switch]
    $ForceDownload
)

$OriginalProgressPreference = $ProgressPreference;
# Increase performance of download.
$ProgressPreference = 'SilentlyContinue';

Function Get-ChromeVersion {
    If ($IsWindows -or $Env:OS) {
        Try {
            (Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction Stop).'(Default)').VersionInfo.FileVersion;
        }
        Catch {
            Throw "The registry key of 'Google Chrome' is not found.";
        }
    }
    ElseIf ($IsLinux) {
        Try {
            Get-Command google-chrome -ErrorAction Stop | Out-Null;
            google-chrome --product-version;
        }
        Catch {
            Throw "'google-chrome' command not found.";
        }
    }
    ElseIf ($IsMacOS) {
        $ChromePath = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
        If (Test-Path $ChromePath) {
            $Version = & $ChromePath --version;
            $Version = $Version.Replace("Google Chrome ", "");
            $Version;
        }
        Else {
            Throw "Google Chrome not found on Mac OSX.";
        }
    }
    Else {
        Throw "Unsupported operating system detected.";
    }
}

If ([string]::IsNullOrEmpty($ChromeVersion)) {
    $ChromeVersion = Get-ChromeVersion -ErrorAction Stop;
    Write-Output "Google Chrome version $ChromeVersion found on machine";
}

$ChromeVersion = $ChromeVersion.Substring(0, $ChromeVersion.LastIndexOf("."));
$ChromeDriverVersion = (Invoke-WebRequest "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$ChromeVersion").Content;
Write-Output "Latest matching version of Chrome Driver is $ChromeDriverVersion";

If (($ForceDownload -eq $False) -and (Test-path $ChromeDriverOutputPath)) {
    $ExistingChromeDriverVersion = & $ChromeDriverOutputPath --version;
    $ExistingChromeDriverVersion = $ExistingChromeDriverVersion.Split(" ")[1];
    If ($ChromeDriverVersion -eq $ExistingChromeDriverVersion) {
        Write-Output "Chromedriver on machine is already latest version. Skipping.";
        Write-Output "Use -ForceDownload to reinstall regardless";
        Exit;
    }
}

$TempFilePath = [System.IO.Path]::GetTempFileName();
$TempZipFilePath = $TempFilePath.Replace(".tmp", ".zip");
Rename-Item -Path $TempFilePath -NewName $TempZipFilePath;
$TempFileUnzipPath = $TempFilePath.Replace(".tmp", "");

If ($IsWindows -or $Env:OS) {
    Invoke-WebRequest "https://chromedriver.storage.googleapis.com/$ChromeDriverVersion/chromedriver_win32.zip" -OutFile $TempZipFilePath;
    Expand-Archive $TempZipFilePath -DestinationPath $TempFileUnzipPath;
    Move-Item "$TempFileUnzipPath/chromedriver.exe" -Destination $ChromeDriverOutputPath -Force;
}
ElseIf ($IsLinux) {
    Invoke-WebRequest "https://chromedriver.storage.googleapis.com/$ChromeDriverVersion/chromedriver_linux64.zip" -OutFile $TempZipFilePath;
    Expand-Archive $TempZipFilePath -DestinationPath $TempFileUnzipPath;
    Move-Item "$TempFileUnzipPath/chromedriver" -Destination $ChromeDriverOutputPath -Force;
}
ElseIf ($IsMacOS) {
    Invoke-WebRequest "https://chromedriver.storage.googleapis.com/$ChromeDriverVersion/chromedriver_mac64.zip" -OutFile $TempZipFilePath;
    Expand-Archive $TempZipFilePath -DestinationPath $TempFileUnzipPath;
    Move-Item "$TempFileUnzipPath/chromedriver" -Destination $ChromeDriverOutputPath -Force;
}
Else {
    Throw "Your operating system is not supported by this script.";
}

Remove-Item $TempZipFilePath;
Remove-Item $TempFileUnzipPath -Recurse;

# reset back to original Progress Preference
$ProgressPreference = $OriginalProgressPreference;