README.md
# AUTOMATISATION DE COPIE DE DOSSIERS

## Description

Ce script automatise un processus de copie de dossier depuis une source ver sune destination en effectuant un rangement des dossiers en fonction d'une convention de nommage.

## Table des Matières

- [Variables de configuration](#Variables_de_configuration)
- [Installation](#Installation)
- [Lancement du script](#Lancement_du_script)
- [Configuration](#Configuration)
- [Fonctionnement](#Fonctionnement)
- [Test](#Test)


## Variables_de_configuration

  Fichier config.json                   |                 réponse attendue                              |   Typage      |   Réponse user                                   
  -------------------------------------------------------------------------------------------------------------------------------------------------------------
  "isInit":  true                       |   => le fichier de configuration est configuré                |  => boolean   |   Aucune
  "SourcePath":  "PATH_FLODER_SOURCE"   |   => le chemin du dossier source                              |  => string    |   Choix du dossier
  "DestinationPath":  "PATH_FOLDER_DEST"|   => le chemin du dossier destination                         |  => string    |   Choix du dossier
  "isShutDown":  true                   |   => est-ce que l'on eteint le pc après l'execution du script |  => boolean   |   Oui => Y || Non => N
  "delayShutDown":  60                  |   => durée en secondes pour eteindre le pc                    |  => number    |   nombre en seconde

## Installation

Dans le répertoire de votre choix, déposer les fichiers :

- backup-files.ps1
- config.json
- README.md

## Lancement_du_script

Ouvrir un terminal depuis ce dossier avec un clic droit et lancer le script

```powerShell
# Commande pour lancer le script
./backup-files.ps1
```

## Configuration

Au premier lancement, la configuration se lance :

- Boite de dialogue pour selectionner le dossier Source
- Boite de dialogue pour selectionner le dossier Destination
- Est-ce que vous souhaitez redémarrer le PC ? "Y" ou "N"
- Determiner le délai entre la fin du script et le redémarrage : 60 secondes par défaut

Vous pouvez à tout moment relancer la configuration avec cette commande :

```powerShell
# Commande pour lancer le script
./backup-files.ps1 -init
```

## Fonctionnement

Dossier Source

- Placer les dossiers à sauvegarder à la racine de ce dossier
- Convention de nommage :
  - VP_4450
  - VI_4500
  - R4_10
  - R5_16
- _OLD => contient toues les dossiers qui ont été sauvegardés (Aux utilisateurs de supprimer les dossiers archivés)
- _logs => contient le fichier txt des logs

Dossier Destination :

- Voie Impaire
- Voie Paire
- Rameau
      - R1
      - R2
      - R3
      - R4
      ...

## Test

Le lancement en ligne de commande est utile pour réaliser la configuration et un test pour valider le résultat attendu

## Automatisation 

## Automatisation Quotidienne

Pour automatiser l'exécution quotidienne du script `backup-files.ps1`, utilisez le Planificateur de tâches de Windows en suivant les étapes ci-dessous :

1. **Ouvrir le Planificateur de tâches**.
2. **Créer une nouvelle tâche** :
   - Nom : `Backup Files Script`
   - Description : `Automatisation de la sauvegarde des fichiers`
   - Exécuter avec les autorisations maximales.

3. **Configurer le déclencheur** :
   - Type : Quotidien
   - Heure : [Spécifiez l'heure désirée]

4. **Configurer l'action** :
   - Programme/script : `powershell`
   - Ajouter des arguments : `-File "C:\chemin\vers\votre\script\backup-files.ps1"`

5. **Configurer les conditions et les paramètres** selon vos besoins.

### Tester la tâche

Pour tester la tâche manuellement, sélectionnez votre tâche dans le Planificateur de tâches et cliquez sur "Exécuter".

### Vérifier les logs

Assurez-vous que le script s'exécute correctement en vérifiant les logs créés dans le dossier `_logs`.

