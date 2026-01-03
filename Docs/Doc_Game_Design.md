# 🎮 GAME DESIGN - COCOONSTRIKE

## 🎯 CONCEPT CORE
**Cocoonstrike - Rebuild** est un survival shooter FPS où le joueur incarne
un soldat dans une armure assistée futuriste, condamné à survivre face à
des vagues d'ennemis dans un environnement urbain en ruine.

**Objectif :** Survivre le plus longtemps possible  
**Fin :** Mort inévitable  
**Map :** Environnement urbain avec 4 zones d'entrée

## 🎮 MÉCANIQUES PRINCIPALES

### Boucle de Survie
1. **Vague d'ennemis** → Combat et survie
2. **Récupération de ressources** → Ramassage du "bric-à-brac"
3. **Préparation** → Activation de pièges entre vagues
4. **Vague suivante** → Difficulté croissante

### Boucle de Combat
1. **Détection ennemis** → Rotation vers le joueur
2. **Tir** → Dégâts et effets d'impact
3. **Mouvement** → Évitement et repositionnement
4. **Slam** → Attaque spéciale avec zone de repulsion
5. **Rechargement** → Gestion des munitions dans l'arme

## 🛠️ SYSTÈMES

### Ressources : "Bric-à-brac"
- **Récupération** : Sprites qui tournent et disparaissent quand ramassés
- **Utilisation** : Matériaux pour construire différents types de pièges
  ou soigner le joueur

### Types de Pièges
- **Barricades** : Bloquer une ou plusieurs entrées pour un tour
- **Pièges à loup** : Dégâts aux ennemis
- **Trappes** : Faire tomber des ennemis dans des trous
- **Haches/bûches** : Activation au-dessus d'entrées ou passages

### Map et Activation des pièges
- **4 zones** avec une entrée d'ennemis par zone
- **Activation** : Interaction directe sur la map (pas de menus)
- **Durée** : 1 activation = 1 tour

### Système de Couverture
- **Conditions** : Joueur à 1.5m d'un muret + muret entre joueur et ennemi
- **Hauteur** : Muret arrive à la moitié du torse (joueur voit son arme
  au-dessus)
- **Effets** : 50% de dégâts en moins + 75% de chance de toucher pour
  l'ennemi
- **Application** : Tous les obstacles de cette hauteur partagent cette
  propriété
- **Feedback visuel** : À définir

## 🌊 SYSTÈME DE VAGUES

### Activation
- **Déclenchement** : Le joueur active un interrupteur pour lancer une vague
- **Une vague à la fois** : Impossible de lancer une nouvelle vague si une vague est déjà en cours
- **Fin de vague** : Tous les ennemis éliminés (succès) ou timer écoulé (échec)

### Système de Spawn
- **Spawn par paquets** : Les ennemis apparaissent progressivement par groupes
- **4 zones de spawn** : Les ennemis peuvent apparaître dans n'importe laquelle des 4 zones
- **Respawn intelligent** : Quand il reste 15% d'ennemis, de nouveaux paquets peuvent être spawnés si la limite simultanée le permet
- **Limite simultanée** : Nombre maximum d'ennemis présents en même temps sur la map

### Cycle de 5 Vagues (Progression Intra-Cycle)
Chaque cycle de 5 vagues suit une progression de difficulté :

- **Vague 1** : Base
  - Nombre d'ennemis : n
  - Ennemis simultanés : n
  
- **Vague 2** : Plus d'ennemis
  - Nombre d'ennemis : n+2
  - Ennemis simultanés : n+2
  
- **Vague 3** : Augmentation simultanée
  - Nombre d'ennemis : n+2
  - Ennemis simultanés : n+4 (plus de pression)
  
- **Vague 4** : Variété maximale
  - Nombre d'ennemis : n+4
  - Ennemis simultanés : n+4
  - Tous les types d'ennemis présents
  
- **Vague 5** : Vague spéciale
  - Nombre d'ennemis : n+2
  - Ennemis simultanés : n+2
  - Stats boostées : +25% PV et +25% dégâts
  - Timer restreint : 80% du temps normal

### Progression Inter-Cycles
Après chaque cycle de 5 vagues terminé, la difficulté de base augmente :

- **Nombre de base d'ennemis (n)** : Augmente de +1 par cycle
- **Timer de base** : Diminue de 1 seconde par cycle (minimum 5 secondes)

### Exemple de Progression
- **Cycle 1** (Vagues 1-5) : n=5 ennemis de base, timer=30s
- **Cycle 2** (Vagues 6-10) : n=6 ennemis de base, timer=29s
- **Cycle 3** (Vagues 11-15) : n=7 ennemis de base, timer=28s
- Et ainsi de suite...
