# SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param(
    [string]$PartsDirectory,
    [string]$OutputDirectory
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$pending = $null
$ownsPending = $false

function Get-SafeChild([string]$Root, [string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name) -or $Name -ne [IO.Path]::GetFileName($Name)) {
        throw 'A manifest filename is not a plain filename.'
    }
    $candidate = [IO.Path]::GetFullPath([IO.Path]::Combine($Root, $Name))
    if (-not [string]::Equals([IO.Path]::GetDirectoryName($candidate), $Root, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'A target escaped the selected directory.'
    }
    return $candidate
}

function Assert-RegularFile([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "Expected an ordinary file: $Path"
    }
    return $item
}

function Get-Sha256([string]$Path) {
    $algorithm = [Security.Cryptography.SHA256]::Create()
    $file = $null
    try {
        $file = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
        return [BitConverter]::ToString($algorithm.ComputeHash($file)).Replace('-', '').ToLowerInvariant()
    }
    finally {
        if ($null -ne $file) { $file.Dispose() }
        $algorithm.Dispose()
    }
}

try {
    # Windows PowerShell 5.1 may evaluate parameter defaults before PSScriptRoot.
    if ([string]::IsNullOrWhiteSpace($PartsDirectory)) { $PartsDirectory = $PSScriptRoot }
    if ([string]::IsNullOrWhiteSpace($OutputDirectory)) { $OutputDirectory = $PSScriptRoot }
    $partsItem = Get-Item -LiteralPath $PartsDirectory
    $outputItem = Get-Item -LiteralPath $OutputDirectory
    if (-not $partsItem.PSIsContainer -or -not $outputItem.PSIsContainer) {
        throw 'Select existing folders for the parts and output.'
    }
    $partsRoot = [IO.Path]::GetFullPath($partsItem.FullName).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $outputRoot = [IO.Path]::GetFullPath($outputItem.FullName).TrimEnd([IO.Path]::DirectorySeparatorChar)
    # Keep drive roots absolute after removing trailing separators.
    if ($partsRoot -match '^[A-Za-z]:$') { $partsRoot += '\' }
    if ($outputRoot -match '^[A-Za-z]:$') { $outputRoot += '\' }
    $manifestPath = Get-SafeChild $partsRoot 'PARTS.json'
    $null = Assert-RegularFile $manifestPath
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $expectedArchiveName = 'CLOUD-JA21-1.5.0-complete.zip'
    if ($manifest.format -ne 'cloud-ja21-parts/1' -or $manifest.partSizeLimitBytes -ne 24000000 -or
        $manifest.archive.name -cne $expectedArchiveName -or
        $manifest.archive.bytes -le 0 -or $manifest.archive.bytes -gt 2000000000 -or
        $manifest.archive.sha256 -cnotmatch '^[a-f0-9]{64}$') {
        throw 'The parts manifest is invalid or belongs to another distribution.'
    }
    $count = [int][Math]::Ceiling($manifest.archive.bytes / 24000000.0)
    if (@($manifest.parts).Count -ne $count) { throw 'The part count does not match the archive size.' }
    $destination = Get-SafeChild $outputRoot $expectedArchiveName
    [long]$total = 0
    $paths = @()
    for ($i = 0; $i -lt $count; $i++) {
        $part = $manifest.parts[$i]
        $expectedName = $expectedArchiveName + ('.part{0:D3}' -f ($i + 1))
        $expectedBytes = [Math]::Min(24000000L, [long]$manifest.archive.bytes - $total)
        if ($part.index -ne ($i + 1) -or $part.name -cne $expectedName -or
            $part.bytes -ne $expectedBytes -or $part.sha256 -cnotmatch '^[a-f0-9]{64}$') {
            throw "The manifest entry for part $($i + 1) is invalid."
        }
        $partPath = Get-SafeChild $partsRoot $part.name
        if (-not (Test-Path -LiteralPath $partPath)) { throw "Missing part: $($part.name)" }
        $item = Assert-RegularFile $partPath
        if ($item.Length -ne $part.bytes) { throw "Incorrect size: $($part.name)" }
        Write-Host "Checking part $($i + 1) of $count..."
        if ((Get-Sha256 $partPath) -cne $part.sha256) {
            throw "Checksum failed: $($part.name). Download or copy this part again."
        }
        $paths += $partPath
        $total += $part.bytes
    }
    if ($total -ne $manifest.archive.bytes) { throw 'The total part size is incorrect.' }
    if (Test-Path -LiteralPath $destination) {
        $existing = Assert-RegularFile $destination
        if ($existing.Length -eq $total -and
            (Get-Sha256 $destination) -ceq $manifest.archive.sha256) {
            Write-Host "Already joined and verified: $destination"
            exit 0
        }
        throw "An existing ZIP has different contents. Move it aside before joining: $destination"
    }
    $pending = Get-SafeChild $outputRoot ($expectedArchiveName + '.' + [Guid]::NewGuid().ToString('N') + '.pending')
    $stream = [IO.File]::Open($pending, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    $ownsPending = $true
    try {
        foreach ($partPath in $paths) {
            $inputStream = [IO.File]::Open($partPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
            try { $inputStream.CopyTo($stream, 1048576) }
            finally { $inputStream.Dispose() }
        }
        $stream.Flush()
    }
    finally { $stream.Dispose() }
    $pendingItem = Assert-RegularFile $pending
    if ($pendingItem.Length -ne $total -or
        (Get-Sha256 $pending) -cne $manifest.archive.sha256) {
        throw 'The joined ZIP failed its final checksum. The parts may have changed while joining.'
    }
    # File.Move does not overwrite an existing destination. Both absolute paths
    # were checked as direct children of the chosen output folder above.
    [IO.File]::Move($pending, $destination)
    $ownsPending = $false
    Write-Host "Joined and verified: $destination"
    Write-Host 'Right-click the ZIP, choose Extract All, then open START CLOUD.cmd in the extracted application folder.'
    exit 0
}
catch {
    Write-Host ('Could not join the parts: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
finally {
    if ($ownsPending -and $pending -and (Test-Path -LiteralPath $pending)) {
        # Only this invocation's newly created, checked temporary file is removed.
        Remove-Item -LiteralPath $pending -Force
    }
}
