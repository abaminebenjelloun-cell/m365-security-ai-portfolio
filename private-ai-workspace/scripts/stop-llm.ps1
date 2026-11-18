<#
.SYNOPSIS
    Frees the GPU: unloads every model loaded in Ollama.

.DESCRIPTION
    Use before gaming or GPU-heavy work (lesson 1: a running game cut generation speed by about 88%,
    and the reverse is also true). Models reload automatically on the next request.
#>
[CmdletBinding()]
param()

if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    throw 'ollama CLI not found in PATH.'
}

# `ollama ps` prints a header line, then one line per loaded model; the first column is the model name
$loaded = ollama ps | Select-Object -Skip 1 | ForEach-Object { ($_ -split '\s+')[0] } | Where-Object { $_ }

if (-not $loaded) {
    Write-Host 'No model loaded. GPU already free.'
    return
}

foreach ($model in $loaded) {
    ollama stop $model
    Write-Host "Unloaded $model"
}

ollama ps
