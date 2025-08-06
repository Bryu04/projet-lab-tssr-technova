# Projet Lab TSSR – Infrastructure réseau virtualisée sécurisée pour PME

## 🚧 Avancement du projet

| Étape                             | Statut        | Commentaires                                               |
|----------------------------------|---------------|------------------------------------------------------------|
| Planification & définition       | ✅ Terminé     | Cahier des charges et plan d’architecture faits            |
| Création infrastructure VMware   | ✅ Terminé     | Utilisation de NAT & LAN Segment, VM créées manuellement   |
| Installation pfSense             | ✅ Terminé     | Interfaces WAN/LAN/DMZ configurées, accès web fonctionnel  |
| Déploiement Serveur AD/DNS/DHCP  | ✅ Terminé     | Services installés, domaine "homelab.infra" opérationnel   |
| Mise en place serveur fichiers   | ⬜ À faire     | VM non encore installée                                    |
| Configuration clients Windows 10 | ⬜ À faire     | Deux clients prévus (admin & direction)                    |
| Création DMZ & Serveur Web       | ⬜ À faire     | VM à installer et configurer avant retour sur pfSense      |
| Configuration des règles firewall| ⏳ À venir     | Prévue après installation complète des serveurs            |
| Tests et validations             | ⏳ À venir     | Vérification de la communication et filtrage               |
| Rédaction rapport final          | 🟠 En cours    | Version 3 prête, avec installation & configuration d’AD/pfSense |

---

## 📘 Contexte du Projet – Lab TSSR
### 🎯 Titre du projet :
Déploiement d’une infrastructure réseau virtualisée sécurisée pour une PME fictive – Projet Lab VMware

### 🏢 Présentation de l’entreprise :
TechNova Solutions est une PME spécialisée dans les services numériques. Elle souhaite moderniser son infrastructure réseau en mettant en place une solution virtualisée pour :

- Centraliser la gestion des utilisateurs,
- Partager les ressources (fichiers, imprimantes),
- Sécuriser les accès réseau,
- Héberger un site web consultable de l’extérieur via une DMZ.

### 🧩 Objectifs du projet :

1. Concevoir et déployer une infrastructure réseau complète et segmentée en VLANs simulés via des réseaux VMware.
2. Mettre en œuvre un contrôleur de domaine (Active Directory) pour centraliser la gestion des postes clients et utilisateurs.
3. Mettre en place un serveur de fichiers pour le partage des données en réseau local.
4. Installer un pare-feu (pfSense) pour gérer la sécurité, le routage et l’accès Internet.
5. Créer une DMZ pour héberger un serveur web et tester son accessibilité depuis une machine externe.
6. Assurer la séparation logique des réseaux : LAN / DMZ / WAN et sécuriser les flux avec des règles firewall.

---

## 💻 Infrastructure virtualisée (VMware Workstation) – Vue d’ensemble

| Rôle                  | OS                    | IP               | Réseau       |
|-----------------------|-----------------------|------------------|--------------|
| pfSense (firewall)    | pfSense               | WAN: 192.168.10.1 | WAN (VMnet1) |
|                       |                       | LAN: 192.168.100.1| LAN (VMnet2) |
|                       |                       | DMZ: 192.168.200.1| DMZ (VMnet3) |
| Serveur AD/DNS/DHCP   | Windows Server 2022   | 192.168.100.10   | LAN          |
| Serveur de fichiers   | Windows Server 2022   | 192.168.100.11   | LAN          |
| Client Admin          | Windows 10 Pro        | DHCP (ex: .100)  | LAN          |
| Client Direction      | Windows 10 Pro        | DHCP (ex: .101)  | LAN          |
| Serveur Web           | Debian 12 / Ubuntu    | 192.168.200.10   | DMZ          |
| Machine Externe (test)| Windows / Linux       | 192.168.10.50    | WAN          |

---

## 🔒 Fonctionnalités de sécurité implémentées

