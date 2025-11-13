Import-Module ActiveDirectory

$DomainDN = "DC=laplateforme,DC=io"
$OUUsers  = "CN=Users,$DomainDN"
$OUGroups = "OU=Groups,$DomainDN"
$CsvPath = "C:\Users\Administrateur\Documents\utilisateurs.csv"
$Mdp = "Azerty_2025!"
$SMdp = ConvertTo-SecureString $Mdp -AsPlainText -Force
$rows = Import-Csv -Path $CsvPath -Delimiter ','

###Création des groupes
$groupList = @()
foreach ($r in $rows) {
    foreach ($i in 1..6) {
        $g = $r."groupe$i"
        if ($g -and $g.Trim()) {
            if ($groupList -notcontains $g.Trim()) { $groupList += $g.Trim() }
        }
    }
}

foreach ($g in $groupList) {
    $exists = Get-ADGroup -LDAPFilter "(cn=$g)" -SearchBase $OUGroups -ErrorAction SilentlyContinue
    if (-not $exists) {
        New-ADGroup -Name $g -GroupScope Global -GroupCategory Security -Path $OUGroups | Out-Null
        Write-Host "[+] Groupe créé : $g"
    } else {
        Write-Host "[-] Groupe déjà présent : $g"
    }
}

###Création des utilisateurs
foreach ($r in $rows) {
    $nom    = ($r.nom    | ForEach-Object { $_.ToString().Trim() })
    $prenom = ($r."prénom" | ForEach-Object { $_.ToString().Trim() })

    if (-not $nom -or -not $prenom) {
        Write-Warning "Ligne ignorée (nom/prénom manquant)."
        continue
    }
    $loginBase = ("{0}.{1}" -f $prenom.ToLower(), $nom.ToLower())
    $login     = $loginBase -replace "\s","" -replace "[^a-z0-9\.-]",""
    if (-not $login) { $login = ($prenom.Substring(0,1) + $nom).ToLower() }

    # Respect (approx.) de la limite sAMAccountName (20) => simple troncature
    $sam = if ($login.Length -gt 20) { $login.Substring(0,20) } else { $login }
    $upn = "$login@laplateforme.io"
    $cn  = "$prenom $nom"

    # Collision simple : si le sAM existe, on ajoute 2 chiffres
    $samFinal = $sam
    if (Get-ADUser -LDAPFilter "(sAMAccountName=$samFinal)" -ErrorAction SilentlyContinue) {
        $rand = Get-Random -Minimum 10 -Maximum 99
        $samFinal = if ($sam.Length -ge 18) { $sam.Substring(0,18) + $rand } else { $sam + $rand }
        $upn = "$samFinal@laplateforme.io"
    }

    # Création
    $existing = Get-ADUser -LDAPFilter "(userPrincipalName=$upn)" -ErrorAction SilentlyContinue
    if (-not $existing) {
        New-ADUser `
            -Name $cn `
            -GivenName $prenom `
            -Surname $nom `
            -DisplayName $cn `
            -UserPrincipalName $upn `
            -SamAccountName $samFinal `
            -Path $OUUsers `
            -AccountPassword $SMdp `
            -Enabled $true `
            -ChangePasswordAtLogon $true `
            -PasswordNeverExpires $false
        Write-Host "[+] Utilisateur créé : $cn ($samFinal)"
    } else {
        Write-Host "[-] Utilisateur déjà présent : $cn"
        Set-ADAccountPassword -Identity $existing -NewPassword $SMdp -Reset
        Set-ADUser -Identity $existing -ChangePasswordAtLogon $true -PasswordNeverExpires $false
        Enable-ADAccount -Identity $existing
    }

    # Ajout aux groupes
    foreach ($i in 1..6) {
        $g = $r."groupe$i"
        if ($g -and $g.Trim()) {
            try {
                Add-ADGroupMember -Identity $g.Trim() -Members $samFinal -ErrorAction Stop
                Write-Host "    -> $cn ajouté au groupe : $($g.Trim())"
            } catch {
                Write-Warning "    ! Impossible d'ajouter $cn au groupe '$g' : $($_.Exception.Message)"
            }
        }
    }
}

Write-Host "`nTerminé. Mot de passe initial : $Mdp (changement imposé à la première connexion)."
