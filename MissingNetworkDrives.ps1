function Exit-Program{
    Write-Host "`nExiting program..."
    Start-Sleep -Seconds 2
    Exit
}
function Confirm-Drives{
    Write-Host
    Get-PSDrive -PSProvider FileSystem | Format-Table
    $continue = Read-Host "Are drives still missing? (Y/N)"
    if($continue -ne "y"){ exit }
}
function Get-DriveLetters{
    param( $userInfo )
    $usedLetters = @()
    $currentDrives = Get-PSDrive -PSProvider FileSystem | Select-Object Name
    
    foreach ($letter in $currentDrives){
        $usedLetters += $letter.Name
    }
    $usedLetters += $userDriveInfo.HomeDrive.Substring(0,1)

    return $usedLetters
}

Write-Host "Troubleshoot Missing Drives"
Write-Host "    1. Only Personal drive is missing"
Write-Host "    2. Multiple drives are missing"
$menuChoice = Read-Host "   Enter menu choice (1 or 2)"

switch($menuChoice){
    "1"{
        # Variable Declaration
        $lettersInUse = @()
        $tempLetter

        Confirm-Drives
        $userName = Read-Host "`nEnter the username of the drive owner"

        <##### Find the user's personal drive; Exit if it doesn't exist #####>
        $userDriveInfo = Get-ADUser -Identity $userName -Properties HomeDrive, HomeDirectory | Select-Object HomeDrive, HomeDirectory
        if($userDriveInfo.HomeDrive.Count -eq 0) { 
            Write-Host "User does not have a home directory."
            Exit-Program
        }

        <##### Get list of taken drive letters #####>
        $lettersInUse = Get-DriveLetters -userInfo $userDriveInfo

        if($lettersInUse -notcontains "Z"){ $tempLetter = "Z" }
        elseif($lettersInUse -notcontains "Y"){ $tempLetter = "Y" }
        else{ $tempLetter = "X" }

        <##### Create the temporary suer drive #####>
        Write-Host "Creating temporary network drive..."
        try{
            New-PSDrive -Name $newLetter -PSProvider "FileSystem" -Root $userDriveInfo.HomeDirectory -Persist
            Write-Host -NoNewline "Drive successfully created: "
            Write-Host "$($tempLetter):\ to $($userDriveInfo.HomeDirectory)"
        }
        catch {
            Write-Host "Error creating the drive."
            $_.Exception.Message
        }

        Exit-Program
    }

    "2"{
        Confirm-Drives
        gpupdate /force
        Confirm-Drives
        Get-Process Explorer | Stop-Process
        Start-Sleep -Seconds 7
        Confirm-Drives
        Write-Host "If user home drive still missing, run again using menu choice 1."
        Exit-Program
    }
    default {
        Exit-Program
    }
}
