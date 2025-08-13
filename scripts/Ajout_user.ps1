<#
Nom : Ajout_user.ps1
Description :
Ce script PowerShell permet d'automatiser l'ajout de plusieurs utilisateurs dans un environnement Active Directory.
Il utilise un fichier CSV contenant les informations des utilisateurs (prénom, nom, fonction, etc.) 
et permet également l'ajout dans une OU et dans des groupes existants.

#>

#################### Chargement des modules et préparation ####################

# Vérifie si le module ActiveDirectory est disponible
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Error "Le module ActiveDirectory n’est pas installé. Exécutez : Add-WindowsFeature RSAT-AD-PowerShell"
    exit
}
Import-Module ActiveDirectory

# Définir le chemin du log
$logPath = "C:\Logs"
if (-not (Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath | Out-Null
}
$logFile = "$logPath\import_users_log.txt"

# Chargement des composants pour les boîtes de dialogue
Add-Type -AssemblyName System.Windows.Forms

###############################################################################



#################### Définition des fonctions ####################

function Import-UsersFromCSV {
    # Ouvre un explorateur pour choisir le fichier CSV
    $csvFilePath = [System.Windows.Forms.OpenFileDialog]::new() | ForEach-Object {
        $_.Filter = "Fichiers CSV (*.csv)|*.csv"
        $_.ShowDialog() | Out-Null
        $_.FileName
    }

    if (-not (Test-Path $csvFilePath)) {
        Write-Warning "Fichier CSV introuvable."
        return
    }

    $users = Import-Csv -Path $csvFilePath
    Write-Host "Nombre d'utilisateurs détectés : $($users.Count)" -ForegroundColor Green

    foreach ($user in $users) {
        $prenom   = $user.firstname
        $nom      = $user.lastname
        $fonction = $user.function
        $login    = ($prenom.Substring(0,1) + $nom).ToLower()
        $email    = "$login@tssr.corp"

        # Définir le mot de passe
        $password = if ($user.password) {
            ConvertTo-SecureString $user.password -AsPlainText -Force
        } else {
            ConvertTo-SecureString "Azerty1234!" -AsPlainText -Force
        }

        # Vérifie l'existence
        if (Get-ADUser -Filter {SamAccountName -eq $login}) {
            Write-Warning "L'utilisateur $login existe déjà."
            continue
        }

        # Choix de l'OU
        $ou = (Get-ADOrganizationalUnit -Filter *).DistinguishedName | Out-GridView -Title "Choisissez une OU pour $prenom $nom" -PassThru

        # Création de l'utilisateur
        New-ADUser -Name "$nom $prenom" `
                   -DisplayName "$nom $prenom" `
                   -GivenName $prenom `
                   -Surname $nom `
                   -SamAccountName $login `
                   -UserPrincipalName "$login@$((Get-ADDomain).DNSRoot)" `
                   -EmailAddress $email `
                   -Title $fonction `
                   -AccountPassword $password `
                   -ChangePasswordAtLogon $true `
                   -Enabled $true `
                   -Path $ou

        Write-Host "Utilisateur $login créé." -ForegroundColor Green
        Add-Content -Path $logFile -Value "$(Get-Date -Format u) - Utilisateur $login créé."

        # Ajout aux groupes
        $groupes = (Get-ADGroup -Filter * -SearchBase "OU=Groupes,DC=tssr,DC=corp").Name | Out-GridView -Title "Groupes pour $login" -PassThru
        foreach ($groupe in $groupes) {
            Add-ADGroupMember -Identity $groupe -Members $login
            Add-Content -Path $logFile -Value "$(Get-Date -Format u) - $login ajouté au groupe $groupe"
            Write-Host "Ajouté à $groupe" -ForegroundColor Cyan
        }
    }
}

###############################################################################



#################### Exécution ####################

# Menu simple
do {
    Write-Host "`nMenu Principal" -ForegroundColor Cyan
    Write-Host "1. Importer des utilisateurs via CSV"
    Write-Host "2. Quitter"
    $choix = Read-Host "Choix (1-2)"

    switch ($choix) {
        '1' {
            Import-UsersFromCSV
        }
        '2' {
            Write-Host "Fermeture du script." -ForegroundColor Yellow
        }
        default {
            Write-Warning "Option invalide."
        }
    }
} until ($choix -eq '2')

###################################################

