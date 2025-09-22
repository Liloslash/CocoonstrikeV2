# DOCUMENTATION GAME DESIGN - COCOONSTRIKE

## CONCEPT DU JEU

**Cocoonstrike - Rebuild** est un survival shooter FPS où le joueur incarne un soldat dans une armure assistée futuriste, condamné à survivre face à des vagues d'ennemis dans un environnement urbain en ruine.

**Objectif :** Survivre le plus longtemps possible  
**Fin :** Mort inévitable  
**Map :** Environnement urbain avec 4 zones d'entrée

## BOUCLES DE GAMEPLAY

### Boucle Principale
1. **Vague d'ennemis** → Combat et survie
2. **Récupération de ressources** → Ramassage du "bric-à-brac"
3. **Préparation** → Activation de pièges entre vagues
4. **Vague suivante** → Difficulté croissante
5. **Mort** → Game Over

### Boucle de Combat
1. **Détection ennemis** → Rotation vers le joueur
2. **Tir** → Dégâts et effets d'impact
3. **Mouvement** → Évitement et repositionnement
4. **Slam** → Attaque spéciale avec propulseurs
5. **Rechargement** → Gestion des munitions

### Boucle de Ressources
1. **Mort d'ennemi** → Drop de "bric-à-brac"
2. **Ramassage** → Sprites qui tournent et disparaissent
3. **Choix stratégique** → Quel piège activer
4. **Activation** → Interaction directe sur la map
5. **Effet** → Piège actif pour 1 tour

## DIRECTION ARTISTIQUE

### Armure Futuriste
- **Style** : Armure assistée futuriste (inspiration Fallout mais design original)
- **HUD diégétique** : Contour de visière de casque affichant vie et munitions
- **Justification gameplay** : L'armure explique les capacités spéciales (slam, power shot)

### Environnement
- **Style** : Environnement urbain en ruine et barricadé
- **Amélioration** : Remplacer les "blocs types" actuels par une ambiance urbaine

### Armes
- **Révolver futuriste** : Design qui inspire la puissance et la confiance
- **Power shot** : Mécanique de tir spécial justifiée par l'armure

## SYSTÈME DE PIÈGES

### Ressources : "Bric-à-brac"
- **Récupération** : Sprites qui tournent et disparaissent quand ramassés
- **Utilisation** : Matériaux pour construire différents types de pièges

### Types de Pièges
- **Barricades** : Bloquer une ou plusieurs entrées pour un tour
- **Pièges à loup** : Dégâts aux ennemis
- **Trappes** : Faire tomber des ennemis dans des trous
- **Haches/bûches** : Activation au-dessus d'entrées ou passages

### Map et Activation
- **4 zones** avec une entrée d'ennemis par zone
- **Activation** : Interaction directe sur la map (pas de menus)
- **Durée** : 1 activation = 1 tour
