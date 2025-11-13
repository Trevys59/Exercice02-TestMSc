# Exercice02-TestMSc
Déployement d'un domaine Active Directory via Powershell et automatisation de la création d'utilisateurs et de groupes à partir d’un fichier CSV, et appliquer une politique de mot de passe standardisée avec obligation de changement à la première connexion.

## Environnement
- 1x Windows Server 2022 (contrôleur de domaine DC1.laplateforme.io)
- Domaine : laplateforme.io
- DNS intégré à ADDS
- Script PowerShell automatisé : Add-Users.ps1
- Fichier CSV source : utilisateurs.csv

## Étapes
1. Promotion du serveur en contrôleur de domaine (laplateforme.io)
2. Création des OU : Users, Groups, ServiceAccounts
3. Import du CSV via Add-Users.ps1
	a. Génération automatique des logins (prenom.nom)
	b. Mot de passe initial : Azerty_2025!
	c. Obligation de changement à la première connexion
4. Création des groupes manquants (global security)
5. Ajout automatique des utilisateurs à leurs groupes
6. Vérifications : console ADUC → utilisateurs, groupes, appartenance, UPN
