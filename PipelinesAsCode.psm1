Function Get-DeployVariables ($publicVariables, $secretVariables) {
    $output = @{}

    foreach ($var in $publicVariables) {
        $output += @{
            $var.Name = @{
                value = $var.Value
                isSecret = $false
            }
        }
    }

    foreach ($var in $secretVariables) {
        $output += @{
            $var.Name = @{
                value = $var.Value
                isSecret = $true
            }
        }
    }

    return $output
}

Function Get-Creds ([string]$userName, [securestring]$password) {
    return New-Object System.Management.Automation.PSCredential ($userName, $password)
}

Function Get-AuthToken ([pscredential]$creds) {
    $pair = "$($creds.UserName):$($creds.GetNetworkCredential().Password)"
    
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    
    return [System.Convert]::ToBase64String($bytes)
}

Function New-BuildDefinition {
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [string]$org, 
        [string]$project, 
        [string]$buildName, 
        [pscredential]$creds, 
        [string]$manifestPath,
        $publicBuildVariables,
        $secretBuildVariables,
        [switch]$Force
    )

    begin {
        $uri = "https://dev.azure.com/$org/$project/_apis/build/definitions`?api-version=5.0-preview.7"

        $payload = @{
            name = $buildName
            buildNumberFormat = "`$(Build.DefinitionName)-`$(date:yyyyMMdd)`$(rev:.r)"
            badgeEnabled = $true
            queue = @{
                name = "Hosted"
            }
            repository = @{
                name = $project
                defaultBranch = "refs/heads/master"
                clean = $true
                type = "TfsGit"
                properties = @{
                    cleanOptions = 1
                    reportBuildStatus = $true
                }
            }
            process = @{
                yamlFilename = $manifestPath
                type = 2
            }
            variables = Get-DeployVariables $publicBuildVariables $secretBuildVariables
        }

        $newBuildParams = @{
            uri = $uri 
            Method = "Post"
            Body = ($payload | ConvertTo-Json -Compress)
            Headers = @{
                Authorization = ("Basic {0}" -f (Get-AuthToken -creds $creds))
            }
            Credential = $creds
            ContentType = "application/json"
        }
    }

    process {
        if ($Force -or $PSCmdlet.ShouldProcess(
            $buildName,             
            "Create Build Definition for $org on $project" 
        )) {
            (Invoke-WebRequest @newBuildParams).Content | ConvertFrom-Json
        }
    }
}

Function Get-AgentID {
    Param(
        [string]$org,
        [string]$project = "PipelinesAsCode",
        [pscredential]$creds 
    )

    $uri = (Get-ReleaseDefinions -org $org -project $project).value.url

    return (Invoke-RestMethod $uri).environments[0].deployPhases[0].deploymentInput.queueId
}

Function Get-DeploymentPhases {
    Param(
        [string]$environmentName, 
        [string]$org, 
        [pscredential]$creds
    )

    $hostedQueue = @{
        queueId = Get-AgentID -org $org -creds $creds
    }

    $deployPhases = @(
        @{
            name = "Stage $environmentName Environment"
            phaseType = "agentBasedDeployment"
            rank = 1
            deploymentInput = $hostedQueue
        },
        @{
            name = "Deploy to $environmentName"
            phaseType = "agentBasedDeployment"
            rank = 2
            deploymentInput = $hostedQueue
        }
    )

    if ($environmentName -eq "Prod") {
        return $deployPhases
    } else {
        return @(
            $deployPhases
            @{
                name = "Cleanup $environmentName Environment"
                phaseType = "agentBasedDeployment"
                rank = 3
                deploymentInput = $hostedQueue
            }
        )
    }
}

Function New-Environment ([string]$environmentName, [int]$rank, [string]$org) {
    switch ($environmentName) {
        "Dev" {
            $condition = @{
                name = "ReleaseStarted"
                conditionType = "event"
            }
        }
        "Test" {
            $condition = @{
                name = "Dev"
                conditionType = "environmentState"
                value = 4
            }
        }
        "Prod" {
            $condition = @{
                name = "Test"
                conditionType = "environmentState"
                value = 6
            }
        }
    }

    return @{
        name = $environmentName
        rank = $rank
        source = "restApi"
        conditions = @(
            $condition
        )
        retentionPolicy = @{
            daysToKeep = 30
            releasesToKeep = 3
            retainBuild = $true
        }
        executionPolicy = @{
            concurrencyCount = 1
            queueDepthCount = 0
        }
        deployPhases = @(Get-DeploymentPhases -environmentName $environmentName -org $org)
        environmentOptions = @{
            badgeEnabled = $true
            autoLinkWorkItems = $true
            publishDeploymentStatus = $true
        }
        preDeployApprovals = @{
            approvals = @(
                @{
                    isAutomated = $true
                    rank = 1
                    isNotification = $false
                    id = 1
                }
            )
        }
        preDeploymentGates = @{
            gates = $null
        }
        postDeployApprovals = @{
            approvals = @(
                @{
                    isAutomated = $true
                    rank = 1
                    isNotification = $false
                    id = 1
                }
            )
        }
        postDeploymentGates = @{
            gates = $null
        }
    }
}

