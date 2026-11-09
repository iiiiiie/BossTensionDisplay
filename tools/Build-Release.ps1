[CmdletBinding()]
param([string]$OutputDirectory)

$ErrorActionPreference = 'Stop'
$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $repositoryRoot 'dist'
}
$outputRoot = [System.IO.Path]::GetFullPath($OutputDirectory)
$archivePath = Join-Path $outputRoot 'BossTensionDisplay-0.1.1.zip'
$entries = @(
    'BossTensionDisplay/enabled.txt'
    'BossTensionDisplay/Scripts/main.lua'
    'BossTensionDisplay/Scripts/Reader.lua'
    'BossTensionDisplay/Scripts/HUD.lua'
    'BossTensionDisplay/Scripts/Settings.lua'
    'BossTensionDisplay/Scripts/Probe.lua'
    'README.md'
    'README.en.md'
    'LICENSE'
    'CHANGELOG.md'
    'docs/images/pressure-hud.png'
)

foreach ($entry in $entries) {
    if (!(Test-Path -LiteralPath (Join-Path $repositoryRoot $entry) -PathType Leaf)) {
        throw "Required release file is missing: $entry"
    }
}
if (Test-Path -LiteralPath $outputRoot) {
    if (!(Test-Path -LiteralPath $outputRoot -PathType Container)) {
        throw "Output path is not a directory: $outputRoot"
    }
    Get-ChildItem -LiteralPath $outputRoot -Force | Select-Object Name, Mode
} else {
    $outputParent = [System.IO.Path]::GetDirectoryName($outputRoot)
    if (!(Test-Path -LiteralPath $outputParent -PathType Container)) {
        throw "Output parent must already exist: $outputParent"
    }
    Get-ChildItem -LiteralPath $outputParent -Force | Select-Object Name, Mode
}
if (Test-Path -LiteralPath $archivePath) {
    throw "Refusing to overwrite an existing archive: $archivePath"
}
Write-Output "Preflight: release sources verified; output parent checked; archive name free."
Write-Output "Scope: create only $archivePath and its output directory if needed."
Write-Output 'Rollback: retain or rename the new output; source files remain unchanged.'
if (!(Test-Path -LiteralPath $outputRoot)) {
    Write-Output "Creating directory: $outputRoot"
    [System.IO.Directory]::CreateDirectory($outputRoot) | Out-Null
}
Write-Output "Creating archive from the fixed 11-file whitelist: $archivePath"
$archiveStream = [System.IO.File]::Open($archivePath, [System.IO.FileMode]::CreateNew,
    [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
try {
    $archive = [System.IO.Compression.ZipArchive]::new($archiveStream,
        [System.IO.Compression.ZipArchiveMode]::Create, $true)
    try {
        foreach ($entry in $entries) {
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,
                (Join-Path $repositoryRoot $entry), $entry,
                [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
    } finally {
        $archive.Dispose()
    }
} finally {
    $archiveStream.Dispose()
}
Get-Item -LiteralPath $archivePath | Select-Object FullName, Length
Get-FileHash -LiteralPath $archivePath -Algorithm SHA256
