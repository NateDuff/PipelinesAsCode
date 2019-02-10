# Pipelines As Code
[![codecov](https://codecov.io/gh/NateDuff/PipelinesAsCode/branch/master/graph/badge.svg)](https://codecov.io/gh/NateDuff/PipelinesAsCode)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/a1a1144423c64e3b8eed8f1a12e843b2)](https://www.codacy.com/app/NateDuff/PipelinesAsCode?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=NateDuff/PipelinesAsCode&amp;utm_campaign=Badge_Grade)
[![Build Status](https://dev.azure.com/NateDuff/PipelinesAsCode/_apis/build/status/CI%20Build?branchName=master)](https://dev.azure.com/NateDuff/PipelinesAsCode/_build/latest?definitionId=28&branchName=master)
[![Release Status](https://vsrm.dev.azure.com/NateDuff/_apis/public/Release/badge/ad13437d-ad6a-43cb-af82-61d7294a999e/1/1)](https://vsrm.dev.azure.com/NateDuff/_apis/public/Release/badge/ad13437d-ad6a-43cb-af82-61d7294a999e/1/1)
[![AzureRM](https://img.shields.io/powershellgallery/v/PipelinesAsCode.svg?style=flat-square&label=PowerShellGallery)](https://www.powershellgallery.com/packages/PipelinesAsCode/)

The purpose of this library is to provide Azure DevOps pipeline administrators with a way to define and maintain both Build and Release Definitions with YML files for configuration/infrastructure as code. 

## Prerequisites
*   PowerShellGet  
*   Microsoft Account   
*   Azure DevOps Account    
*   Azure DevOps Project

> 2 Guides Available: [Module Only](#Getting-Started---Module-only) or [Full Project](#Getting-Started---Full-Project))

## Getting Started - Module Only
These instructions will get you an updated copy of the module downloaded to your local machine and walk you through creating your first YML Build and Release Definitions!

### Installation - Module Only
Install the latest version of the module from the PowerShell Gallery:

```powershell
Install-Module PipelinesAsCode
```

Once you've installed this module to your local system you should be able to use the functions and commandlets provided:

```powershell
Import-Module PipelinesAsCode

Get-Command -Module PipelinesAsCode
```

## Getting Started - Full Project
These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See [Module Only](#Getting-Started---Module-only) section for notes on how to use the module on a live system.

### Installation - Full Project
Step by step instructions for how to install this project and the required dependencies to your local machine

Install the latest version of the module from the PowerShell Gallery:

```powershell
Install-Module PipelinesAsCode
```

Install Pester for running PowerShell unit tests from the PowerShell Gallery:

```powershell
Install-Module Pester
```

Once you've installed these modules to your local system you should be able to use the functions and commandlets provided:

```powershell
Import-Module Pester, PipelinesAsCode

Get-Command -Module Pester, PipelinesAsCode
```

## Execute Tests
Once you have the project and Pester module installed, open PowerShell and navigate to the project directory:

```powershell
Set-Location $HOME/source/repos/PipelinesAsCode
```

Once you have the test scripts pointed at your AzureDevOps instance you can go ahead and run the tests using Pester:

```powershell
Invoke-Pester .\PipelinesAsCode.Tests.ps1
```

## Development References
*    [Codecov.io](https://codecov.io) - Code Coverage
*    [Codacy](https://codacy.com) - Code Quality

## Module References
*   [YamlDotNet](https://github.com/aaubry/YamlDotNet) - .NET library to help convert YML to PowerShell objects

## Contributing
Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning
We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/NateDuff/PipelinesAsCode/tags). 

## Authors
*    **Nathan Duff** - [NateDuff](https://github.com/NateDuff)

<!-- 
See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project. 

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to anyone whose code was used
* Inspiration
* etc
-->