Function New-ReleaseDefinition {
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [string]$org, 
        [string]$project, 
        [string]$releaseName, 
        [pscredential]$creds, 
        [string]$buildName, 
        [string]$buildID,
        [string]$projectID,
        $publicReleaseVariables,
        $secretReleaseVariables,
        [switch]$Force
    )

    begin {
        $uri = "https://vsrm.dev.azure.com/$org/$project/_apis/release/definitions?api-version=5.0-preview.3"

        $orgParams = @{
            org = $org
            creds = $creds
        }

        $payload = @{
            name = $releaseName        
            releaseNameFormat = "Release-`$(rev:r)"
            artifacts = @(
                @{
                    definitionReference = @{
                        definition = @{
                            id = $buildID
                            name = $buildName
                        }
                        project = @{
                            id = $projectId
                            name = $project
                        }
                    }
                    isPrimary = $true
                    isRetained = $false
                    alias = $buildName
                    type = "Build"
                }
            )
            environments = @(
                (New-Environment -environmentName "Dev" -rank 1 @orgParams),
                (New-Environment -environmentName "Test" -rank 2 @orgParams),
                (New-Environment -environmentName "Prod" -rank 3 @orgParams)
            )
            triggers = @(
                @{
                    artifactAlias = $buildName
                    triggerType = "artifactSource"
                }
            )
            variables = Get-DeployVariables $publicReleaseVariables $secretReleaseVariables
        }

        $newReleaseParams = @{
            uri = $uri 
            Method = "Post"
            Body = ($payload | ConvertTo-Json -Compress -Depth 100)
            Headers = @{
                Authorization = ("Basic {0}" -f (Get-AuthToken -creds $creds))
            }
            Credential = $creds
            ContentType = "application/json"
        }
    }

    process{
        if ($Force -or $PSCmdlet.ShouldProcess(
            $releaseName,             
            "Create Release Definition for $org on $project" 
        )) {
            (Invoke-WebRequest @newReleaseParams).Content | ConvertFrom-Json
        }
    }
} 

Function Remove-ReleaseDefinition {
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [string]$org, 
        [string]$project, 
        [int]$releaseDefinitionID, 
        [pscredential]$creds,
        [switch]$Force
    )

    begin {
        $uri = "https://vsrm.dev.azure.com/$org/$project/_apis/release/definitions/$releaseDefinitionID`?api-version=5.0-preview.3"

        $removeReleaseParams = @{
            uri = $uri 
            Method = "Delete"
            Headers = @{
                Authorization = ("Basic {0}" -f (Get-AuthToken -creds $creds))
            }
            Credential = $creds
            ContentType = "application/json"
        }
    }

    process {
        if ($Force -or $PSCmdlet.ShouldProcess(
            $releaseDefinitionID,             
            "Remove Release Definition for $org on $project" 
        )) {
            (Invoke-WebRequest @removeReleaseParams).Content | ConvertFrom-Json
        }
    }
}

Function Remove-BuildDefinition {
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [string]$org, 
        [string]$project, 
        [int]$buildDefinitionID, 
        [pscredential]$creds,
        [switch]$Force
    )

    begin {
        $uri = "https://dev.azure.com/$org/$project/_apis/build/definitions/$buildDefinitionID`?api-version=5.0-preview.7"

        $removeBuildParams = @{
            uri = $uri 
            Method = "Delete"
            Headers = @{
                Authorization = ("Basic {0}" -f (Get-AuthToken -creds $creds))
            }
            Credential = $creds
            ContentType = "application/json"
        }
    }

    process {
        if ($Force -or $PSCmdlet.ShouldProcess(
            $buildDefinitionID,             
            "Remove Build Definition for $org on $project" 
        )) {
            (Invoke-WebRequest @removeBuildParams).Content | ConvertFrom-Json
        }
    }
}

function Get-ReleaseDefinions ([string]$org, [string]$project) {
    $uri = "https://vsrm.dev.azure.com/$org/$project/_apis/release/definitions?api-version=5.0-preview.3"

    return (Invoke-WebRequest $uri).Content | ConvertFrom-Json
}

function Get-BuildDefinions ([string]$org, [string]$project) {
    $uri = "https://dev.azure.com/$org/$project/_apis/build/definitions?api-version=5.0-preview.7"

    return (Invoke-WebRequest $uri).Content | ConvertFrom-Json
}