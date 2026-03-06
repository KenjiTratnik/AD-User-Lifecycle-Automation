Import-Module ActiveDirectory

# --- CONFIGURATION ---
$CSVPath      = "C:\Provisioning\students.csv"
$StudentOU    = "OU=Students,OU=Users,OU=Enterprise,DC=ad,DC=lab"
$DisabledStudents   = "OU=DisabledStudents,OU=Users,OU=Enterprise,DC=ad,DC=lab"
$StudentGroup = "SG_Students_Share"
$PasswordFile = "C:\Provisioning\NewStudentPasswords.csv"
$HomeRoot     = "\\Dell-R440\StudentHomes"
$LocalHomeDir = "C:\Shares\StudentHomes"

# --- LOGGING & TRANSCRIPT SETUP ---
$LogDir = "C:\Provisioning\Logs"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$LogPath = Join-Path $LogDir "Provisioning_$(Get-Date -Format 'yyyyMMdd_HHmm').log"

# Start the professional audit trail
Start-Transcript -Path $LogPath -Append

# --- PRE-FLIGHT CHECKS ---
# Ensures environment is ready before making changes
if (-not (Test-Path $CSVPath)) { Write-Error "CSV not found at $CSVPath"; exit }
if (-not (Get-ADOrganizationalUnit -Identity $StudentOU)) { Write-Error "Target OU not found"; exit }
$Students = Import-Csv $CSVPath

# Refresh Password Log
if (Test-Path $PasswordFile) { Remove-Item $PasswordFile }

# --- FUNCTIONS ---
function New-RandomPassword {
    param([int]$Length = 14)
    $Upper = "ABCDEFGHJKLMNPQRSTUVWXYZ".ToCharArray()
    $Lower = "abcdefghijkmnopqrstuvwxyz".ToCharArray()
    $Nums  = "23456789".ToCharArray()
    $Spec  = "!@#$%&*".ToCharArray()

    $Selection = @()
    $Selection += $Upper | Get-Random
    $Selection += $Lower | Get-Random
    $Selection += $Nums  | Get-Random
    $Selection += $Spec  | Get-Random

    $All = $Upper + $Lower + $Nums + $Spec
    $Selection += 1..($Length - 4) | ForEach-Object { $All | Get-Random }

    return -join ($Selection | Sort-Object { Get-Random })
}

# --- MAIN PROCESS ---
foreach ($Student in $Students) {
    $User = $Student.Username
    $Full = "$($Student.FirstName) $($Student.LastName)"
    
    # CASE 1: OFFBOARDING
    if ($Student.Graduated -eq "Yes") {
        $ExistingUser = Get-ADUser -Filter "SamAccountName -eq '$User'" -Properties DistinguishedName
        
        if ($null -ne $ExistingUser) {
            try {
                # Check if they are already in the Disabled OU
                if ($ExistingUser.DistinguishedName -like "*$DisabledStudents*") {
                    Write-Host "$Full is already in the Disabled OU." -ForegroundColor Gray
                } else {
                    Disable-ADAccount -Identity $User
                    Move-ADObject -Identity $ExistingUser.DistinguishedName -TargetPath $DisabledStudents
                    
                    $Groups = Get-ADPrincipalGroupMembership -Identity $User | Where-Object { $_.Name -ne "Domain Users" }
                    if ($Groups) {
                        Remove-ADPrincipalGroupMembership -Identity $User -MemberOf $Groups -Confirm:$false
                    }
                    Write-Host "De-provisioned Graduated Student: $Full" -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host "Failed to move $User : $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Warning "User $User not found in Active Directory. Skipping offboarding."
        }
    } 

    # CASE 2: ONBOARDING
    else {
        try {
            $PassPlain = New-RandomPassword
            $PassSec   = ConvertTo-SecureString $PassPlain -AsPlainText -Force
            
            # Create AD User
            New-ADUser -Name $Full -GivenName $Student.FirstName -Surname $Student.LastName `
                       -SamAccountName $User -UserPrincipalName "$User@ad.lab" `
                       -Path $StudentOU -AccountPassword $PassSec -Enabled $true `
                       -ChangePasswordAtLogon $true -HomeDirectory "$HomeRoot\$User" -HomeDrive "H:"
            
            Add-ADGroupMember -Identity $StudentGroup -Members $User
            Write-Host "Created AD User: $Full" -ForegroundColor Cyan

            # Create Folder
            $Path = "$LocalHomeDir\$User"
            New-Item -ItemType Directory -Path $Path -Force | Out-Null

            # AD REPLICATION VALIDATION LOOP
            # Solves: "Identity references could not be translated"
            Write-Host "Waiting for AD replication..." -NoNewline
            $Resolved = $false
            $Retries  = 0
            while (-not $Resolved -and $Retries -lt 5) {
                try {
                    $NTAccount = New-Object System.Security.Principal.NTAccount($User)
                    $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]) | Out-Null
                    $Resolved = $true
                    Write-Host " Success!" -ForegroundColor Green
                }
                catch {
                    $Retries++; Start-Sleep -Seconds 2; Write-Host "." -NoNewline
                }
            }

            if ($Resolved) {
                $Acl = Get-Acl $Path
                $Ar  = New-Object System.Security.AccessControl.FileSystemAccessRule($User, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
                $Acl.SetAccessRule($Ar)
                Set-Acl $Path $Acl
            }

            # CSV Logging
            [PSCustomObject]@{
                Date     = Get-Date -Format "yyyy-MM-dd"
                Student  = $Full
                User     = $User
                Password = $PassPlain
            } | Export-Csv -Path $PasswordFile -Append -NoTypeInformation

            Write-Host "Successfully provisioned: $Full" -ForegroundColor Green
        }
        catch {
            Write-Host "Error on $Full : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`nAutomation Task Complete." -ForegroundColor White -BackgroundColor DarkBlue

# End the audit trail
Stop-Transcript
Write-Host "Transcript saved to: $LogPath" -ForegroundColor Gray
