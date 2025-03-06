# Define the cutoff date
$CutoffDate = Get-Date "2024-01-01"

# Get all IAM roles
$Roles = aws iam list-roles --query "Roles[*].{RoleName:RoleName}" --output json | ConvertFrom-Json

# Array to store roles with last activity before the cutoff date
$InactiveRoles = @()

Write-Host "Checking IAM roles for last activity before $CutoffDate..."

foreach ($Role in $Roles) {
    $RoleName = $Role.RoleName

    # Get the role's details including last used date
    $RoleDetails = aws iam get-role --role-name AWSCodePipelineServiceRole-us-east-1-fortress.api-core-prd --query "Role.RoleLastUsed" --output json | ConvertFrom-Json

    # Check if the role has a LastUsedDate
    if ($RoleDetails.LastUsedDate) {
        # Parse the LastUsedDate
        try {
            $LastUsedDate = [datetime]::Parse($RoleDetails.LastUsedDate)
        } catch {
            Write-Host "Failed to parse LastUsedDate for role: $RoleName"
            continue
        }

        # Compare dates
        if ($LastUsedDate -lt $CutoffDate) {
            $InactiveRoles += [PSCustomObject]@{
                RoleName     = $RoleName
                LastUsedDate = $LastUsedDate
            }
        }
    }
}

# Output the results
if ($InactiveRoles.Count -gt 0) {
    Write-Host "Roles with last activity before $CutoffDate :"
    $InactiveRoles | Format-Table -AutoSize
} else {
    Write-Host "No roles found with last activity before $CutoffDate."
}