- Accès Internet uniquement depuis le LAN (via pfSense NAT)
- Interdiction de tout accès direct de la DMZ vers le LAN
- Redirection du port HTTP (80) depuis le WAN vers le serveur web en DMZ
- Journalisation du trafic et test des règles firewall dans pfSense

---

## 🧪 Tests prévus

- Ping entre les machines (selon les règles)
- Accès au domaine depuis les clients
- Application de GPO
- Test du serveur de fichiers
- Accès au site web en DMZ depuis la machine externe
- Vérification des logs pfSense

---

## 📝 Livrables

- Schéma réseau (physique + logique)
- Plan d’adressage IP
- Capture des configurations AD, DNS, DHCP, pfSense, GPO
- Résultats des tests réseau et sécurité
- Rapport de projet synthétique (version PDF évolutive disponible dans `/docs`)

---

## 📁 1. Serveur de fichiers : structure simple et logique

Un dossier par groupe, avec des droits spécifiques via les groupes de sécurité AD.

### Arborescence des dossiers (exemple sur D:\Partages)

D:\
└── Partages\
    ├── Admin\
    ├── Comptabilité\
    └── Direction\


### Groupes de sécurité correspondants (dans AD)

- G_Admin
- G_Comptabilité
- G_Direction

On ajoute les utilisateurs dans les groupes, et on donne les droits NTFS uniquement à ces groupes (et pas aux utilisateurs individuellement !)

### Droits NTFS recommandés

| Dossier      | Groupe autorisé   | Droits NTFS      |
|--------------|-------------------|------------------|
| Admin        | G_Admin           | Contrôle total   |
| Comptabilité | G_Comptabilité    | Lecture/écriture |
| Direction    | G_Direction       | Lecture seule    |

On peut aussi masquer les dossiers non autorisés avec l’option “Masquer les dossiers auxquels les utilisateurs n’ont pas accès” (dans les paramètres de partage).

---

## 🧠 2. GPO à tester : des trucs utiles et visibles

### A. Changer le fond d’écran

- Appliquer un fond d’écran par défaut (selon l’OU par exemple)
- GPO : Configuration utilisateur > Paramètres Windows > Paramètre du Bureau > Fond d’écran

### B. Mappage automatique d’un lecteur réseau

- Connecter un lecteur réseau (ex : P:\ sur \\serveur\partages\comptabilité)
- GPO : Configuration utilisateur > Préférences > Paramètres Windows > Lecteurs

### C. Politique de mot de passe renforcée

- Longueur mini : 8 caractères, complexité activée
- GPO : Configuration ordinateur > Paramètres Windows > Paramètres de sécurité > Stratégies de compte > Mot de passe

### D. Désactiver le panneau de configuration ou le gestionnaire de tâches

- GPO : Configuration utilisateur > Stratégies > Modèles d’administration > Panneau de configuration

### E. Script de connexion (optionnel)

- Message de bienvenue ou script .bat qui affiche quelque chose
- GPO : Configuration utilisateur > Paramètres Windows > Scripts

### Tests GPO à faire (et capturer)

- Le fond d’écran change-t-il après redémarrage / login ?
- Le lecteur réseau est-il mappé automatiquement ?
- Les restrictions sont-elles bien appliquées au bon utilisateur / bon groupe ?
- Les règles ne s’appliquent pas aux autres groupes (test de filtrage)

---

## 📂 Organisation du dépôt

- `/docs` : schémas et captures d’écran
- `/rapport` : rapports PDF
- `/configurations` : scripts, fichiers de configuration (pfSense, GPO, etc.)
- `/vmware` : fichiers de configuration VM si possible
- `/scripts` : scripts bash, PowerShell, batch utilisés dans le projet

---

## 📄 Rapport évolutif

Le rapport de projet sera disponible en PDF dans `/rapport`, avec une version mise à jour régulièrement selon l’avancement.  
N’hésitez pas à consulter le README pour le suivi des étapes.

---

*Dernière mise à jour : 6 août 2025*

