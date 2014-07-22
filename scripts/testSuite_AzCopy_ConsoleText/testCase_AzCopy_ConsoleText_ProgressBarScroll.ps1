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
ack "Please Move the Scroll bar of the console while AzCopy running"
log "AzCopy /Y /DestKey:$AccountKey ./ http://$AccountName.blob.core.windows.net/$randomFolderName/ testfile_*.txt"
#"$AzCopyPath /Y /V:upload.log /DestKey:$AccountKey ./ http://$AccountName.blob.core.windows.net/$randomFolderName/ testfile_*.txt" | Out-File "temp_run_script.bat" -Append  -encoding "ASCII"
cmd /c $AzCopyPath "/Y" "/DestKey:$AccountKey" "./" "http://$AccountName.blob.core.windows.net/$randomFolderName/" "testfile_*.txt"
#$AzCopyCmdProcess = Start-Process cmd -Wait -ArgumentList ("/k", "temp_run_script.bat") -PassThru

if (-not (yesOrNo "The output didn't mess, correct?")) {
	log "Something wrong with the progress bar, and the output mess."
}
else {
	$passed = $true
}

Remove-Item "testfile_*.txt"
#Return test result
if ($passed) {
    $result.value = $true
} else {
    $result.value = $false
}