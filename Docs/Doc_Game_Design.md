# 🎮 GAME DESIGN - COCOONSTRIKE

## 🎯 CONCEPT CORE
**Cocoonstrike - Rebuild** est un survival shooter FPS où le joueur incarne 
un soldat dans une armure assistée futuriste, condamné à survivre face à des
vagues d'ennemis dans un environnement urbain en ruine.

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

## 👾 ENNEMIS

### Architecture des Ennemis
- **3 types de base** : Papillons (léger), Monster (moyen), BigMonster (lourd)
- **Recolorisations** : Chaque type a 2 variantes avec comportements différents
- **Total final** : 6 ennemis uniques (3 types × 2 variantes)

### PAPILLONS (Type Léger)

#### Chaser (Papillon V1)
- **Comportement** : Pathfinding direct vers le joueur + attaque corps à corps
- **Attaque** : Jet de spores (animation) dans un rayon de 1.5m
- **Dégâts** : 15 points par attaque
- **Cooldown** : 3 secondes entre attaques
- **Style** : Agressif, pression directe

#### Peintre (Papillon V2 - Recolorisé)
- **Comportement** : Déplacement libre sur la carte + contrôle de zone
- **Attaque** : Lance des spores à intervalles de 8 secondes
- **Effet spécial** : Zones de dégâts persistantes (5 DPS)
- **Taille des zones** : Rayon de 1.5m
- **Limitation** : Maximum 3 zones simultanées par ennemi
- **Style** : Tactique, pression indirecte

### MONSTER (Type Moyen)
- **2 variantes** : À définir (comportements différents)

### BIG MONSTER (Type Lourd)
- **2 variantes** : À définir (comportements différents)

## 🛠️ SYSTÈMES

### Ressources : "Bric-à-brac"
- **Récupération** : Sprites qui tournent et disparaissent quand ramassés
- **Utilisation** : Matériaux pour construire différents types de pièges

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
- **Hauteur** : Muret arrive à la moitié du torse (joueur voit son arme au-dessus)
- **Effets** : 50% de dégâts en moins + 75% de chance de toucher pour l'ennemi
- **Application** : Tous les obstacles de cette hauteur partagent cette propriété
- **Feedback visuel** : À définir

## 🌊 SYSTÈME DE VAGUES

> **Note** : Ce système est une ébauche. Le système final sera plus complexe et plus riche. Cette version initiale pourra être complétée et complexifiée au fur et à mesure.

### Variables de Contrôle
Le système de vagues utilise 5 variables principales pour ajuster la difficulté :

1. **Nombre total d'ennemis** : Quantité d'ennemis à éliminer pour terminer la vague
2. **Nombre d'ennemis simultanés** : Limite d'ennemis présents en même temps sur la map (limite de spawn)
3. **Variété des ennemis** : Types d'ennemis présents dans la vague (Papillons, Monsters, BigMonsters)
4. **Timer** : Temps alloué pour éliminer tous les ennemis de la vague
5. **Surcharge de stats** : Multiplicateur de statistiques pour créer des vagues spéciales (ex: +25% PV, +25% dégâts)

### Cycle de 5 Vagues (Progression Intra-Cycle)
Chaque cycle de 5 vagues suit une progression de difficulté :

- **Vague 1** : Base
  - Nombre d'ennemis : n
  
- **Vague 2** : Plus d'ennemis
  - Nombre d'ennemis : n+
  
- **Vague 3** : Augmentation simultanée
  - Nombre d'ennemis : n+
  - Nombre d'ennemis simultanés : Augmenté
  
- **Vague 4** : Variété maximale
  - Nombre d'ennemis : n++
  - Nombre d'ennemis simultanés : Augmenté
  - Variété : Tous les types d'ennemis présents
  
- **Vague 5** : Vague spéciale
  - Nombre d'ennemis : n+
  - Stats surchargées : Ennemis avec statistiques augmentées (ex: +25% PV)
  - Timer : Restreint (moins de temps pour éliminer la vague)

### Progression Inter-Cycles
Après chaque cycle de 5 vagues terminé, la difficulté de base augmente :

- **Nombre de base d'ennemis (n)** : Augmente de +1
- **Timer de base** : Diminue (ex: -1 seconde par cycle)

### Exemple de Progression
- **Cycle 1** (Vagues 1-5) : n=5 ennemis de base, timer=30s
- **Cycle 2** (Vagues 6-10) : n=6 ennemis de base, timer=29s
- **Cycle 3** (Vagues 11-15) : n=7 ennemis de base, timer=28s
- Et ainsi de suite...
