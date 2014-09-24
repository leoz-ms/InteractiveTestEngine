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
ack "Please wait for the transfer end"
log "AzCopy /Y /DestKey:$AccountKey /source:./ /dest:http://$AccountName.blob.core.windows.net/$randomFolderName/ /pattern:testfile_*.txt"
runExecutableWithArgs $AzCopyPath @("/Y","/DestKey:$AccountKey","/source:./","/dest:http://$AccountName.blob.core.windows.net/$randomFolderName/","/pattern:testfile_*.txt")

log "Change some files to ReadOnly"
$file = Get-Item "testfile_250.txt"
$file.IsReadOnly = $true
$file = Get-Item "testfile_251.txt"
$file.IsReadOnly = $true

log "Start downloading files"
ack "Please input 'a' to overwrite all files, and wait for the transfer failed"
log "AzCopy /S /SourceKey:$AccountKey /source:http://$AccountName.blob.core.windows.net/$randomFolderName/ /dest:./ /pattern:testfile_"
runExecutableWithArgs $AzCopyPath @("/S","/SourceKey:$AccountKey","/source:http://$AccountName.blob.core.windows.net/$randomFolderName/","/dest:./","/pattern:testfile_")

log "Change some files back to normal"
$file = Get-Item "testfile_250.txt"
$file.IsReadOnly = $false
$file = Get-Item "testfile_251.txt"
$file.IsReadOnly = $false

log "Start to try the download command again"
ack "Please input 'y' to resume the transfer, then please input 'a' to overwrite all files"
log "AzCopy /S /SourceKey:$AccountKey /source:http://$AccountName.blob.core.windows.net/$randomFolderName/ .dest:./ /pattern:testfile_"
runExecutableWithArgs $AzCopyPath @("/S","/SourceKey:$AccountKey","/source:http://$AccountName.blob.core.windows.net/$randomFolderName/","/dest:./","/pattern:testfile_")

if (-not (yesOrNo "The question appear and all txt looks good and no truncate, correct?")) {
	log "Something wrong with the resume question."
}
else {
	if (-not (yesOrNo "The transfer has resumed, correct?")) {
		log "Something wrong with the resume function."
	}
	else {
		$passed = $true
	}
}

cleanUpTestFileAndAzCopyInstanceAndJnl

#Return test result
if ($passed) {
    $result.value = $true
} else {
    $result.value = $false
}