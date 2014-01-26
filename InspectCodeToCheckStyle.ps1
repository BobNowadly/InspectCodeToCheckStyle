function InspectCode-To-CheckStyle
{
 <#
  .SYNOPSIS
    This function converts Resharper InspectCode output to a CheckStyle output
  .DESCRIPTION
    The Jenkins Violations Plugin does not support InspectCode output. As a result I created this
    function to convert InspectCode output to a CheckStyle output.
    You can either import this script into your powershell build script or call this script from a 
    Jenkins Windows Batch file Step. 
  .EXAMPLE
    #Import the script to your script 
    . .\ResharperToCheckStyle.ps1
    InspectCode-To-CheckStyle "MyProject-ReSharper-Results.xml" "MyProject-CheckStyle.xml" "C:\Jenkins\Workspace\jobs\MyProject"
  .EXAMPLE
  # From command line
    Powershell.exe -noprofile -executionpolicy Bypass . ".\ResharperToCheckStyle.ps1";InspectCode-To-CheckStyle "MyProject-ReSharper-Results.xml" "MyProject-CheckStyle.xml" "C:\Jenkins\Workspace\jobs\MyProject"
  .PARAMETER resharperFile
    The path of the resharper file you would like to convert
  .PARAMETER checkstyleFile
    The File name that you would like to create for the checkstyle output
  .PARAMETER solutionFolderPath
    The absolute path to the solution folder you are inspecting. Resharper only uses a relative path from the 
    solution folder. The Jenkins violations plugin is expecting it to the an absolute path. 
  #>
[CmdletBinding()]
param(
    $resharperFile = "",
    $checkstyleFile = "",
    $solutionFolderPath = ""
)

begin {
    Write-Host "Converting $resharperFile to CheckStyle file $checkstyleFile"
}

process {
    [Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq") | Out-Null
    
    $resharperxml = [System.Xml.Linq.XDocument]::Load($resharperFile)
    
    $errorTypes = $resharperxml.Descendants("IssueType") |
        where {$_.Attribute("Severity").Value -ieq "ERROR"} |
        foreach {return $_.Attribute("Id").value}
    
    $warningTypes = $resharperxml.Descendants("IssueType") |
        where {$_.Attribute("Severity").Value -ieq "WARNING"} |
        foreach {return $_.Attribute("Id").value}
    
    $checkStylexml = $resharperxml.Descendants("Issue") |
        where {$errorTypes -contains $_.Attributes("TypeId").Value -or $warningTypes -contains $_.Attributes("TypeId").Value} |
        group{$_.Attributes("File").Value} | 
        ForEach { 
            $elem = "" 
            $elem += "<file name=`"$solutionFolderPath\" + $_.Name + "`" >" 
            
            foreach($g in $_.Group)
            {
                $severity = @{$true="ERROR";$false="WARNING"}[$errorTypes -contains $g.Attributes("TypeId").Value]
                $elem += "<error line=`"" + $g.Attributes("Line").Value + "`" message=`"" + $g.Attributes("Message").Value + "`" source=`"`" severity=`"$severity`" />" # TODO: See if we can pull out severity from type
            }
            
            $elem += "</file>"

            return $elem
       }
        
    "<checkstyle version=`"5.0`">" + $checkStylexml + "</checkstyle>" |  
        Out-File $checkstyleFile
}
}