function Export-KeePassEntry
{
    <#
        .SYNOPSIS
            xxx

        .DESCRIPTION
            xxx

        .PARAMETER RootPath
            xxx

        .PARAMETER WithId
            xxx

        .PARAMETER DatabaseProfileName
            xxx

        .PARAMETER MasterKey
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

        [Parameter()]
        [switch]
        $WithId,

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
        $rp = $RootPath -split '/'
    }

    process
    {
        Write-Verbose -Message "Process begin (ErrorActionPreference: $ErrorActionPreference)"

        try
        {
            # Make sure that we don't continue on error, and that we catches the error
            $ErrorActionPreference = 'Stop'

            Get-KeePassEntry @p -AsPlainText | ForEach-Object -Process {
                $fp = $_.FullPath -split '/'
                if (
                    $fp.Length -ge $rp.Length -and
                    ($fp[0..($rp.Length - 1)] -join '/') -ceq ($rp[0..($rp.Length - 1)] -join '/')
                )
                {
                    $e = [PSCustomObject] @{
                        Path     = ($fp | Select-Object -Skip $rp.Length) -join '/'
                        Name     = $_.Title
                        Username = $_.UserName
                        Password = $_.Password
                        Url      = $_.URL
                        Notes    = $_.Notes -replace "`r`n","`n"
                    }
                    if ($WithId) {$e | Add-Member -NotePropertyName Id -NotePropertyValue ([string] $_.Uuid)}
                    $e
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
        Write-Verbose -Message 'End'
    }
}