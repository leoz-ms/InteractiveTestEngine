$root = split-path $MyInvocation.MyCommand.Path
pushd $root 
. $root\..\utility.ps1

try {
	$CurrentAzCopy = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*Azure Storage Tools*"}
	if( -not [bool] $CurrentAzCopy ) {
		throw "Please install the AzCopy and try again."
	}
	$global:AzCopyPath = "`"" +  [string]$CurrentAzCopy.InstallLocation + "AzCopy\AzCopy.exe`""
	$AzCopyPath = $global:AzCopyPath
	$AccountName = getConfValue "AccountName"
	$AccountKey = getConfValue "AccountKey"
    if ((Test-Path $AzCopyPath.Trim("`"")) -eq $false) {
        throw "The AzCopy.exe is missing"
    }
}
finally {
    popd
}