############################################################################################################################################
#This script allows to apply custom bradning recursively to all the sites defined in a site collection
#Required parametes:
#   ->$sSiteUrl: Site Collection Url
#   ->$sMasterUrl: Marte Page file
#   ->$sFeatureName: Branding feature name
############################################################################################################################################
If ((Get-PSSnapIn -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null ) 
{ Add-PSSnapIn -Name Microsoft.SharePoint.PowerShell }

$host.Runspace.ThreadOptions = "ReuseThread"

#Functiont that enables/disables the branding feature at the Site level
function EnableDisableFeature
{
    param ($spWeb,$sSiteUrl,$sFeatureName)
    try
    {
	$spFeature=Get-SPFeature -Web $spWeb | Where-object {$_.DisplayName -eq $sFeatureName}
        #Checking if the feature exist
	if($spFeature -ne $null)
	{
            Write-host "The feature $sFeatureName is enabled in the site $sSiteUrl .Disabling the feature ..." -f blue
            Disable-SPFeature –identity $sFeatureName -Url $sSiteUrl -Confirm:$false
            Write-host "Enabling the feature $sFeatureName in the sote $sSiteUrl ..." -f green
            Enable-SPFeature –identity $sFeatureName -Url $sSiteUrl		
	}
	else
	{
            Write-host "The feature $sFeatureName is not enabled in the site $sSiteUrl .Enabling la feature ..." -f blue
            Enable-SPFeature –identity $sFeatureName -Url $sSiteUrl
	}            
    }
    catch [System.Exception]
    {
        write-host -f red $_.Exception.ToString()
    } 	
}

#Definition of the function that applies the custom master page to all the sites in a site collection
function Aplicar-MasterPageSitios
{   
    param ($sFeatureName, $sSiteUrl,$sMasterUrl)
    try
    {
        $spSite = Get-SPSite $sSiteUrl    
        $spsubWebs = $spSite.AllWebs    
        foreach($spsubWeb in $spsubWebs)
        {
            Write-Host "Applying the custom master page to ($($spsubWeb.Url))" -foregroundcolor green
            #First, we enable the branding feature if required         
            EnableDisableFeature -spWeb $spsubWeb -sSiteUrl $spsubWeb.Url -sFeatureName $sFeatureName
            $spsubWeb.MasterUrl= $sMasterUrl
            $spsubWeb.Update()
        }     
        $spSite.Dispose()                
    }
    catch [System.Exception]
    {
        write-host -f red $_.Exception.ToString()
    } 
}

Start-SPAssignment –Global
#Applying Master page
$sSiteUrl="http://<SiteCollectionUrl>"
$sMasterUrl="/_catalogs/masterpage/<Custom>.master"
$sFeatureName="<BrandingFeatureName>"
Aplicar-MasterPageSitios -sFeatureName $sFeatureName -sSiteUrl $sSiteUrl -sMasterUrl $sMasterUrl
Stop-SPAssignment –Global
Remove-PsSnapin Microsoft.SharePoint.PowerShell