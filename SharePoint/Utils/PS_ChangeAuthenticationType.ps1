############################################################################################################################################
# This script allows to change the authentication type for an existing web application
# Required Parameters:
# ->$sWebApplicationUrl: Url of the Web Application where we are going to change the authentication type.
# ->$sAuthenticationType: Authentication Type.
# References:
# -> http://technet.microsoft.com/en-us/library/gg251985(v=office.15).aspx
############################################################################################################################################
If ((Get-PSSnapIn -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null ) 
{ Add-PSSnapIn -Name Microsoft.SharePoint.PowerShell }

$host.Runspace.ThreadOptions = "ReuseThread"

#This function is itended to add a Claims user to the Web Application where we have changed authentication from Classic to Claims
function AddUserToWebApp
{
    param ($spWebApplication,$sAccount)
    try
    {   
        $spAccount = (New-SPClaimsPrincipal -identity $sAccount -identitytype 1).ToEncodedString()                
        $spZonePolicy = $spWebApplication.ZonePolicies("Default")
        $spPolicy = $spZonePolicy.Add($spAccount,"PSPolicy")
        $spFullControlRole=$spWebApplication.PolicyRoles.GetSpecialRole("FullControl")
        $spPolicy.PolicyRoleBindings.Add($spFullControlRole)
        $spWebApplication.Update()	
    }
    catch [System.Exception]
    {
        write-host -f red $_.Exception.ToString()
    }
}

#Function that changes the authentication type for an existing Web Application
function ChangeAuthenticationType
{  
    param ($sAuthenticantionType, $sWebApplicationUrl)
    try
    {  
        $spWebApplication=Get-SPWebApplication $sWebApplicationUrl
        Write-Host -f green "Changing the authentication type of $sWebApplicationUrl to $sAuthenticantionType"
        switch -wildcard ($sAuthenticantionType) 
        { 
            "Claims" 
            {                
                $spWebApplication.UseClaimsAuthentication=1
                $spWebApplication.Update()
                AddUserToWebApp -spWebApplication $spWebApplication -sAccount "<Domain\Account>" 
                $spWebApplication.MigrateUsers($true)
		$spWebApplication.ProvisionGlobally()
            }
            "Classic"
            {
                $spWebApplication.UseClaimsAuthentication=0
                $spWebApplication.Update()
            } 
            default 
            {
                Write-Host -f blue "Authentication type has not been changed. Invalid option"
            }
        }
    }
    catch [System.Exception]
    {
        write-host -f red $_.Exception.ToString()
    }
}

Start-SPAssignment –Global
ChangeAuthenticationType -sAuthenticantionType "Claims" -sWebApplicationUrl "http://<WebAppUrl>"
Stop-SPAssignment –Global

Remove-PsSnapin Microsoft.SharePoint.PowerShell