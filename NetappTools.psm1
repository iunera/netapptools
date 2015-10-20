Import-module DataONTAP


function logonToNaNode {
<#
.SYNOPSIS
	Makes a connection to a NetApp filer
.DESCRIPTION
	Returns connection object or $null.
.NOTES
	Authors:	Chris
#>

    param(
		[parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]
		[string]$NaNode
	)

	Try {
		$objCredentials = getCredentials
		if ($objCredentials -ne $null) {
			Write-Message "Connecting to ${NaNode}.." -level "verbose"
			$objNaConnection = Connect-NaController $NaNode -Credential $objCredentials
			return $objNaConnection
		}
		else { return $null }
	}
	Catch {
		writeError $_
		Write-Message "Error occurred while trying to logon to NetApp filer!" -level "err"
		return $null
	}
}

function createVolumeSnapshot {
<#
.SYNOPSIS
	Creates a NetApp volume snapshot.
.DESCRIPTION
	Returns $true or $false.
.NOTES
	Authors:	Chris
#>

    param(
		[parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]
		[string]$NaNode,
		[parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]
		[string]$Volume,
		[parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]
		[string]$SnapName
	)

	Try {
		$objNaConnection = logonToNaNode $nanode
		if ((Get-NaSnapshot $volume) -notmatch $SnapName) {
			Write-Message "Creating snapshot '${SnapName}' on volume '${volume}'.."
			New-NaSnapshot $volume $SnapName | Out-Null
			return $true
		}
		else {
			Write-Message "A snapshot with this name already exists." -level "warn"
			return $true
		}
	}
	Catch {
		writeError $_
		Write-Message "Error occurred while trying to create volume snapshot!" -level "err"
		return $false
	}
}

function removeVolumeSnapshot {
<#
.SYNOPSIS
	Creates a NetApp volume snapshot.
.DESCRIPTION
	Returns $true or $false.
.NOTES
	Authors:	Chris
#>

    param(
		[parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]
		[string]$NaNode,
		[parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]
		[string]$Volume,
		[parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]
		[string]$SnapName
	)

	Try {
		$objNaConnection = logonToNaNode $nanode
		
		$colSnapshots = Get-NaSnapshot $volume
		
		$blnSnapshotFound = $false
		Foreach ($objSnapshot In $colSnapshots) {
			if ($objSnapshot.Name -eq $SnapName) {
				Write-Message "Removing snapshot '${SnapName}' from '${Volume}'.." -level "verbose"
				$blnSnapshotFound = $true
				Remove-NaSnapshot -TargetName $volume -SnapName $SnapName -Confirm:$false | Out-Null
				return $true
			}	
		}
		
		if ($blnSnapshotFound -eq $false) {
			Write-Message "A snapshot with this name doesn't exist." -level "warn"
			return $true
		}
	}
	Catch {
		writeError $_
		Write-Message "Error occurred while trying to create volume snapshot!" -level "err"
		return $false
	}
}

function sisCloneFolder {
<#
.SYNOPSIS
	Clones a folder located on a NFS exported volume from source to target
.DESCRIPTION
	Returns $true or $false.
.NOTES
	Authors:	Chris
#>

    param(
		[parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]
		[string]$NaNode,
		[parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]
		[string]$SourceFolder,
		[parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]
		[string]$TargetFolder
	)

	Try {
		$objNaConnection = logonToNaNode $nanode
	
		if ($objNaConnection -ne $null) {
			Write-Message "Cloning $SourceFolder to ${TargetFolder}.."
			if ((Get-NaFile $SourceFolder -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue) -eq $null){
				Write-Message "Sourcefolder $sourcefolder doesn't exist. Cloning will be aborted!" -level "verbose"
				return $false
			}elseif ((Get-NaFile $TargetFolder -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue) -ne  $null){
				Write-Message "Targetfolder $targetfolder exists. Cloning will be aborted!" -level "err"
				return $false
			#source folder need to exists and targetfolder not. Only then the clone is allowed to work.
			}elseif (
			((Get-NaFile $SourceFolder -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue) -ne $null) -and
			((Get-NaFile $TargetFolder -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue) -eq  $null)	
			){
				cloneFolder -SourceFolder $SourceFolder -TargetFolder $TargetFolder
				return $true
			}
		}
	}
	Catch {
		writeError $_
		Write-Message "Error occurred while trying to clone folder!" -level "err"
		return $false
	}
}

function cloneFolder{
<#
.SYNOPSIS
	Clones a folder located on a NFS exported volume
.DESCRIPTION
	
.NOTES
	Authors:	Chris
#>

    param(
		[parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]
		[string]$SourceFolder,
		[parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]
		[string]$TargetFolder
	)

	Try {
		if ((Get-NaFile $TargetFolder -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue) -eq $null) {
			New-NaDirectory $TargetFolder -Permission (Get-NaFile $SourceFolder).Perm | Out-Null
		}
		
		$files = Read-NaDirectory $SourceFolder
			
		# clone directories
		foreach ($file in $files) {
			if (
			($file.FileType -eq "directory") -and
			($file -notmatch "^\.$") -and
			($file -notmatch "^\.\.$")
			) {
				write-message $file -level "trivia"
				cloneFolder "$sourcefolder/$file" "$targetfolder/$file"
			} else{
				write-message $file -level "trivia"
			}
		}

		# clone files
		foreach ($file in $files ){
			if (
			($file -notmatch "^\.$") -and
			($file -notmatch "^\.\.$") -and 
			($file.FileType -eq "file")
			) {
				Write-Message "$sourcefolder/$file to $targetfolder/$file" -level "trivia"
				Start-NaClone "$sourcefolder/$file" "$targetfolder/$file" | Out-Null
			}
		}
	}
	Catch {
		writeError $_
		Write-Message "Error occurred while trying to clone!" -level "err"
	}
}

function getSecureString {
<#
.SYNOPSIS
	Extracts secure string 
.DESCRIPTION
	Extracts secure string out of an encrypted string. 
	The encrypted string could be in a file or handed over directly.
	Returns secure password or throws an exception
.NOTES
	Authors:	Chris
#>
	
    param(
		[parameter(Mandatory = $false)] [ValidateNotNullOrEmpty()]
		[string]$File, 
		[parameter(Mandatory = $false)] [ValidateNotNullOrEmpty()]
		[string]$String
	)

	Try {
		# encryption string
		$key = [byte]12,86,65,17,72,45,65,12,49,46,0,12,67,48,47,33
	
		if ($File) {
			if (Test-Path($File)) {
				$strAuthstring = Get-Content $File
				$Password = ConvertTo-SecureString -String $strAuthstring -Key $key
				return $Password
			}
			else {
				throw "File $Path not found! Could not get secure string."
			}
		}
	
		if ($String) {
			$Password = ConvertTo-SecureString -String $String -Key $key
			return $Password
		}
	}
	Catch {
		Write-Message $_ -level "err"
		throw $_
	}
}


function getCredentials {
<#
.SYNOPSIS
	Builds credentials object
.DESCRIPTION
	Returns an PSCredential object
.NOTES
	Authors:	Chris
#>
	
	Try {
		$strUsername = "root"
		$strFile = "NetappRootEncString.txt" # contains the PS encrypted Password String

		Write-message "Building credentials for user '${strUsername}'.." -level "trivia"
		$objPassword = getSecureString -file $strFile
		$objCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($strUsername,$objPassword)
	} 
	Catch {
		Write-Message "No encrypted password found! Type in user and password manually.." -level "err"
		$objCredentials = Get-Credential
	}
	return $objCredentials
}

