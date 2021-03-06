############################################################################################################################################
# This Script allows to create & update property bags at different scopes
# Required parameters
#    ->$sInputFile: CSV file that stores the property bags to be created / updated
#    ->$sSiteCollectionUrl: Site Collection where Property Bags are created / updated.
############################################################################################################################################

If ((Get-PSSnapIn -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null ) 
{ Add-PSSnapIn -Name Microsoft.SharePoint.PowerShell }

$host.Runspace.ThreadOptions = "ReuseThread"

#
#Function that reads the CSV file containing the Property Bags
#
function ReadPropertyBagsFromFile
{
    param ($sInputFile,$sSiteCollectionUrl) 
    try
    {
        $bFileExists = (Test-Path $sInputFile -PathType Leaf) 
        if ($bFileExists) { 
            "Loading $sInputFile for processing..." 
            $tblData = Import-CSV $sInputFile            
        } else { 
            Write-Host "File $sInputFile not found. Stopping loading process !" -ForegroundColor Red
            exit 
        }
        Write-Host "Creating/Updating Property Bags ..." -ForegroundColor Green    
        foreach ($fila in $tblData) 
        {  
            #$fila       
            $sPBScope=$fila.PropertyBagScope.ToString()            
            $sPBKey=$fila.PropertyBagKey.ToString() 
            $sPBValue=$fila.PropertyBagValue.ToString()
	    #Calling the function that creates/updates the property bags
            CreateUpdatePropertyBag -sPropertyBagScope  $sPBScope -sPropertyBagKey $sPBKey -sPropertyBagValue $sPBValue
        }   
    }
    catch [System.Exception]
    {
        write-host -f red $_.Exception.ToString()
    }
}

#
#Function that creates/updates each property bag
#
function CreateUpdatePropertyBag
{
    param ($sPropertyBagScope,$sPropertyBagKey,$sPropertyBagValue)
    try
    {              
        switch ($sPropertyBagScope) 
        { 
        "Farm" {
            $spfFarm=Get-SPFarm
            $sPropertyBag=$spfFarm.Properties[$sPropertyBagKey]
            if($sPropertyBag -eq "")
            {  
                Write-Host "Adding Property Bag $sPropertyBagKey ato the farm!!" -ForegroundColor Green
                $spfFarm.Properties.Add($sPropertyBagKey,$sPropertyBagValue)           
            }else{
                Write-Host "Updating Property Bag $sPropertyBagKey in the granja" -ForegroundColor Green
                $spfFarm.Properties[$sPropertyBagKey]=$sPropertyBagValue
            }
            $spfFarm.Update()            
            $sPropertyBag=$spfFarm.Properties[$sPropertyBagKey]
            Write-Host "Property bag $sPropertyBagKey has a value $sPropertyBag" -ForegroundColor Green
            } 
        "WebApplication" {
            #Code for Web Application Property bags here
            }
        "SiteCollection" {
            $spSite=Get-SPSite -Identity $sSiteCollection
            $spwWeb=$spSite.OpenWeb()
            $sPropertyBag=$spwWeb.AllProperties[$sPropertyBagKey]
            if($sPropertyBag -eq "")
            {  
                Write-Host "Adding Property Bag $sPropertyBagKey to $sSiteCollection !!" -ForegroundColor Green
                $spwWeb.AllProperties.Add($sPropertyBagKey,$sPropertyBagValue) 
            }else{
                Write-Host "Updating Property Bag $sPropertyBagKey for $sSiteCollection" -ForegroundColor Green            
                $spwWeb.AllProperties[$sPropertyBagKey]=$sPropertyBagValue
            }           
            $spwWeb.Update()            
            $sPropertyBag=$spwWeb.AllProperties[$sPropertyBagKey]
            Write-Host "Property bag $sPropertyBagKey has a value $sPropertyBag" -ForegroundColor Green
            }
        "Site" {
            #Código para Property Bags de Sitio aquí
            } 
        "List" {
            #Código para Property Bags de Lista aquí
            }           
        default {
            Write-Host "Requested opeartion is not valid!!" -ForegroundColor DarkBlue            
            }
        }        
    }
    catch [System.Exception]
    {
        write-host -f red $_.Exception.ToString()
    }
}

$ScriptDir = Split-Path -parent $MyInvocation.MyCommand.Path
$sInputFile=$ScriptDir+ "\PropertyBags.csv"
$sSiteCollection="http://<YourSiteCollection>"

Start-SPAssignment –Global
#Calling the function
ReadPropertyBagsFromFile -sInputFile $sInputFile

Stop-SPAssignment –Global

Remove-PSSnapin Microsoft.SharePoint.PowerShell