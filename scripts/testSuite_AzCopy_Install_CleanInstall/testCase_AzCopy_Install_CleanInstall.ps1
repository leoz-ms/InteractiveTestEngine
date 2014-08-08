#Keep these two lines
Param ([ref]$result)
. ..\utility.ps1

#You can get config value like this:
#$value = getConfValue "sample"
$AzCopyMsiPath = getConfValue "AzCopyMsiPath"

& $AzCopyMsiPath

if (-not (yesOrNo "Does the installer appear?")) {
    $result.value = $false
    return
}

ack "In every step of the installation, you have to check version information, text change and period information according to the instructions."

#First Page: Welcome
if (-not (yesOrNo "Is the version in the title correct?")) {
    $result.value = $false
    return
}
if (-not (yesOrNo "Is the version in this page correct?")) {
    $result.value = $false
    return
}
if (-not (yesOrNo "Is the text changes applied to this page?")) {
    $result.value = $false
    return
}
ack "Please press the Next button, and enter y to continue."

#Second Page: License
ack "In this page, you should check whether the license file is in valid period. Entey y to continue"
if (-not (yesOrNo "Is the ENU license file in valid period?")) {
    $result.value = $false
    return
}
if (-not (yesOrNo "Is the DEU license file in valid period?")) {
    $result.value = $false
    return
}
ack "Please check the `"I accept..`" checkbox, press the Next button, and enter y to continue."

#Third Page: Destination
if (-not (yesOrNo "Is the version in this page correct?")) {
    $result.value = $false
    return
}
if (-not (yesOrNo "Is the text changes applied to this page?")) {
    $result.value = $false
    return
}
ack "Please press the Next button, and enter y to continue."

#Fourth Page: Confirmation
if (-not (yesOrNo "Is the version in this page correct?")) {
    $result.value = $false
    return
}
if (-not (yesOrNo "Is the text changes applied to this page?")) {
    $result.value = $false
    return
}
ack "Please press Install button, and enter y to install AzCopy. Notice that you should click Yes if there is a UAC dialog. Be sure to check the version and text changes during the installation."

#Fifth Page: Installation
if (-not (yesOrNo "Is the version showed during the installation correct?")) {
    $result.value = $false
    return
}
if (-not (yesOrNo "Is the text changes applied to the installation page?")) {
    $result.value = $false
    return
}

#Last Page: Finish
if (-not (yesOrNo "Is the version in this page correct?")) {
    $result.value = $false
    return
}
if (-not (yesOrNo "Is the text changes applied to this page?")) {
    $result.value = $false
    return
}
ack "Please press the Finish button to finish the installation, and enter y to continue."

#Submit a task to get the AzCopy Path
$AzCopyPathCode = { 
    $CurrentAzCopy = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*Azure Storage Tools*"}
    if( -not [bool] $CurrentAzCopy ) {
        return ""
    }
    $AzCopyPath = [string]$CurrentAzCopy.InstallLocation + "AzCopy\AzCopy.exe"    
    $AzCopyPath
}
$AzCopyPathJob = Start-Job -ScriptBlock $AzCopyPathCode

#Check Add/Remove Program
ack "Now the Add/Remove Program wizard will appear, you should check if the version of the AzCopy item is correct."
& appwiz.cpl
if (-not (yesOrNo "Is the version of the AzCopy item correct?")) {
    $result.value = $false
    return
}
ack "Please close the Add/Remove Program wizard, and enter y to continue."

#Addtional Check of Start menu and Install Folder
ack "Now the Start Menu Folder will appear, you should check if the AzCopy folder is correct, and the old version is removed."
& explorer.exe "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
if (-not (yesOrNo "Is the AzCopy folder correct?")) {
    $result.value = $false
    return
}
ack "Please close the Start Menu Folder, and enter y to continue."

#Wait for the AzCopyPath
$Waitjob = Wait-Job $AzCopyPathJob
$AzCopyPath = Receive-Job $AzCopyPathJob

#Addtional Check of Install Folder
$installFolder = Split-Path -parent(Split-Path -parent(Split-Path -parent $AzCopyPath))
ack "Now the Install Folder will appear, you should check if the AzCopy folder is correct, and the old version is removed."
& explorer.exe $installFolder
if (-not (yesOrNo "Is the AzCopy folder correct?")) {
    $result.value = $false
    return
}
ack "Please close the Install Folder, and enter y to continue."

#Check commandline Help
ack "Now there will be a new commandline window with AzCopy commandline help, you should check if the version and copyright of the AzCopy is correct."
Start-Process cmd -ArgumentList @("/k", "`"$AzCopyPath`"")
if (-not (yesOrNo "Is the version in the commandline help correct?")) {
    $result.value = $false
    return
}
if (-not (yesOrNo "Is the copyright in AzCopy commandline help updated?")) {
    $result.value = $false
    return
}
if (-not (yesOrNo "Is the copyright in AzCopy commandline help in valid period?")) {
    $result.value = $false
    return
}
ack "Please close the commandline window, and enter y to continue."
$passed = $true
#Return test result
if ($passed) {
    $result.value = $true
} else {
    $result.value = $false
}