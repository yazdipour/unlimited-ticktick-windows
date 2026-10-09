#requires -Version 7.0
[CmdletBinding()]
param(
    [uri]$InstallerUrl = $(if ($env:TICKTICK_TEST_INSTALLER_URL) {
        $env:TICKTICK_TEST_INSTALLER_URL
    } else {
        'https://download.ticktick.app/download/win64/tick_win_setup_release_x64_8215.exe'
    }),

    [string]$OutputDirectory = (Join-Path $PSScriptRoot ('../artifacts/installer-test/' + [guid]::NewGuid().ToString('N')))
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
Start-Transcript -Path (Join-Path $OutputDirectory 'test.log') | Out-Null
try {
    # Exercise the real URL download, build, patch, repack and payload hash checks.
    & (Join-Path $PSScriptRoot 'Build-PatchedInstaller.ps1') -InstallerUrl $InstallerUrl -OutputDirectory $OutputDirectory
    $installer = Join-Path $OutputDirectory 'TickTick Unlimited.exe'
    if (-not (Test-Path -LiteralPath $installer -PathType Leaf) -or (Get-Item -LiteralPath $installer).Length -eq 0) {
        throw 'Installer was not produced.'
    }
    $work = @(Get-ChildItem -LiteralPath $OutputDirectory -Directory -Filter 'work-*')
    if ($work.Count -ne 1) { throw 'Expected exactly one build working directory.' }
    $packagedApp = Join-Path $work[0].FullName 'verification/{app}/TickTick.exe'

    # Inspect the assembly recovered from the FINAL installer, without executing it.
    # Reuse the patcher's existing dependency; no test framework or new packages.
    Add-Type -Path (Join-Path $PSScriptRoot '../bin/Release/net8.0/dnlib.dll')
    $module = [dnlib.DotNet.ModuleDefMD]::Load($packagedApp)
    try {
        $userModel = @($module.Types | Where-Object FullName -EQ 'ticktick_WPF.Models.UserModel')
        if ($userModel.Count -ne 1) { throw 'Packaged UserModel was not found.' }
        $pro = @($userModel[0].Properties | Where-Object Name -EQ 'pro')
        $endDate = @($userModel[0].Properties | Where-Object Name -EQ 'proEndDate')
        if ($pro.Count -ne 1 -or $endDate.Count -ne 1) { throw 'Packaged patch targets were not found.' }

        $proInstructions = @($pro[0].GetMethod.Body.Instructions)
        if (($proInstructions.OpCode.Name -join '|') -ne 'ldc.i4.1|ret' -or
            $pro[0].PropertySig.RetType.FullName -ne 'System.Boolean') {
            throw 'Packaged pro getter does not return true.'
        }
        $dateInstructions = @($endDate[0].GetMethod.Body.Instructions)
        if (($dateInstructions.OpCode.Name -join '|') -ne 'ldsfld|newobj|ret' -or
            $dateInstructions[0].Operand.FullName -ne 'System.DateTime System.DateTime::MaxValue' -or
            $dateInstructions[1].Operand.FullName -ne 'System.Void System.Nullable`1<System.DateTime>::.ctor(System.DateTime)' -or
            $dateInstructions[1].Operand.MethodSig.Params[0].FullName -ne '!0' -or
            $endDate[0].PropertySig.RetType.FullName -ne 'System.Nullable`1<System.DateTime>') {
            throw 'Packaged proEndDate getter does not return nullable DateTime.MaxValue.'
        }
    } finally {
        $module.Dispose()
    }
    Write-Host 'PASS: installer download, patch, repack, payload hashes and packaged getter IL.'
} finally {
    Stop-Transcript | Out-Null
}
