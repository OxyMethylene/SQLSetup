# Loads the config file.
$Config = (Get-Content ".\parameters.json") -join "`n" | ConvertFrom-Json

function Start-Executable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        #[ValidateScript({ Test-Path $_ -PathType Leaf -Include "*.ini" })]
        [string]$configPath,
        [Parameter(Mandatory = $false)]
        #[ValidateScript({ Test-Path $_ -PathType Leaf -Include "setup.exe" })]
        [string]$setupEXEPath
    )

    DynamicParam { 
        $RuntimeParamDic = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        <# 
        Uses JSON file to create all parameters
        Parameters can be devided in different groups, making them mandatory only when a specific feaature has been selected
        #>
        # Mandatory Global Parameters
        foreach ($paramGroup in $($config).Parameters) {
            foreach ($param in $paramGroup) {
                # Create parameter group
                $ParamAttrib = New-Object System.Management.Automation.ParameterAttribute
                $ParamAttrib.Mandatory = $param.isMandatory
                $ParamAttrib.ParameterSetName = $param.Group
    
                $AttribColl = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $AttribColl.Add($ParamAttrib)
                if ($param.ValidateSet) {
                    $AttribColl.Add((New-Object System.Management.Automation.ValidateSetAttribute($param.ValidateSet)))
                }
                
                # Define the type
                switch ($param.Type.ToUpper()) {
                    "INT32" { $paramType = [int32] }
                    "INT" { $paramType = [int] }
                    "BOOLEAN" { $paramType = [bool] }
                    "STRING" { $paramType = [string] }
                    "DATETIME" { $paramType = [DateTime] }
                    "REGEX" { $paramType = [regex] }
                    "FLOAT" { $paramType = [float] }
                    "TIMESPAN" { $paramType = [timespan] }
                    "ARRAY" { $paramType = [Array] }
                    "STRING[]" { $paramType = [string[]] }
                }
    
                # Create parameter and add it to the group
                $RuntimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter($param.Parameter.ToUpper(), $paramType, $AttribColl)
                $RuntimeParamDic.Add($param.Parameter.ToUpper(), $RuntimeParam)
            }
        }
        ##################### TEST
        return  $RuntimeParamDic
    }

    process {

        # Info to start process
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo;

        ############### Check what features have been chosen. This will define which parameters will become mandatory
        <# $PSBoundParameters.GetEnumerator() | Foreach-Object {   
            if ($_.Key.ToString().ToUpper() -eq "FEATURES" -or $_.Key.ToString().ToUpper() -eq "ROLE") {
                $OFS = ','
                $varFeatures = [string] $_.Value
            }
            $pinfo.Arguments += " /" + $_.Key + '=' + $_.Value;
            Write-Output "Variable: $($_.Key)= $($_.Value)"
        } #>

        # Run executable
        $pinfo.FileName = $setupEXEPath;
        $pinfo.RedirectStandardOutput = $true;
        $pinfo.UseShellExecute = $false;
        $p = New-Object System.Diagnostics.Process;
        $p.StartInfo = $pinfo;
        $p.Start();
        Write-Output "$($pinfo.FileName)$($pinfo.Arguments)"
    }
}

#Start-Executable -IACCEPTSQLSERVERLICENSETERMS $true -IACCEPTROPENLICENSETERMS $true -IACCEPTPYTHONLICENSETERMS $true -ACTION "INSTALL" -CONFIGURATIONFILE "C:\SQLServer\SQLServer2017Media\Developer_ENU\SqlServerInstallConfig.ini" -FEATURES "AS,IS,Tools,SQL"