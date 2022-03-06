extends Reference
class_name SaveReadmeGenerator


static func get_save_readme():
	return """
# MANUEL DU DOSSIER DE SAUVEGARDE DE LAEC EST TOI

## ARBORESCENCE DES FICHIERS

### logs/ 
contient les journaux du jeu
### levels/
contient les niveaux édité avec l'éditeur en jeu
### settings.json
contient les options du jeu qui peuvent être modifié depuis le jeu. Le plus simple des fichiers de sauvegarde.
### settings.godot
est copie de projet.godot sans les parties critiques, permet aux utilisateurs les plus techniciens de finement régler le jeu.
### SettingsMigrationData.json
doit être considéré en lecture seule pour l'utilisateur, contient une liste d'information à propos de la migration des options du jeu
### README.md
ce fichier =)


# LAEC IS YOU SAVE FOLDER MANUAL

## TREE

### logs/ 
Logs of the game
### levels/
Folder containing levels edited with the in-game editor
### settings.json
The most user friendly setting file, reflect in-game settings
### settings.godot
A copy of project.godot without the most critical part, to be used by tech people to tweak the game
### SettingsMigrationData.json
to be considered read-only contains information about save edition by dev for most technical users
### README.md
this file =)
"""
