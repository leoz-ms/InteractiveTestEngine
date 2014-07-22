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

log "Generating 500 files for test"
$randomFolderNameNumber = Get-Random
$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$utf8 = new-object -TypeName System.Text.UTF8Encoding
$randomFolderName = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($randomFolderNameNumber))).Replace("-","").ToLower();
cmd /c create_thousand_files.cmd

log "Start uploading 500 files"
ack "Please check that the progress bar will keep in the bottom of the output, and update with transfer progress"
log "AzCopy /Y /DestKey:$AccountKey ./ http://$AccountName.blob.core.windows.net/$randomFolderName/ testfile_*.txt"
cmd /c $AzCopyPath "/Y" "/DestKey:$AccountKey" "./" "http://$AccountName.blob.core.windows.net/$randomFolderName/" "testfile_*.txt"

if (-not (yesOrNo "The progress bar act right, correct?")) {
	log "Something wrong with the progress bar."
}
else {
	$passed = $true
}
#Return test result
Remove-Item "testfile_*.txt"
if ($passed) {
    $result.value = $true
} else {
    $result.value = $false
}