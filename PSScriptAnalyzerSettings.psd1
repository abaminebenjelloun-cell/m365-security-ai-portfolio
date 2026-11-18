@{
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # Write-Host is used on purpose for coloured operator feedback in interactive runbooks
        'PSAvoidUsingWriteHost'
    )
}
