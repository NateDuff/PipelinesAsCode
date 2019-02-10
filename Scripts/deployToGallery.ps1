Param(
    $galleryKey,
    $moduleName = "PipelinesAsCode",
    $modulePath = ".\CI Build\drop\Module",
    $releaseVersion,
    [switch]$Prerelease
)

$module = "$modulePath\$moduleName"

if ($Prerelease)
{
    [version]$previousVersion = (Find-Module PipelinesAsCode -MaximumVersion ([Version]::new(0,9,99))).Version
}
else
{
    [version]$previousVersion = (Find-Module $moduleName -AllVersions | select -First 1).Version
}

if (!$previousVersion)
{
    $previousVersion = [version]::new(0, 0, 1)
}

$previousMajorVersion = $previousVersion.Major
$previousMinorVersion = $previousVersion.Minor
$previousBuildVersion = $previousVersion.Build

$newVersion = $releaseVersion.Split(".")

$newMajorVersion = $newVersion | select -First 1
$newMinorVersion = $newVersion | select -Last 1

if ($previousMajorVersion -ne $newMajorVersion) {
    $majorVersion = $newMajorVersion
} else {    
    $majorVersion = $previousMajorVersion    
}

if ($previousMinorVersion -ne $newMinorVersion) {
    $minorVersion = $newMinorVersion
} else {
    $minorVersion = $previousMinorVersion
}

if ($previousBuildVersion -eq -1) {
    $buildVersion = 1
} else {
    $buildVersion = $previousBuildVersion + 1
}

$moduleVersion = [version]::new($majorVersion, $minorVersion, $buildVersion)

Import-Module "$module.psm1"

Update-ModuleManifest -Path "$module.psd1" -ModuleVersion $moduleVersion -RootModule "$module.psm1"

Write-Output "New Version: $($moduleVersion.ToString())"

Import-Module "$module.psd1"

Publish-Module -Name "$module.psd1" -NuGetApiKey $galleryKey -Force # -RequiredVersion $releaseVersion

Write-Host "##vso[task.setvariable variable=ReleaseVersion;]$($moduleVersion.ToString())"
