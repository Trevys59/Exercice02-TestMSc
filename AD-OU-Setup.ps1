Import-Module ActiveDirectory

$ouBase = "DC=laplateforme,DC=io"
$ous = @(
    "OU=Users,$ouBase",
    "OU=Groups,$ouBase",
    "OU=ServiceAccounts,$ouBase"
)

foreach ($ou in $ous) {
    $parts = $ou -split ",", 2
    $name  = $parts[0] -replace '^OU=', ''
    $path  = $parts[1]

    $exists = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ou'" -ErrorAction SilentlyContinue

    if (-not $exists) {
        New-ADOrganizationalUnit -Name $name -Path $path -ProtectedFromAccidentalDeletion $true | Out-Null
        Write-Host "[+] OU créée : $name"
    } else {
        Write-Host "[-] OU déjà présente : $name"
    }
}