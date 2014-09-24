#Keep these two lines
Param ([ref]$result)
. ..\utility.ps1

#You can get config value like this:
#$value = getConfValue "sample"
$AzCopyPath = (getConfValue "AzCopyPath").Trim("`"")
$AccountName = getConfValue "AccountName"
$AccountKey = getConfValue "AccountKey"

#Do your stuff here and set $passed to $true of $false to indicate test result
$passed = $false

cleanUpTestFileAndAzCopyInstanceAndJnl

log "Generating random file for test"
$randomFileName = Get-Random
$randomContentLocal = Get-Random
$randomContentUpload = Get-Random
$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$utf8 = new-object -TypeName System.Text.UTF8Encoding
$randomFileNameHash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($randomFileName))).Replace("-","").ToLower();
$randomContentLocalHash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($randomContentLocal))).Replace("-","").ToLower();
$randomContentUploadHash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($randomContentUpload))).Replace("-","").ToLower();
$randomContentUploadHash | Out-File "testfile_$randomFileNameHash.txt"

log "Uploading random file"
log "AzCopy /Y /DestKey:$AccountKey /source:./ /dest:http://$AccountName.blob.core.windows.net/$randomFileNameHash/ /pattern:testfile_$randomFileNameHash.txt"
runExecutableWithArgs $AzCopyPath @("/Y", "/V:upload.log", "/DestKey:$AccountKey", "/source:./", "/dest:http://$AccountName.blob.core.windows.net/$randomFileNameHash/", "/pattern:testfile_$randomFileNameHash.txt")

log "Removing and rebuilding local random file for test"
Remove-Item "testfile_$randomFileNameHash.txt"
$randomContentLocalHash | Out-File "testfile_$randomFileNameHash.txt"

log "Downloading random file"
ack "Please Input 'y' to commit overwrite of file"
log "$AzCopyPath /SourceKey:$AccountKey /source:http://$AccountName.blob.core.windows.net/$randomFileNameHash/ /dest:./ /pattern:testfile_$randomFileNameHash.txt"
runExecutableWithArgs $AzCopyPath @("/V:upload.log", "/SourceKey:$AccountKey", "/source:http://$AccountName.blob.core.windows.net/$randomFileNameHash/", "/dest:./", "/pattern:testfile_$randomFileNameHash.txt")

if (-not (yesOrNo "Please verify the output prompt, does it looks good, not truncate?")) {
	log "The output mess."
}
else {
	$content = (Get-Content "testfile_$randomFileNameHash.txt" -Raw)
	$content = $content.Trim()
	if ( $content.CompareTo($randomContentUploadHash) -eq 0 ) {
		log "The content of the file is $content, which is same as the original $randomContentUploadHash."
		$passed = $true
	}
	else {
		log "The content of the file is $content, which is different from the original $randomContentUploadHash."
		$passed = $false
	}
}

cleanUpTestFileAndAzCopyInstanceAndJnl
#Return test result
if ($passed) {
    $result.value = $true
} else {
    $result.value = $false
}