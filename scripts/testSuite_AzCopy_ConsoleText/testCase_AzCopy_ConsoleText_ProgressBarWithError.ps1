#Keep these two lines
Param ([ref]$result)
. ..\utility.ps1

#You can get config value like this:
#$value = getConfValue "sample"
$AzCopyPath = getConfValue "AzCopyPath"
$AccountName = getConfValue "AccountName"
$AccountKey = getConfValue "AccountKey"

#Do your stuff here and set $passed to $true of $false to indicate test result
$passed = $false

cleanUpTestFileAndAzCopyInstanceAndJnl

log "Generating 500 files for test"
$randomFolderNameNumber = Get-Random
$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$utf8 = new-object -TypeName System.Text.UTF8Encoding
$randomFolderName = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($randomFolderNameNumber))).Replace("-","").ToLower();
runExecutableWithArgs cmd @("/c", "create_thousand_files.cmd")

log "Start uploading files"
ack "Please Check if error shows correctly, and progress bar will move to the end of the output from azcopy while AzCopy running"
log "Uploading files"
log "AzCopy /Y /DestKey:$AccountKey /source:./ /dest:http://$AccountName.blob.core.windows.net/$randomFolderName/ /pattern:testfile_*.txt"
runExecutableWithArgs $AzCopyPath @("/Y","/DestKey:$AccountKey","/source:./","/dest:http://$AccountName.blob.core.windows.net/$randomFolderName/","/pattern:testfile_*.txt")

log "Change some files to ReadOnly"
$file = Get-Item "testfile_250.txt"
$file.IsReadOnly = $true

log "Downloading files"
log "AzCopy /Y /S /SourceKey:$AccountKey /source:http://$AccountName.blob.core.windows.net/$randomFolderName/ /dest:./ /pattern:testfile_"
runExecutableWithArgs $AzCopyPath @("/Y","/S","/SourceKey:$AccountKey","/source:http://$AccountName.blob.core.windows.net/$randomFolderName/","/dest:./","/pattern:testfile_")

if (-not (yesOrNo "The error and the progress bar act right, correct?")) {
	log "Something wrong with the progress bar while error, and the output mess."
}
else {
	$passed = $true
}
$file.IsReadOnly = $false

cleanUpTestFileAndAzCopyInstanceAndJnl

#Return test result
if ($passed) {
    $result.value = $true
} else {
    $result.value = $false
}