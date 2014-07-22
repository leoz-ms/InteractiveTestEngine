#Keep these two lines
Param ([ref]$result)
. ..\utility.ps1

#You can get config value like this:
#$value = getConfValue "sample"
$AzCopyPath = $global:AzCopyPath
$AccountName = getConfValue "AccountName"
$AccountKey = getConfValue "AccountKey"

#Do your stuff here and set $passed to $true of $false to indicate test result
$passed = $false

log "Generating random file for test"
$randomFileName = Get-Random
$randomContentLocal = Get-Random
$randomContentUpload = Get-Random
$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$utf8 = new-object -TypeName System.Text.UTF8Encoding
$randomFileNameHash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($randomFileName))).Replace("-","").ToLower();
$randomContentLocalHash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($randomContentLocal))).Replace("-","").ToLower();
$randomContentUploadHash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($randomContentUpload))).Replace("-","").ToLower();
$randomContentUploadHash | Out-File "$randomFileNameHash.txt"

log "Uploading random file"
log "AzCopy /Y /DestKey:$AccountKey ./ http://$AccountName.blob.core.windows.net/$randomFileNameHash/ $randomFileNameHash.txt"
cmd /c $AzCopyPath "/Y" "/DestKey:$AccountKey" "./" "http://$AccountName.blob.core.windows.net/$randomFileNameHash/" "$randomFileNameHash.txt"
#$AzCopyCmdProcess = Start-Process cmd -Wait -ArgumentList ("/c", $AzCopyPath, "/Y", "/V:upload.log", "/DestKey:$AccountKey", "./", "http://$AccountName.blob.core.windows.net/$randomFileNameHash/", "$randomFileNameHash.txt") -PassThru

log "Removing and rebuilding local random file for test"
Remove-Item "$randomFileNameHash.txt"
$randomContentLocalHash | Out-File "$randomFileNameHash.txt"

log "Downloading random file"
ack "Please Input 'y' to commit overwrite of file"
log "$AzCopyPath /SourceKey:$AccountKey http://$AccountName.blob.core.windows.net/$randomFileNameHash/ ./ $randomFileNameHash.txt"
cmd /c $AzCopyPath "/SourceKey:$AccountKey" "http://$AccountName.blob.core.windows.net/$randomFileNameHash/" "./" "$randomFileNameHash.txt"
#$AzCopyCmdProcess = Start-Process cmd -ArgumentList ("/c", $AzCopyPath, "/V:upload.log", "/SourceKey:$AccountKey", "http://$AccountName.blob.core.windows.net/$randomFileNameHash/", "./", "$randomFileNameHash.txt") -PassThru

if (-not (yesOrNo "Please verify the output prompt, does it looks good, not truncate?")) {
	log "The output mess."
	#$AzCopyCmdProcess | Stop-Process
}
else {
	Get-Content  "$randomFileNameHash.txt" | Write-Host
    if (-not (yesOrNo "The content of the file is $randomContentUploadHash, correct?")) {
        $passed = $false
    }
	else {
		$passed = $true
	}
}

Remove-Item "$randomFileNameHash.txt"
#Return test result
if ($passed) {
    $result.value = $true
} else {
    $result.value = $false
}