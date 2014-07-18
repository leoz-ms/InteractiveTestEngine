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
log "Please wait for the transfer end"
log "AzCopy /Y /DestKey:$AccountKey ./ http://$AccountName.blob.core.windows.net/$randomFolderName/ testfile_*.txt"
cmd /c $AzCopyPath "/Y" "/DestKey:$AccountKey" "./" "http://$AccountName.blob.core.windows.net/$randomFolderName/" "testfile_*.txt"

log "Change some files to ReadOnly"
$file = Get-Item "testfile_250.txt"
$file.IsReadOnly = $true
$file = Get-Item "testfile_251.txt"
$file.IsReadOnly = $true

log "Start downloading files"
log "Please input 'a' to overwrite all files, and wait for the transfer failed"
log "AzCopy /S /SourceKey:$AccountKey http://$AccountName.blob.core.windows.net/$randomFolderName/ ./ testfile_"
cmd /c $AzCopyPath "/S" "/SourceKey:$AccountKey" "http://$AccountName.blob.core.windows.net/$randomFolderName/" "./" "testfile_"

log "Change some files back to normal"
$file = Get-Item "testfile_250.txt"
$file.IsReadOnly = $false
$file = Get-Item "testfile_251.txt"
$file.IsReadOnly = $false

log "Start to try the download command again"
log "Please input 'y' to resume the transfer"
log "Then please input 'a' to overwrite all files"
log "AzCopy /S /SourceKey:$AccountKey http://$AccountName.blob.core.windows.net/$randomFolderName/ ./ testfile_"
cmd /c $AzCopyPath "/S" "/SourceKey:$AccountKey" "http://$AccountName.blob.core.windows.net/$randomFolderName/" "./" "testfile_"

$input = read-host " The question appear and all txt looks good and no truncate, correct?`n (Y)es, (N)o"
if ($input -eq "n") {
	log "Something wrong with the resume question."
}
else {
	$input = read-host " The transfer has resumed, correct?`n (Y)es, (N)o"
	if ($input -eq "n") {
		log "Something wrong with the resume function."
	}
	else {
		$passed = $true
	}
}
Remove-Item "testfile_*.txt"
#Return test result
if ($passed) {
    $result.value = $true
} else {
    $result.value = $false
}