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

## 🎨 DIRECTION ARTISTIQUE

### Armure Futuriste
- **Style** : Armure assistée futuriste 
- **HUD diégétique** : Contour de visière de casque affichant vie et munitions
et état des capacités
- **Justification gameplay** : L'armure explique les capacités spéciales (slam, power shot)

### Environnement
- **Style** : Environnement urbain en ruine et barricadé
- **Amélioration** : Remplacer les "blocs types" actuels par une ambiance urbaine

### Armes
- **Révolver futuriste** : Design qui inspire la puissance et la confiance
- **Power shot** : Mécanique de tir spécial justifiée par l'armure

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

## 🎵 AUDIO & FEEDBACK
- **Sons de pas** : Joueur et ennemis
- **Sons de dégâts** : Impact et mort des ennemis
- **Audio ambiant** : Ambiance urbaine post-apocalyptique
- **Effets visuels** : Particules d'impact, tremblements, animations
