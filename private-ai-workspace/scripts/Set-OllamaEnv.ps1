<#
.SYNOPSIS
    Sets the Ollama environment variables used by this workspace, for the current Windows user.

.DESCRIPTION
    Values documented in docs/ollama-tuning.md. After running, quit Ollama from the taskbar
    and start it again, then check with `ollama ps` that models load at 100% GPU.
    Supports -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess)]
param()

$settings = [ordered]@{
    OLLAMA_HOST            = '127.0.0.1:11434'   # never exposed on the network
    OLLAMA_CONTEXT_LENGTH  = '32768'             # default is 4096
    OLLAMA_FLASH_ATTENTION = '1'                 # required for KV cache quantization
    OLLAMA_KV_CACHE_TYPE   = 'q8_0'              # about half the KV cache memory of f16
    OLLAMA_KEEP_ALIVE      = '30m'               # default is 5 minutes
    OLLAMA_NO_CLOUD        = '1'                 # local-only mode
}

foreach ($name in $settings.Keys) {
    $current = [Environment]::GetEnvironmentVariable($name, 'User')
    if ($current -eq $settings[$name]) {
        Write-Host "$name already set to $current"
        continue
    }
    if ($PSCmdlet.ShouldProcess($name, "Set to $($settings[$name]) (was '$current')")) {
        [Environment]::SetEnvironmentVariable($name, $settings[$name], 'User')
        Write-Host "$name = $($settings[$name])"
    }
}

Write-Host "`nRestart Ollama, then run: ollama ps"
