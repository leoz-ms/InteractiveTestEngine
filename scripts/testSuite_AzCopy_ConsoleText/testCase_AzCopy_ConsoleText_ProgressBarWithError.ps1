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

log "Start uploading files"
ack "Please Check if error shows correctly, and progress bar will move to the end of the output from azcopy while AzCopy running"
log "Uploading files"
log "AzCopy /Y /DestKey:$AccountKey ./ http://$AccountName.blob.core.windows.net/$randomFolderName/ testfile_*.txt"
cmd /c $AzCopyPath "/Y" "/DestKey:$AccountKey" "./" "http://$AccountName.blob.core.windows.net/$randomFolderName/" "testfile_*.txt"

log "Change some files to ReadOnly"
$file = Get-Item "testfile_250.txt"
$file.IsReadOnly = $true

log "Downloading files"
log "AzCopy /Y /S /SourceKey:$AccountKey http://$AccountName.blob.core.windows.net/$randomFolderName/ ./ testfile_"
cmd /c $AzCopyPath "/Y" "/S" "/SourceKey:$AccountKey" "http://$AccountName.blob.core.windows.net/$randomFolderName/" "./" "testfile_"

if (-not (yesOrNo "The error and the progress bar act right, correct?")) {
	log "Something wrong with the progress bar while error, and the output mess."
}
else {
	$passed = $true
}
$file.IsReadOnly = $false
Remove-Item "testfile_*.txt"
#Return test result
if ($passed) {
    $result.value = $true
} else {
    $result.value = $false
}