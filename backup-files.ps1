# script d'automatisation de sauvegarde de dossier entre un dossier source et destination

# Declare les parametres du script 
param (
    [switch]$init
)

# Initialisation de $config a $null
$config = $null

# Initialisation de $folderArray
$folderArray = @()

# Fonction pour ouvrir une boîte de dialogue de selection de dossier
function Select-FolderDialog {
    param (
        [string]$Description = "Selectionnez un dossier"
    )
    
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.ShowNewFolderButton = $true

    $result = $dialog.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    } else {
        return $null
    }
}

# Fonction pour lire la configuration depuis un fichier JSON
function Get-Configuration {
    param ($configFilePath)
    if (Test-Path -Path $configFilePath) {
        return Get-Content -Path $configFilePath -Raw -Encoding UTF8 | ConvertFrom-Json
    } else {
        throw "Le fichier de configuration n'existe pas."
    }
}

# Fonction pour ecrire la configuration dans un fichier JSON
function Set-Configuration {
    param ($configFilePath, $sourcePath, $destinationPath, $isShutDown, $delayShutDown)
    $config = @{
        isInit = $true
        SourcePath = $sourcePath
        DestinationPath = $destinationPath
        isShutDown = $isShutDown
        delayShutDown = $delayShutDown
    }
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configFilePath -Encoding UTF8
}

# Chemin du fichier de configuration
$configFilePath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"

# Fonction pour lancer le mode de configuration
function Start-Configuration {
    $sourcePath = Select-FolderDialog -Description "Selectionnez le dossier source"
    if (-not $sourcePath) {
        Write-Output "Aucun dossier source selectionne. Le script se termine."
        exit
    }

    $destinationPath = Select-FolderDialog -Description "Selectionnez le dossier de destination"
    if (-not $destinationPath) {
        Write-Output "Aucun dossier de destination selectionne. Le script se termine."
        exit
    }

    $isShutDown = Read-Host "Voulez-vous eteindre le PC apres la sauvegarde ? (Y/N)"
    $delayShutDown = Read-Host "Delai avant l'arret en secondes (par defaut 60)" -DefaultValue 60

    if (-not $isShutDown) {
      $isShutDown = "N"
    }
    $isShutDown = if ($isShutDown -eq "Y") { $true } else { $false }

    if (-not $delayShutDown) {
        $delayShutDown = 60
    }

    Set-Configuration -configFilePath $configFilePath -sourcePath $sourcePath -destinationPath $destinationPath -isShutDown $isShutDown -delayShutDown $delayShutDown
    Write-Output "Configuration enregistree avec succes."
    exit
}

# Verification de la configuration
$configMissing = $false

try {
    $config = Get-Configuration -configFilePath $configFilePath
    if (-not $config.isInit -or -not $config.SourcePath -or -not $config.DestinationPath) {
        $configMissing = $true
    }
} catch {
    Write-Output "Erreur lors de la lecture de la configuration : $_"
    $configMissing = $true
    exit
}

# Si $init est defini, lancer le mode de configuration
if ($init -or $configMissing -or $null -eq $config) {
    Start-Configuration
}

# Lire la configuration
$config = Get-Configuration -configFilePath $configFilePath
$sourcePath = $config.SourcePath
$destinationPath = $config.DestinationPath
$isShutDown = $config.isShutDown
$delayShutDown = $config.delayShutDown

$parentSourcePath = Split-Path -Parent $sourcePath
$logFolderPath = Join-Path -Path $sourcePath -ChildPath "_logs"

if (-Not (Test-Path -Path $logFolderPath)) {
    New-Item -ItemType Directory -Path $logFolderPath
}

# Log de sauvegarde
$logPath = Join-Path -Path $logFolderPath -ChildPath "backup_log.txt"
Add-Content -Path $logPath -Value "--------------- Debut de la tache a $(Get-Date) ---------------" -Encoding UTF8

