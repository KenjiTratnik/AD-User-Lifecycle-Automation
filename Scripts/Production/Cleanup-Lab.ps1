Import-Module ActiveDirectory

$CSVPath = "C:\Provisioning\students.csv"
$Students = Import-Csv $CSVPath
$LocalHomeDir = "C:\Shares\StudentHomes"

foreach($Student in $Students){
	$User = $Student.Username

	try{
		# Remove from AD
		if(Get-ADUser -Filter "SamAccountName -eq '$User'"){
			Remove-ADUser -Identity $User -Confirm:$false
			Write-Host "Removed AD User: $User" -ForegroundColor Gray
		}

		# Remove Home Folder
		$Path = "$LocalHomeDir\$User"
		if(Test-Path $Path){
			Remove-Item -Path $Path -Recurse -Force
			Write-Host "Delted Folder: $Path" -ForegroundColor Gray
		}
	}

	catch{
		Write-Warning "Could not fully clean up $User"
	}
}

# Clear Password Log
$PasswordFile = "C:\Provisioning\NewStudentPasswords.csv"
if(Test-Path $PasswordFile){Remove-Item $PasswordFile}

Write-Host "`n Lab Environment Reset. Ready for a fresh run." -ForegroundColor Cyan
