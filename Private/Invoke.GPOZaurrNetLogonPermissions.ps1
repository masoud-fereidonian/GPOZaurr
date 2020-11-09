﻿$GPOZaurrNetLogonPermissions = [ordered] @{
    Name           = 'NetLogon Permissions'
    Enabled        = $true
    ActionRequired = $null
    Data           = $null
    Execute        = {
        Get-GPOZaurrNetLogon
    }
    Processing     = {
        foreach ($File in $Script:Reporting['NetLogonPermissions']['Data']) {
            if ($File.FileSystemRights -eq 'Owner') {
                $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwners']++
                if ($File.PrincipalType -eq 'WellKnownAdministrative') {
                    $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersAdministrative']++
                } elseif ($File.PrincipalType -eq 'Administrative') {
                    $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersAdministrative']++
                } else {
                    $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersNotAdministrative']++
                }
                if ($File.PrincipalSid -eq 'S-1-5-32-544') {
                    $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersAdministrators']++
                } elseif ($File.PrincipalType -in 'WellKnownAdministrative', 'Administrative') {
                    $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersAdministrativeNotAdministrators']++
                    $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersToFix']++
                } else {
                    $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersToFix']++
                }
                $Script:Reporting['NetLogonPermissions']['Variables']['Owner'].Add($File)
            } else {
                $Script:Reporting['NetLogonPermissions']['Variables']['NonOwner'].Add($File)
            }
        }
        if ($Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersToFix'].Count -gt 0) {
            $Script:Reporting['NetLogonPermissions']['ActionRequired'] = $true
        } else {
            $Script:Reporting['NetLogonPermissions']['ActionRequired'] = $false
        }
    }
    Variables      = @{
        NetLogonOwners                                = 0
        NetLogonOwnersAdministrators                  = 0
        NetLogonOwnersNotAdministrative               = 0
        NetLogonOwnersAdministrative                  = 0
        NetLogonOwnersAdministrativeNotAdministrators = 0
        NetLogonOwnersToFix                           = 0
        Owner                                         = [System.Collections.Generic.List[PSCustomObject]]::new()
        NonOwner                                      = [System.Collections.Generic.List[PSCustomObject]]::new()
    }
    Overview       = {
        New-HTMLPanel {
            New-HTMLText -Text 'Following chart presents ', 'NetLogon Summary' -FontSize 10pt -FontWeight normal, bold
            New-HTMLList -Type Unordered {
                New-HTMLListItem -Text 'NetLogon Files in Total: ', $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwners'] -FontWeight normal, bold
                New-HTMLListItem -Text 'NetLogon BUILTIN\Administrators as Owner: ', $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersAdministrators'] -FontWeight normal, bold
                New-HTMLListItem -Text "NetLogon Owners requiring change: ", $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersToFix'] -FontWeight normal, bold {
                    New-HTMLList -Type Unordered {
                        New-HTMLListItem -Text 'Not Administrative: ', $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersNotAdministrative'] -FontWeight normal, bold
                        New-HTMLListItem -Text 'Administrative, but not BUILTIN\Administrators: ', $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersAdministrativeNotAdministrators'] -FontWeight normal, bold
                    }
                }
            } -FontSize 10pt
            #New-HTMLText -FontSize 10pt -Text 'Those problems must be resolved before doing other clenaup activities.'
            New-HTMLChart {
                New-ChartPie -Name 'Correct Owners' -Value $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersAdministrators'] -Color LightGreen
                New-ChartPie -Name 'Incorrect Owners' -Value $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersToFix'] -Color Crimson
            } -Title 'NetLogon Owners' -TitleAlignment center
        }
        New-HTMLPanel {

        }
    }
    Summary        = {
        New-HTMLText -TextBlock {
            "NetLogon is crucial part of Active Directory. Files stored there are available on each and every computer or server in the company. "
            "Keeping those files clean and secure is very important task. "
            "It's important that NetLogon file owners are set to BUILTIN\Administrators (SID: S-1-5-32-544). "
            "Owners have full control over the file object. Current owner of the file may be an Administrator but it doesn't guarentee that he/she will be in the future. "
            "That's why as a best-practice it's recommended to change any non-administrative owners to BUILTIN\Administrators, and even Administrative accounts should be replaced with it. "
        } -FontSize 10pt
        New-HTMLList -Type Unordered {
            New-HTMLListItem -Text 'NetLogon Files in Total: ', $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwners'] -FontWeight normal, bold
            New-HTMLListItem -Text 'NetLogon BUILTIN\Administrators as Owner: ', $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersAdministrators'] -FontWeight normal, bold
            New-HTMLListItem -Text "NetLogon Owners requiring change: ", $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersToFix'] -FontWeight normal, bold {
                New-HTMLList -Type Unordered {
                    New-HTMLListItem -Text 'Not Administrative: ', $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersNotAdministrative'] -FontWeight normal, bold
                    New-HTMLListItem -Text 'Administrative, but not BUILTIN\Administrators: ', $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersAdministrativeNotAdministrators'] -FontWeight normal, bold
                }
            }
        } -FontSize 10pt
        New-HTMLText -Text "Follow the steps below table to get NetLogon Owners into compliant state." -FontSize 10pt
    }
    Solution       = {
        New-HTMLTab -Name 'NetLogon Owners' {
            New-HTMLSection -Invisible {
                New-HTMLPanel {
                    & $Script:GPOConfiguration['NetLogonPermissions']['Summary']
                }
                New-HTMLPanel {
                    New-HTMLChart {
                        New-ChartPie -Name 'Correct Owners' -Value $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersAdministrators'] -Color LightGreen
                        New-ChartPie -Name 'Incorrect Owners' -Value $Script:Reporting['NetLogonPermissions']['Variables']['NetLogonOwnersToFix'] -Color Crimson
                    } -Title 'NetLogon Owners' -TitleAlignment center
                }
            }
            New-HTMLSection -Name 'NetLogon Files List' {
                New-HTMLTable -DataTable $Script:Reporting['NetLogonPermissions']['Variables']['Owner'] -Filtering {
                    New-HTMLTableCondition -Name 'PrincipalSid' -Value "S-1-5-32-544" -BackgroundColor LightGreen -ComparisonType string
                    New-HTMLTableCondition -Name 'PrincipalSid' -Value "S-1-5-32-544" -BackgroundColor Salmon -ComparisonType string -Operator ne
                    New-HTMLTableCondition -Name 'PrincipalType' -Value "WellKnownAdministrative" -BackgroundColor LightGreen -ComparisonType string -Operator eq
                }
            }
            if ($Script:Reporting['NetLogonPermissions']['WarningsAndErrors']) {
                New-HTMLSection -Name 'Warnings & Errors to Review' {
                    New-HTMLTable -DataTable $Script:Reporting['NetLogonPermissions']['WarningsAndErrors'] -Filtering {
                        New-HTMLTableCondition -Name 'Type' -Value 'Warning' -BackgroundColor SandyBrown -ComparisonType string -Row
                        New-HTMLTableCondition -Name 'Type' -Value 'Error' -BackgroundColor Salmon -ComparisonType string -Row
                    }
                }
            }
            New-HTMLSection -Name 'Steps to fix NetLogon Owners ' {
                New-HTMLContainer {
                    New-HTMLSpanStyle -FontSize 10pt {
                        New-HTMLText -Text 'Following steps will guide you how to fix NetLogon Owners and make them compliant.'
                        New-HTMLWizard {
                            New-HTMLWizardStep -Name 'Prepare environment' {
                                New-HTMLText -Text "To be able to execute actions in automated way please install required modules. Those modules will be installed straight from Microsoft PowerShell Gallery."
                                New-HTMLCodeBlock -Code {
                                    Install-Module GPOZaurr -Force
                                    Import-Module GPOZaurr -Force
                                } -Style powershell
                                New-HTMLText -Text "Using force makes sure newest version is downloaded from PowerShellGallery regardless of what is currently installed. Once installed you're ready for next step."
                            }
                            New-HTMLWizardStep -Name 'Prepare report' {
                                New-HTMLText -Text "Depending when this report was run you may want to prepare new report before proceeding with removal. To generate new report please use:"
                                New-HTMLCodeBlock -Code {
                                    Invoke-GPOZaurr -FilePath $Env:UserProfile\Desktop\GPOZaurrNetLogonBefore.html -Verbose -Type NetLogon
                                }
                                New-HTMLText -TextBlock {
                                    "When executed it will take a while to generate all data and provide you with new report depending on size of environment."
                                    "Once confirmed that data is still showing issues and requires fixing please proceed with next step."
                                }
                                New-HTMLText -Text "Alternatively if you prefer working with console you can run: "
                                New-HTMLCodeBlock -Code {
                                    $NetLogonOutput = Get-GPOZaurrNetLogon -Verbose
                                    $NetLogonOutput | Format-Table
                                }
                                New-HTMLText -Text "It provides same data as you see in table above just doesn't prettify it for you."
                            }
                            New-HTMLWizardStep -Name 'Set non-compliant file owners to BUILTIN\Administrators' {
                                New-HTMLText -Text "Following command when executed runs internally command that lists all file owners and if it doesn't match changes it BUILTIN\Administrators. It doesn't change compliant owners."
                                New-HTMLText -Text "Make sure when running it for the first time to run it with ", "WhatIf", " parameter as shown below to prevent accidental removal." -FontWeight normal, bold, normal -Color Black, Red, Black

                                New-HTMLCodeBlock -Code {
                                    Repair-GPOZaurrNetLogonOwner -Verbose -WhatIf
                                }
                                New-HTMLText -TextBlock {
                                    "After execution please make sure there are no errors, make sure to review provided output, and confirm that what is about to be changed matches expected data. Once happy with results please follow with command: "
                                }
                                New-HTMLCodeBlock -Code {
                                    Repair-GPOZaurrNetLogonOwner -Verbose -LimitProcessing 2
                                }
                                New-HTMLText -TextBlock {
                                    "This command when executed sets new owner only on first X non-compliant NetLogon files. Use LimitProcessing parameter to prevent mass change and increase the counter when no errors occur."
                                    "Repeat step above as much as needed increasing LimitProcessing count till there's nothing left. In case of any issues please review and action accordingly."
                                }
                            }
                            New-HTMLWizardStep -Name 'Verification report' {
                                New-HTMLText -TextBlock {
                                    "Once cleanup task was executed properly, we need to verify that report now shows no problems."
                                }
                                New-HTMLCodeBlock -Code {
                                    Invoke-GPOZaurr -FilePath $Env:UserProfile\Desktop\GPOZaurrNetLogonAfter.html -Verbose -Type NetLogon
                                }
                                New-HTMLText -Text "If everything is healthy in the report you're done! Enjoy rest of the day!" -Color BlueDiamond
                            }
                        } -RemoveDoneStepOnNavigateBack -Theme arrows -ToolbarButtonPosition center
                    }
                }
            }
        }
        New-HTMLTab -Name 'NetLogon Permissions' {
            New-HTMLSection -Name 'NetLogon Files List' {
                New-HTMLTable -DataTable $Script:Reporting['NetLogonPermissions']['Variables']['NonOwner'] -Filtering
            }
        }
    }
}