# Obtenir les dossiers a la racine du dossier source, en excluant et _logs
$folders = Get-ChildItem -Path $sourcePath -Directory | Where-Object { $_.Name -notin "_logs" }

# Verifier s'il y a des dossiers a copier
if ($folders.Count -eq 0) {
    Add-Content -Path $logPath -Value "$(Get-Date) - Aucun dossier a copier pour ce jour." -Encoding UTF8
    Write-Output "Aucun dossier a copier. Le script se termine."
    exit
}

# Fonction pour determiner le chemin de destination base sur le nom du dossier
function Get-DestinationPath {
    param ($folderName, $destinationBase)
    $parts = $folderName -split '_'
    $prefix = $parts[0]
    switch -regex ($prefix) {
        "VP" { return Join-Path -Path $destinationBase -ChildPath "Voie Paire" }
        "VI" { return Join-Path -Path $destinationBase -ChildPath "Voie Impaire" }
        "R(\d+)" { return Join-Path -Path $destinationBase -ChildPath "Rameau\Rameau $($matches[1])" }
        default { 
            $message = "$(Get-Date) - Le dossier suivant $folderName ne respecte la convention de nommage - Dossier ignore."
            Add-Content -Path $logPath -Value $message -Encoding UTF8
            return $null
        }
    }
}

# Copier les dossiers sources vers le dossier de destination approprie
foreach ($folder in $folders) {
    $source = $folder.FullName
    $destSubPath = Get-DestinationPath -folderName $folder.Name -destinationBase $destinationPath
    # Si le dossier a une erreur de convention de nommage, on l'ignore
    if($null -eq $destSubPath) {
        continue
    }
    $destination = Join-Path -Path $destSubPath -ChildPath $folder.Name

    # Creez le dossier de destination s'il n'existe pas
    if (-Not (Test-Path -Path $destSubPath)) {
        New-Item -ItemType Directory -Path $destSubPath -Force
    }

    Write-Output "Copie de $($folder.Name) vers $destSubPath..."
    Copy-Item -Path $source -Destination $destSubPath -Recurse -Force
}

# Deplacer les dossiers dans le dossier parent du dossier source
foreach ($folder in $folders) {
    $source = $folder.FullName
    $destSubPath = Get-DestinationPath -folderName $folder.Name -destinationBase $parentSourcePath
    # Si le dossier a une erreur de convention de nommage, on l'ignore
    if($null -eq $destSubPath) {
        continue
    }
    $destination = Join-Path -Path $destSubPath -ChildPath $folder.Name

    # Creez le dossier de destination s'il n'existe pas
    if (-Not (Test-Path -Path $destSubPath)) {
        New-Item -ItemType Directory -Path $destSubPath -Force
    }

    Write-Output "Copie de $($folder.Name) vers $destSubPath..."
    Copy-Item -Path $source -Destination $destSubPath -Recurse -Force

    if (Test-Path -Path $destination) {
        Remove-Item -Path $source -Recurse -Force
        Write-Output "Suppression de $($source)"
    }

    $folderArray += $folder.Name
}

Write-Output $folderArray.length

# Ajouter au log de sauvegarde
if($folderArray.length -gt 0) {
    Add-Content -Path $logPath -Value "$(Get-Date) - Sauvegarde et deplacement des dossiers $($folderArray) termines." -Encoding UTF8
    Write-Output "Sauvegarde et deplacement termines."
} else {
    Add-Content -Path $logPath -Value "$(Get-Date) - Aucun dossier n'a ete traites." -Encoding UTF8
    Write-Output "Aucun dossiers."
}
Add-Content -Path $logPath -Value "--------------- Fin de la tache a $(Get-Date) ---------------" -Encoding UTF8
Add-Content -Path $logPath -Value "" -Encoding UTF8


# eteindre le PC apres la sauvegarde si configure
if ($isShutDown -eq "Yes") {
    shutdown /s /t $delayShutDown /c "Le PC s'eteindra dans $delayShutDown secondes apres la sauvegarde et le deplacement."
}
