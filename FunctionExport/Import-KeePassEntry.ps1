function Import-KeePassEntry
{
    <#
        .SYNOPSIS
            xxx

        .DESCRIPTION
            xxx

        .PARAMETER RootPath
            xxx

        .PARAMETER InputObject
            xxx

        .PARAMETER NoCheck
            xxx

        .PARAMETER CheckProperty
            xxx

        .PARAMETER DryRun
            xxx

        .PARAMETER DatabaseProfileName
            xxx

        .PARAMETER MasterKey
            xxx

        .EXAMPLE
            xxx

        .EXAMPLE
            xxx
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $RootPath,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [PSCustomObject]
        $InputObject,

        [Parameter()]
        [switch]
        $NoCheck,

        [Parameter()]
        [string[]]
        $CheckProperty = @('Name', 'Username'),

        [Parameter()]
        [switch]
        $DryRun,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $DatabaseProfileName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [PSobject]
        $MasterKey
    )

    begin
    {
        Write-Verbose -Message "Begin (ErrorActionPreference: $ErrorActionPreference)"
        $origErrorActionPreference = $ErrorActionPreference
        $verbose = $PSBoundParameters.ContainsKey('Verbose') -or ($VerbosePreference -ne 'SilentlyContinue')

        $p = @{}
        $PSBoundParameters.GetEnumerator() | Where-Object -Property Key -In -Value 'DatabaseProfileName','MasterKey' | ForEach-Object -Process {
            $p[$_.Key] = $_.Value
        }

        $allProperties = @('Name', 'Username', 'Password', 'Url', 'Notes')

        if (-not $NoCheck)
        {
            # Some versions of PowerShell doesn't seem to trigger ValidateScript on an empty array. That's why it's located here
            if (-not $CheckProperty.Count) {throw 'CheckProperty should not be empty'}
            $CheckProperty | ForEach-Object -Process {if ($_ -notin $allProperties) {throw "$_ is not allowed in CheckProperty, only $($allProperties -join ',') is allowed"}}
            $CheckProperty = @('Path') + $CheckProperty

            try
            {
                $ErrorActionPreference = 'Stop'
                $existing = @(Export-KeePassEntry @p -RootPath $RootPath -WithId)
                if (-not ($existingHash = $existing | Group-Object -Property $CheckProperty -AsHashTable -AsString))
                {
                    $existingHash = @{}
                }
            }
            catch
            {
                $existing = @()
                $existingHash = @{}
            }
        }

        function NewGrp ([string] $Path)
        {
            if (-not (Get-KeePassGroup @p -KeePassGroupPath $Path))
            {
                $parent, $name = $Path -split '/(?=[^/]*$)'
                if (-not $name) {throw "$Path is not an allowed path in this KeePass file"}
                NewGrp -Path $parent                
                New-KeePassGroup @p -KeePassGroupParentPath $parent -KeePassGroupName $name
            }
        }

        function NewEntry ([string] $Path, [hashtable] $Params)
        {
            NewGrp -Path $Path
            New-KeePassEntry @p -KeePassEntryGroupPath $Path @Params
        }
    }

    process
    {
        Write-Verbose -Message "Process begin (ErrorActionPreference: $ErrorActionPreference)"

        try
        {
            # Make sure that we don't continue on error, and that we catches the error
            $ErrorActionPreference = 'Stop'

            $fullPath = if ($InputObject.Path) {$RootPath + '/' + $InputObject.Path} else {$RootPath}

            # PoShKeePass does not allow empty title, username, ... - so if these fields should be cleared, it's just too bad!
            # you will get a "Updating ..." every time, and nothing will be updated!

            #$entryParams = @{
            #    Title           = $InputObject.Name
            #    UserName        = $InputObject.Username
            #    KeePassPassword = $InputObject.Password | ConvertTo-SecureString -AsPlainText -Force
            #    URL             = $InputObject.Url
            #    Notes           = $InputObject.Notes
            #}

            $entryParams = @{}
            if ($InputObject.Name)     {$entryParams['Title']    = $InputObject.Name}
            if ($InputObject.Username) {$entryParams['UserName'] = $InputObject.Username}
            if ($InputObject.Url)      {$entryParams['URL']      = $InputObject.Url}
            if ($InputObject.Notes)    {$entryParams['Notes']    = $InputObject.Notes}
            if ($InputObject.Password)
            {
                $entryParams['KeePassPassword'] = $InputObject.Password | ConvertTo-SecureString -AsPlainText -Force
            }
            else
            {
                $entryParams['KeePassPassword'] = [securestring]::new()
            }

            if ($NoCheck)
            {
                "Creating $($InputObject.Path),  $($InputObject.Name)"
                if (-not $DryRun)
                {
                    $null = NewEntry -Path $fullPath -Params $entryParams
                }
            }
            else
            {
                $key = ($InputObject | Group-Object -Property $CheckProperty -AsHashTable -AsString).Keys | Select-Object -First 1
                if ($e = @($existingHash[$key] | Where-Object -FilterScript {-not $_._PROCESSED_}))
                {
                    if ($e.Count -gt 1) {Write-Warning -Message "Found $($e.Count) objects matching ""$key"", just selecting first match"}
                    $e = $e[0]
                    $e | Add-Member -NotePropertyName _PROCESSED_ -NotePropertyValue $true
                    if (Compare-Object -ReferenceObject $e -DifferenceObject $InputObject -Property $allProperties -CaseSensitive)
                    {
                        # PoShKeePass has multiple errors - if you have two groups with the same name (even if it isn't same cAsE) you can run into trouble
                        "Updating $key" | Write-Host
                        if (-not $DryRun)
                        {
                            Get-KeePassEntry @p | Where-Object -FilterScript {([string] $_.Uuid) -eq $e.Id} | Update-KeePassEntry @p -Force @entryParams
                        }
                    }
                    else
                    {
                        "OK $key" | Write-Host
                    }
                }
                else
                {
                    "Creating $key" | Write-Host
                    if (-not $DryRun)
                    {
                        $null = NewEntry -Path $fullPath -Params $entryParams
                    }
                }
            }

        }
        catch
        {
            Write-Verbose -Message "Encountered an error: $_"
            Write-Error -ErrorAction $origErrorActionPreference -Exception $_.Exception
        }
        finally
        {
            $ErrorActionPreference = $origErrorActionPreference
        }

        Write-Verbose -Message 'Process end'
    }

    end
    {
        # Not processed
        #$existing | Where-Object -FilterScript {-not $_._PROCESSED_}

        Write-Verbose -Message 'End'
    }
}