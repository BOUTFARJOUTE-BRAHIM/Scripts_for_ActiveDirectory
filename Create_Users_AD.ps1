# Liste exhaustive des options dsadd user 
$options = @(
    @{ Num = 1; Name = "-samid"; Prompt = "Nom de connexion (sAMAccountName)" },
    @{ Num = 2; Name = "-upn"; Prompt = "UPN (ex: user@domaine.local)" },
    @{ Num = 3; Name = "-fn"; Prompt = "Prénom" },
    @{ Num = 4; Name = "-mi"; Prompt = "Initiale du deuxième prénom" },
    @{ Num = 5; Name = "-ln"; Prompt = "Nom de famille" },
    @{ Num = 6; Name = "-display"; Prompt = "Nom affiché complet" },
    @{ Num = 7; Name = "-empid"; Prompt = "ID Employé" },
    @{ Num = 8; Name = "-pwd"; Prompt = "Mot de passe" },
    @{ Num = 9; Name = "-desc"; Prompt = "Description" },
    @{ Num = 10; Name = "-office"; Prompt = "Bureau" },
    @{ Num = 11; Name = "-tel"; Prompt = "Téléphone bureau" },
    @{ Num = 12; Name = "-hometel"; Prompt = "Téléphone personnel (Home phone)" },
    @{ Num = 13; Name = "-pager"; Prompt = "Pager" },
    @{ Num = 14; Name = "-mobile"; Prompt = "Téléphone mobile" },
    @{ Num = 15; Name = "-fax"; Prompt = "Fax" },
    @{ Num = 16; Name = "-iptel"; Prompt = "Téléphone IP (IP phone)" },
    @{ Num = 17; Name = "-email"; Prompt = "Email" },
    @{ Num = 18; Name = "-webpg"; Prompt = "Page Web" },
    @{ Num = 19; Name = "-title"; Prompt = "Fonction (Title)" },
    @{ Num = 20; Name = "-dept"; Prompt = "Département" },
    @{ Num = 21; Name = "-company"; Prompt = "Société" },
    @{ Num = 23; Name = "-hmdir"; Prompt = "Répertoire personnel (HomeDirectory)" },
    @{ Num = 24; Name = "-hmdrv"; Prompt = "Lecteur réseau (HomeDrive, ex: H:)" },
    @{ Num = 25; Name = "-profile"; Prompt = "Chemin du profil utilisateur" },
    @{ Num = 26; Name = "-loscr"; Prompt = "Script de connexion (Logon script)" },
    @{ Num = 27; Name = "-mustchpwd"; Prompt = "Changer mot de passe à la première connexion ? (yes/no)" },
    @{ Num = 28; Name = "-canchpwd"; Prompt = "L'utilisateur peut changer le mot de passe ? (yes/no)" },
    @{ Num = 29; Name = "-pwdneverexpires"; Prompt = "Le mot de passe n'expire jamais ? (yes/no)" },
    @{ Num = 30; Name = "-disabled"; Prompt = "Compte désactivé ? (yes/no)" },
    @{ Num = 31; Name = "-memberof"; Prompt = "Groupes d'appartenance (DN, séparés par ;)" }
)

# Demande du DN en premier
Write-Host "`n=== CRÉATION D'UN UTILISATEUR AD AVEC DSADD ET AJOUT AUX GROUPES ===" -ForegroundColor Cyan
$dn = Read-Host "`nEntrez le DN (Distinguished Name) de l'utilisateur (ex: CN=Ali Karim,OU=Users,DC=formation,DC=local)"

# Affichage des options disponibles
Write-Host "`n=== OPTIONS DISPONIBLES POUR DSADD USER ===" -ForegroundColor Cyan
foreach ($opt in $options) {
    Write-Host "$($opt.Num). $($opt.Prompt) ($($opt.Name))"
}

# Choix des options à utiliser
$selection = Read-Host "`nEntrez les numéros des options que vous souhaitez utiliser (ex: 1,3,8,27,32)"
$selectedOptions = $selection -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }

# Collecte des valeurs des options sélectionnées
$params = ""
$groupsRaw = ""
foreach ($num in $selectedOptions) {
    $opt = $options | Where-Object { $_.Num -eq [int]$num }
    if ($opt) {
        if ($opt.Num -eq 8) {
            $securePwd = Read-Host "$($opt.Prompt)" -AsSecureString
            $plainPwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePwd)
            )
            $params += " $($opt.Name) `"$plainPwd`""
        }
        elseif ($opt.Num -eq 32) {
            $groupsRaw = Read-Host "$($opt.Prompt)"
        }
        else {
            $val = Read-Host "$($opt.Prompt) [laisser vide pour ignorer]"
            if (![string]::IsNullOrWhiteSpace($val)) {
                $params += " $($opt.Name) `"$val`""
            }
        }
    }
}

# Construction et exécution de la commande dsadd user
$cmd = "dsadd user `"$dn`"$params"
Write-Host "`n=== COMMANDE DSADD USER ===" -ForegroundColor Green
Write-Host $cmd -ForegroundColor Yellow
Invoke-Expression $cmd

# Post-traitement : ajout aux groupes
if ($groupsRaw) {
    $groups = $groupsRaw -split ';'
    foreach ($grp in $groups) {
        $grpTrim = $grp.Trim()
        Write-Host "Ajout de $dn au groupe $grpTrim…" -ForegroundColor Cyan
        dsmod group `"$grpTrim`" -addmbr `"$dn`"
    }
}

Write-Host "`nOpération terminée." -ForegroundColor Green
