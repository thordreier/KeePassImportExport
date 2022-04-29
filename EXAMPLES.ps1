############################ KeePass to KeePass sync ###########################

# Connect to first KeePass database
$kdbx1 = Get-Item -Path C:\path\to\keepass\file1.kdbx
$masterKey1 = Get-Credential -Message MasterKey1 -UserName NOT_USED
$db1 = $kdbx1.BaseName
if (-not (Get-KeePassDatabaseConfiguration -DatabaseProfileName $db1))
{
    New-KeePassDatabaseConfiguration -DatabaseProfileName $db1 -DatabasePath $kdbx1.FullName -UseMasterKey
}

# Connect to second KeePass database
$kdbx2 = Get-Item -Path C:\path\to\keepass\file2.kdbx
$masterKey2 = Get-Credential -Message MasterKey1 -UserName NOT_USED
$db2 = $kdbx2.BaseName
if (-not (Get-KeePassDatabaseConfiguration -DatabaseProfileName $db2))
{
    New-KeePassDatabaseConfiguration -DatabaseProfileName $db2 -DatabasePath $kdbx2.FullName -UseMasterKey
}

# Sync from first to second KeePass file
Export-KeePassEntry -RootPath toplevel/export -DatabaseProfileName $db1 -MasterKey $masterKey1 | Import-KeePassEntry -RootPath toplevel/import -DatabaseProfileName $db2 -MasterKey $masterKey2



################### KeePass to Pleasant Password Server sync ###################

# Install PPS module
Install-Module -Name PPS -Scope CurrentUser

# Connect to KeePass database
$kdbx = Get-Item -Path C:\path\to\keepass\file.kdbx
$masterKey = Get-Credential -Message MasterKey -UserName NOT_USED
$db = $kdbx.BaseName
if (-not (Get-KeePassDatabaseConfiguration -DatabaseProfileName $db))
{
    New-KeePassDatabaseConfiguration -DatabaseProfileName $db -DatabasePath $kdbx.FullName -UseMasterKey
}

# Connect to Pleasant Password Server
Connect-Pps -Uri password.company.tld

# Sync from KeePass to Pleasant Password Server
Export-KeePassEntry -RootPath toplevel/export -DatabaseProfileName $db -MasterKey $masterKey | Import-PpsEntry -RootPath 'Root/Private Folders/xxx/import'



################### Pleasant Password Server to KeePass sync ###################

# Install PPS module
Install-Module -Name PPS -Scope CurrentUser

# Connect to KeePass database
$kdbx = Get-Item -Path C:\path\to\keepass\file.kdbx
$masterKey = Get-Credential -Message MasterKey -UserName NOT_USED
$db = $kdbx.BaseName
if (-not (Get-KeePassDatabaseConfiguration -DatabaseProfileName $db))
{
    New-KeePassDatabaseConfiguration -DatabaseProfileName $db -DatabasePath $kdbx.FullName -UseMasterKey
}

# Connect to Pleasant Password Server
Connect-Pps -Uri password.company.tld

# Sync from Pleasant Password Server to KeePass
Export-PpsEntry -RootPath 'Root/Private Folders/xxx/import' | Import-KeePassEntry -RootPath toplevel/import -DatabaseProfileName $db -MasterKey $masterKey
