$root = split-path $MyInvocation.MyCommand.Path
pushd $root 
. $root\..\utility.ps1

try {
    $AzCopyMsiPath = getConfValue "AzCopyMsiPath"

    if( -not [bool] $AzCopyMsiPath ) {
	    $AzCopyMsiPath = read-host " The path of AzCopy installer is missing, please enter the path: "
	    setConfValue "AzCopyMsiPath" $AzCopyMsiPath
    }
    else {
	    if( -not (yesOrNo( "The AzCopy installer located at $AzCopyMsiPath, correct?"))) {
		    $AzCopyMsiPath = read-host " Please enter the new path of AzCopy installer: "
		    setConfValue "AzCopyMsiPath" $AzCopyMsiPath
	    }
    }

    if ((Test-Path $AzCopyMsiPath.Trim("`"")) -eq $false) {
        throw "The path of AzCopy installer is wrong."
    }

    if((yesOrNo( "Do you want to perform an addtional check of current AzCopy installed in the system?"))) {
	    $CurrentAzCopy = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*Azure Storage Tools*"}
	    if ([bool] $CurrentAzCopy) {
		    throw "Please uninstall the current AzCopy " + ($CurrentAzCopy.Version) + " before start the clean install test."
	    }
    }
}
finally {
    popd
}