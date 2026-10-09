#requires -Version 7.0
[CmdletBinding(DefaultParameterSetName = 'Url')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Url')]
    [uri]$InstallerUrl,

    [Parameter(Mandatory, ParameterSetName = 'File')]
    [string]$InstallerPath,

    [string]$OutputDirectory = (Join-Path $PSScriptRoot '../artifacts/installer')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-Tool([string]$Executable, [string[]]$Arguments) {
    & $Executable @Arguments | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "$Executable failed with exit code $LASTEXITCODE."
    }
}

function Get-VerifiedTool([string]$Url, [string]$Destination, [string]$Sha256) {
    Invoke-WebRequest -Uri $Url -OutFile $Destination
    if ((Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash -ne $Sha256) {
        throw "Tool checksum mismatch: $Destination"
    }
}

function Get-PayloadPath([string]$Root, [string]$RelativePath) {
    # Treat recovered installer paths as data, never as compiler directives or commands.
    if ([string]::IsNullOrWhiteSpace($RelativePath) -or
        $RelativePath -match '[\x00-\x1f<>:"|?*{}]' -or
        [IO.Path]::IsPathRooted($RelativePath) -or
        @($RelativePath -split '[\\/]' | Where-Object {
            $_ -in @('', '.', '..') -or $_.EndsWith('.') -or $_.EndsWith(' ')
        }).Count -gt 0) {
        throw "Unsafe payload path: $RelativePath"
    }
    return Join-Path $Root $RelativePath
}

function Copy-AppPayload([string]$ExtractedDirectory, [string]$PayloadDirectory) {
    $inFiles = $false
    $count = 0
    # Only unconditional app-local copies with ignoreversion are supported. Fail closed
    # on other flags/conditions rather than silently changing installation semantics.
    $filePattern = '^Source: "\{app\}\\(?<source>[^"]+)"; DestDir: "\{app\}(?<directory>\\[^"]+)?"; (?:DestName: "(?<name>[^"]+)"; )?Flags: ignoreversion\s*$'
    foreach ($line in Get-Content -LiteralPath (Join-Path $ExtractedDirectory 'install_script.iss')) {
        if ($line -match '^\[(.+)\]\s*$') {
            $inFiles = $Matches[1] -eq 'Files'
            continue
        }
        if (-not $inFiles -or [string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith(';')) {
            continue
        }
        if ($line -notmatch $filePattern) {
            throw "Unsupported installer file entry: $line"
        }
        $entry = $Matches
        $source = Get-PayloadPath (Join-Path $ExtractedDirectory '{app}') $entry.source
        $name = if ($entry.ContainsKey('name')) { $entry.name } else { [IO.Path]::GetFileName($source) }
        if ($name -match '[\\/]') { throw "Invalid destination filename: $name" }
        $directory = if ($entry.ContainsKey('directory')) { $entry.directory.TrimStart('\') } else { '' }
        $relativeDestination = if ($directory) { "$directory\$name" } else { $name }
        $destination = Get-PayloadPath $PayloadDirectory $relativeDestination
        New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
        # Repeated destinations use the last entry, matching the original ignoreversion order.
        Copy-Item -LiteralPath $source -Destination $destination -Force
        $count++
    }
    if ($count -eq 0) { throw 'No supported application files found in the installer.' }
}

if (-not $IsWindows) { throw 'Installer packaging requires Windows and PowerShell 7.' }
if ($PSCmdlet.ParameterSetName -eq 'Url') {
    if (-not $InstallerUrl.IsAbsoluteUri -or $InstallerUrl.Scheme -ne 'https') {
        throw 'InstallerUrl must be an absolute HTTPS direct download URL.'
    }
} else {
    $InstallerPath = (Resolve-Path -LiteralPath $InstallerPath).Path
    if (-not (Test-Path -LiteralPath $InstallerPath -PathType Leaf)) {
        throw 'InstallerPath must point to an installer file.'
    }
}
$dotnet = (Get-Command dotnet -CommandType Application -ErrorAction Stop).Source
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
$output = Join-Path $OutputDirectory 'TickTick Unlimited.exe'
if (Test-Path -LiteralPath $output) {
    throw "Output already exists. Choose a different OutputDirectory: $output"
}
$work = Join-Path $OutputDirectory ('work-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work -Force | Out-Null
Write-Host "Working directory (retained for inspection): $work"

if ($PSCmdlet.ParameterSetName -eq 'Url') {
    $InstallerPath = Join-Path $work 'original-setup.exe'
    Write-Host 'Downloading installer...'
    Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath
}

# Portable, pinned tools. Neither the input installer nor the compiler installer is run.
$unpackerZip = Join-Path $work 'innounp.zip'
Get-VerifiedTool `
    'https://github.com/jrathlev/InnoUnpacker-Windows-GUI/releases/download/oi_2_2_11/innounp-2.zip' `
    $unpackerZip '851772538a041229102ad9964542d49dc00c74002e3091a70469c079ae368f52'
$unpackerDirectory = Join-Path $work 'innounp'
Expand-Archive -LiteralPath $unpackerZip -DestinationPath $unpackerDirectory
$unpacker = Join-Path $unpackerDirectory 'innounp.exe'
$extracted = Join-Path $work 'extracted'
Write-Host 'Extracting installer...'
Invoke-Tool $unpacker @('-x', '-b', '-a', '-q', '-o', "-d$extracted", $InstallerPath)

$payload = Join-Path $work 'payload'
Copy-AppPayload $extracted $payload
$app = Join-Path $payload 'TickTick.exe'
if (-not (Test-Path -LiteralPath $app -PathType Leaf)) {
    throw 'Installer does not contain {app}\TickTick.exe.'
}
$version = [Diagnostics.FileVersionInfo]::GetVersionInfo($app).FileVersion.Trim()
if ($version -notmatch '^\d+\.\d+\.\d+\.\d+$') {
    throw "Unsupported application version: $version"
}

Write-Host "Patching TickTick $version..."
$project = Join-Path $PSScriptRoot '../TTPatcher.csproj'
Invoke-Tool $dotnet @('run', '--project', $project, '--configuration', 'Release', '--', $app)
$patched = Join-Path $payload 'TickTick_Patched.exe'
if (-not (Test-Path -LiteralPath $patched -PathType Leaf) -or (Get-Item -LiteralPath $patched).Length -eq 0) {
    throw 'Patcher did not produce a patched executable.'
}
$patchedHash = (Get-FileHash -LiteralPath $patched -Algorithm SHA256).Hash
if ($patchedHash -eq (Get-FileHash -LiteralPath $app -Algorithm SHA256).Hash) {
    throw 'Patcher output is unchanged.'
}
Move-Item -LiteralPath $patched -Destination $app -Force

$compilerSetup = Join-Path $work 'innosetup.exe'
Get-VerifiedTool `
    'https://github.com/jrsoftware/issrc/releases/download/is-6_7_0/innosetup-6.7.0.exe' `
    $compilerSetup 'f45c7d68d1e660cf13877ec36738a5179ce72a33414f9959d35e99b68c52a697'
$compilerDirectory = Join-Path $work 'compiler'
Invoke-Tool $unpacker @('-x', '-b', '-a', '-q', '-o', "-d$compilerDirectory", $compilerSetup, '{app}\*')
$compiler = Join-Path $compilerDirectory '{app}/ISCC.exe'
$packageDirectory = Join-Path $work 'package'
Write-Host 'Building unsigned installer...'
Invoke-Tool $compiler @('/Qp', "/DPayloadDir=$payload", "/DAppVersion=$version", "/O$packageDirectory", (Join-Path $PSScriptRoot 'PatchedInstaller.iss'))
$package = Join-Path $packageDirectory 'TickTick Unlimited.exe'

# Round-trip check: verify every packaged file, not just the presence of a setup EXE.
$verification = Join-Path $work 'verification'
Invoke-Tool $unpacker @('-x', '-b', '-a', '-q', '-o', "-d$verification", $package)
$verifiedPayload = Join-Path $verification '{app}'
$expectedFiles = @(Get-ChildItem -LiteralPath $payload -File -Recurse)
$actualFiles = @(Get-ChildItem -LiteralPath $verifiedPayload -File -Recurse)
if ($expectedFiles.Count -ne $actualFiles.Count) { throw 'Repacked payload file count mismatch.' }
foreach ($file in $expectedFiles) {
    $relative = [IO.Path]::GetRelativePath($payload, $file.FullName)
    $actual = Join-Path $verifiedPayload $relative
    if ((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash -ne
        (Get-FileHash -LiteralPath $actual -Algorithm SHA256).Hash) {
        throw "Repacked payload checksum mismatch: $relative"
    }
}
# Publish only after verification. Never overwrite an existing output.
[IO.File]::Copy($package, $output, $false)
Write-Host "Verified $($expectedFiles.Count) payload files. Installer: $output"
