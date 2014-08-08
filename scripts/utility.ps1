function log ($message) {
    $d = get-date
    write-host ("[{0:yyyy-MM-dd HH:mm:ss}] $message" -f $d)
}

function getConfValue ($key) {
    $c = gc "configuration.txt"

    $c | % {
        if ($_ -like "$key=*") {
            $startIndex = "$key=".Length
            $value = $_.substring($startIndex)
            return $value
        }
    }
}

function setConfValue ($key, $value) {
    $c = gc "configuration.txt"
    $existed = $false

    $c = $c | % {
        if ($_ -like "$key=*") {
		    $_ = "$key=$value"
		    $existed = $true
        }
	    $_
    }
    if (-not $existed) {
	    $c += "$key=$value"
    }
    $c | Out-File "configuration.txt"
    return
}

function cleanUpTestFileAndAzCopyInstanceAndJnl() {
    log "Cleaning up..."
    # Delete TestFile
    Remove-Item "testfile_*.txt"

    # Kill AzCopy Instance
    Get-Process -Name AzCopy -ErrorAction SilentlyContinue | Stop-Process

    # Clean Jnl File
    Remove-Item "$env:SystemDrive\Users\$env:username\AppData\Local\Microsoft\Azure\AzCopy\*.jnl"
}

function runExecutableWithArgs($command, $argList) {	
    if ($Host.Name -match 'ise'){
        Start-Process $command -Wait -ArgumentList $argList
    }
    else {
	    & $command $argList
    }
}

function ack ($info) {
    do {
        $input = Read-Host "[ATTENTION!] $info. `r`n(Y) Ok, I get that.`n(N) Sorry, what did you say? `nYou"
    } while ($input -ne "y")
}

function yesOrNo($info) {
    do {
        $input = Read-Host "[ATTENTION!] $info. `r`n(Y)es `n(N)o.`nYou"

        if ($input -eq "n") {
            return $false
        } elseif ($input -eq "y") {
            return $true
        }
    } while ($true)
}