InspectCodeToCheckStyle
=======================

SYNOPSIS
=======================
A Powershell function that converts Resharper InspectCode output to a CheckStyle output

DESCRIPTION
=======================
The Jenkins Violations Plugin does not support InspectCode output. As a result, I created this function to convert 
InspectCode output to a CheckStyle output. Then I can configure the Violations plugin to use the generated CheckStyle 
output. 

You can either import this script into your powershell build script or call this script from a Jenkins Windows 
Batch file Step.

