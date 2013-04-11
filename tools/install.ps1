param($installPath, $toolsPath, $package, $project)

Import-Module (Join-Path $toolsPath NewRelicHelper.psm1)

Write-Host "***Updating project items newrelic.config***" -ForegroundColor DarkGreen
$newrelic = $project.ProjectItems.Item("newrelic")
$config = $newrelic.ProjectItems.Item("newrelic.config")
$configPath = $config.Properties.Item("LocalPath").value

[xml] $configXml = Get-Content $configPath
$ns = @{ e = "urn:newrelic-config" }
$ns = New-Object Xml.XmlNamespaceManager $configXml.NameTable
$ns.AddNamespace( "e", "urn:newrelic-config" )

$projectName = $project.Name.ToString()

if($configXml -ne $null){

	#Modify NewRelic.config to accept the user's license key input 
	$licenseKey = create_dialog "License Key" "Please enter in your New Relic license key (optional)"
	
	if($licenseKey -ne $null -and $licenseKey.Length -gt 0){
		$serviceNode = $configXml.configuration.service
		if($serviceNode -ne $null){
			Write-Host "Updating licensekey in the newrelic.config file..."	 -ForegroundColor DarkGreen
			$serviceNode.SetAttribute("licenseKey", $licenseKey)
		}
	}
	else{
		Write-Host "No Key was provided, please make sure to edit the newrelic.config file & add a valid New Relic license key before deploying your application." -ForegroundColor DarkYellow
	}
	
	#Modify NewRelic.config to accept the user's app name input 
	$appName = create_dialog "NewRelic.AppName" "Please enter in the value you would like for the NewRelic.AppName AppSetting for the project named $projectName (optional, if none is provided we will use the solution name)."
	$appNode = $configXml.SelectSingleNode("//e:application[e:name/text()]", $ns)
	
	if($appNode -ne $null) {
		if($appName -ne $null -and $appName.Length -gt 0){
			Write-Host "Updating Application name in the newrelic.config file with the value provided..."  -ForegroundColor DarkGreen
			$appNode.name = $appName.ToString()
		}
		else{
			if( $appNode.name.Length -lt 1 -or  $appNode.name -eq "My Application"){
				Write-Host "Updating Application name in the newrelic.config file with the solution name..." -ForegroundColor DarkGreen	
				$appNode.name = $projectName
			}
			else{
			    Write-Host "Application name will not be updated, no new value was provied and a value already exists in the newrelic.config file..."  -ForegroundColor DarkYellow
			}
		}
	}
	
    # save the newrelic.config file
   	$configXml.Save($configPath)
}

Write-Host "***Package install is complete***" -ForegroundColor DarkGreen
	
Write-Host "Please make sure to go add the following configurations to your Azure website." -ForegroundColor DarkGreen
Write-Host "Go to manage.windowsazure.com, log in, navigate to your Web Site, choose 'configure' and add the following as 'app settings' " -ForegroundColor DarkGreen

#Write-Host $appSettings | Format-Table @{Expression={$_.Key};Label="Key";width=25},Value
Write-Host "Key					Value"
Write-Host "---------------------------------------"
Write-Host "COR_ENABLE_PROFILING	1"
Write-Host "COR_PROFILER			{71DA0A04-7777-4EC6-9643-7D28B46A8A41}"
Write-Host "COR_PROFILER_PATH		C:\Home\site\wwwroot\newrelic\NewRelic.Profiler.dll"
Write-Host "NEWRELIC_HOME			C:\Home\site\wwwroot\newrelic"

