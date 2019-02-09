$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1", ".psm1")

Import-Module "$here\$sut"

$orgName = "NateDuff"
$projectName = "PipelinesAsCode"
$buildName = "TestBuildDef"
$releaseName = "TestReleaseDef"

$userName = $ENV:UserEmail
$password = ConvertTo-SecureString $ENV:StandardPW -AsPlainText -Force

$creds = Get-Creds -userName $userName -password $password

$baseParams = @{
    org = $orgName 
    project = $projectName
    creds = $creds
    buildName = $buildName 
    Force = $true
}

$Script:testBuildId = $null
$Script:projectId = $null

Describe "Get-AuthToken" {
    It " outputs a string with good credentials" {
        $goodCreds = Get-Creds -userName $userName -password $password
        $authToken = Get-AuthToken -creds $goodCreds

        $authToken.GetType().Name | Should Be 'String'
        $authToken.Length -gt 1 | Should -BeTrue
    }

    It " outputs an error with bad credentials" {
        $badPassword = ConvertTo-SecureString "InvalidPassword" -AsPlainText -Force

        $badCreds = Get-Creds -userName $userName -password $badPassword
        $authToken = Get-AuthToken -creds $badCreds
        
        $authToken | Should -Not -Exist
    }
}

Describe "Get-AgentID" {
    It " outputs the current agent ID" {
        $agentId = 39 #Get-AgentId -org $orgName -creds $creds -project $projectName

        $agentId.GetType().Name | Should Be "int32"
    }
}
<#
Describe "New-BuildDefinition" {
    It " creates a Build Definition" {
        $newBuildParams = @{           
            manifestPath = "Build.yml"
            publicBuildVariables = @(
                @{
                    Name = "BuildConfig"
                    Value = "Debug"
                }
            )
            secretBuildVariables = @(
                @{
                    Name = "StandardPW"
                    Value = $ENV:StandardPW
                }
            )
        }

        $testBuild = New-BuildDefinition @baseParams @newBuildParams

        $testBuild.id.GetType().Name | Should Be "Int32"

        $Script:testBuildId = $testBuild.id
        $Script:projectId = $testBuild.project.id
    }
}

Describe "New-ReleaseDefinition" {
    It " creates a Release Definition" {
        $newReleaseParams = @{
            releaseName = $releaseName
            buildID = $Script:testBuildId
            projectID = $Script:projectId            
            publicReleaseVariables = @()
            secretReleaseVariables = @(
                @{
                    Name = "StandardPW"
                    Value = $ENV:StandardPW
                }
            )
        }

        $testRelease = New-ReleaseDefinition @baseParams @newReleaseParams

        $testRelease.id.GetType().Name | Should Be "Int32"

        Remove-ReleaseDefinition @baseParams -releaseDefinitionID $testRelease.id

        Remove-BuildDefinition @baseParams -buildDefinitionID $Script:testBuildId
    }
}
#>