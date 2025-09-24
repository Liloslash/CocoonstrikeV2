# 📋 DOC_PROJET

---

## 📑 NAVIGATION RAPIDE

**=== INFORMATIONS GÉNÉRALES ===**
- Ligne 42 : Informations du projet
- Ligne 52 : Concept du jeu

**=== ARCHITECTURE ===**
- Ligne 66 : Structure des scènes
- Ligne 79 : Scene Player (Architecture Modulaire)
- Ligne 96 : Architecture Modulaire du Joueur
- Ligne 194 : Scene Enemy
- Ligne 205 : Navigation et Pathfinding

**=== SYSTÈMES ===**
- Ligne 216 : Système Joueur
- Ligne 238 : Système de Saut Avancé
- Ligne 277 : Système Revolver
- Ligne 311 : Système Ennemis (Pathfinding)
- Ligne 353 : Effets d'Impact

**=== RESSOURCES ===**
- Ligne 370 : Assets Audio
- Ligne 389 : Assets Visuels
- Ligne 407 : Configuration

**=== ÉTAT DU PROJET ===**
- Ligne 429 : Fonctionnel
- Ligne 444 : En cours
- Ligne 448 : À implémenter
- Ligne 453 : Récent
- Ligne 470 : Roadmap

**=== RÉFÉRENCES ===**
- Ligne 494 : Référence Rapide

---

## 📋 INFORMATIONS GÉNÉRALES

**Nom :** Cocoonstrike - Rebuild  
**Moteur :** Godot Engine v4.4.1  
**Type :** FPS Survival Shooter 3D  
**Style :** Pixel Art et 3D / Retro  
**Plateforme :** PC (Windows, Linux)

---

## 🎯 CONCEPT DU JEU

**Cocoonstrike - Rebuild** = Survival shooter FPS basé sur un prototype Godot Wild Jam

**Map :** 3D unique avec 2 zones (Arena + Obstacles)

**Gameplay :**
- Joueur au centre de la map
- Déclencheur pour lancer les vagues d'ennemis
- **Objectif :** survivre le plus longtemps possible
- Entre vagues : collecte, pièges, blocage d'accès

---

## 🏗️ ARCHITECTURE TECHNIQUE

### Structure des Scènes

```
World (Node principal)
├── Arena (Node3D) - Zone d'arène
├── Obstacles (Node3D) - Zone d'obstacles  
├── WorldEnvironment3D - Éclairage et ciel
├── Player (CharacterBody3D) - Joueur principal
└── Enemy (CharacterBody3D) - Ennemi (instancié manuellement)
```

### Scene Player (Architecture Modulaire)

```
Player (CharacterBody3D) - ORCHESTRATEUR
├── PlayerCamera (Camera3D) - Gestion caméra (hérite de Camera3D)
├── PlayerMovement (Node) - Mouvement et saut
├── PlayerCombat (Node) - Tir et raycast
├── PlayerInput (Node) - Gestion des inputs
├── Camera3D (référence pour compatibilité)
│   └── RayCast3D (collision_mask = 2)
├── CollisionShape3D (CapsuleShape3D)
├── AudioStreamPlayer3D (bruits de pas)
└── HUD_Layer (CanvasLayer)
	└── Revolver (AnimatedSprite2D)
		└── AnimationPlayer (Sway_Idle)
```

### Architecture Modulaire du Joueur

**Principe :** Séparation des responsabilités en composants spécialisés

#### PlayerCamera.gd (119 lignes)
- **Type :** `extends Camera3D` (hérite directement de Camera3D)
- **Responsabilités :** Shake, head bob, recul de tir
- **Paramètres :** Intensité, durée, fréquence des effets
- **Fonctions clés :** `start_camera_shake()`, `trigger_recoil()`
- **Avantage :** Accès direct aux propriétés de la caméra (position, rotation)

#### PlayerMovement.gd (231 lignes)
- **Responsabilités :** Mouvement, saut boost, slam
- **Paramètres :** Vitesse, accélération, gravité, hauteur de saut
- **Fonctions clés :** `start_jump()`, `start_slam()`, `get_current_speed()`

#### PlayerCombat.gd (121 lignes)
- **Responsabilités :** Tir, raycast, dégâts, effets d'impact
- **Paramètres :** Dégâts du revolver
- **Fonctions clés :** `trigger_shot()`, `trigger_reload()`, `trigger_recoil()`
- **Communication :** Connexion directe avec PlayerCamera pour le recul

#### PlayerInput.gd (56 lignes)
- **Responsabilités :** Gestion des inputs (souris, clavier)
- **Paramètres :** Sensibilité de la souris
- **Fonctions clés :** Délégation des actions aux composants

#### player.gd (70 lignes) - ORCHESTRATEUR
- **Responsabilités :** Coordination des composants et gestion des signaux
- **Fonctions clés :** `_ready()`, `_process()`, `_physics_process()`, `_on_slam_landed()`
- **Signaux :** Connexion `slam_landed` → camera shake, `shot_fired` → recul

### Diagramme d'Architecture Modulaire

```
┌─────────────────────────────────────────────────────────────┐
│                    PLAYER (CharacterBody3D)                │
│                        ORCHESTRATEUR                       │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────┐ │
│  │PlayerCamera │  │PlayerMovement│ │PlayerCombat │  │Input│ │
│  │(Camera3D)   │  │    (Node)   │  │    (Node)   │  │(Node│ │
│  │             │  │             │  │             │  │     │ │
│  │ • Shake     │  │ • Mouvement │  │ • Tir       │  │ •   │ │
│  │ • Head Bob  │  │ • Saut      │  │ • Raycast   │  │     │ │
│  │ • Recul     │  │ • Slam      │  │ • Dégâts    │  │     │ │
│  │ • 119 lignes│  │ • 231 lignes│  │ • 121 lignes│  │ 56  │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────┘ │
├─────────────────────────────────────────────────────────────┤
│                    COMPOSANTS PHYSIQUES                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Camera3D   │  │CollisionShape│  │AudioStream3D│         │
│  │  └─RayCast3D│  │  (Capsule)  │  │             │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                        HUD LAYER                           │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              Revolver (AnimatedSprite2D)               │ │
│  │              └─ AnimationPlayer (Sway_Idle)            │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

AVANT : player.gd (424 lignes) - TOUT MÉLANGÉ
APRÈS : 4 composants + orchestrateur (70 lignes) - SÉPARÉ

### Communication entre Composants

#### Signaux Utilisés
- **`slam_landed`** : PlayerMovement → player.gd → PlayerCamera (camera shake)
- **`shot_fired`** : Revolver → PlayerCombat → PlayerCamera (recul)

#### Références Directes
- **PlayerCombat** → **PlayerCamera** : Communication directe pour le recul
- **player.gd** → **Tous les composants** : Orchestration et délégation
```

### Avantages de l'Architecture Modulaire

#### ✅ **Maintenabilité**
- **Code plus lisible** : Chaque composant a une responsabilité claire
- **Modifications isolées** : Changer un système sans affecter les autres
- **Debugging facilité** : Problèmes localisés dans le bon composant

#### ✅ **Évolutivité**
- **Ajout de fonctionnalités** : Nouveaux composants facilement intégrables
- **Réutilisabilité** : Composants réutilisables dans d'autres projets
- **Tests unitaires** : Chaque composant testable indépendamment

#### ✅ **Performance**
- **Chargement optimisé** : Seuls les composants nécessaires sont actifs
- **Mémoire** : Gestion plus efficace des ressources
- **Debug** : Isolation des problèmes de performance

#### ✅ **Collaboration**
- **Travail en équipe** : Chaque développeur peut travailler sur un composant
- **Code review** : Changements plus faciles à examiner
- **Documentation** : Chaque composant auto-documenté

### Scene Enemy

```
Enemy (CharacterBody3D)
├── AnimatedSprite3D (billboard désactivé - rotation manuelle)
├── CollisionShape3D (collisions environnement)
├── NavigationAgent3D (pathfinding)
└── Area3D (détection/dégâts)
	└── CollisionShape3D
```

### Navigation et Pathfinding

```
World (Node principal)
├── Navigation (NavigationRegion3D) - Zone navigable
├── Arena (Node3D) - Sol navigable
└── Obstacles (Node3D) - Obstacles à éviter
```

---

## ⚙️ SYSTÈME DE JOUEUR

### Mouvement FPS
- **Contrôles :** WASD + Souris
- **Slam :** Q (slam_velocity = -33.0)
- **Accélération :** 0.4s
- **Freeze après slam :** 0.3s

### Effets Visuels
- **Camera Shake :** Tremblement EaseOutElastic
- **Head Bob :** Mouvement de tête marche
- **Recoil :** Recul lors du tir
- **Kickback :** Recul caméra arrière

### Combat
- **RayCast3D :** collision_mask = 2
- **Dégâts :** 25 points par tir
- **Signal :** shot_fired du revolver
- **Impact :** Particules colorées

---

## ⚙️ SYSTÈME DE SAUT SIMPLIFIÉ

### Mécanique de Saut
- **Déclenchement :** Espace (quand au sol)
- **Force du saut :** 8.0 (vitesse verticale directe)
- **Gravité de chute :** 1.1x (chute légèrement plus rapide)
- **Feeling :** Saut simple et réactif, contrôle immédiat

### Slam Aérien
- **Déclenchement :** Q (en l'air)
- **Vitesse :** -33.0 (plonge rapide)
- **Temps minimum :** 0.4s après le saut
- **Gel après impact :** 0.3s

### Effet de Caméra "Jump Look Down"
- **Déclenchement :** Automatique au saut
- **Angle d'inclinaison :** 30° vers le bas (configurable)
- **Démarrage :** À partir de la moitié du saut
- **Progression :** Inclinaison progressive jusqu'au sommet
- **Maintien :** Angle conservé pendant la chute
- **Retour :** Transition douce vers la position normale à l'atterrissage

### Variables Exportées (Éditeur)
**PlayerMovement :**
- `jump_velocity` : Force du saut (8.0)
- `fall_gravity_multiplier` : Multiplicateur de gravité pour la chute (1.1)

**PlayerCamera :**
- `jump_look_angle` : Angle d'inclinaison vers le bas (30°)
- `jump_look_smoothness` : Vitesse de transition (2.0)

### Fonctions Clés
- `start_jump()` : Applique la vélocité de saut et démarre l'effet caméra
- `_handle_gravity_and_jump()` : Gère la gravité et la communication avec la caméra
- `start_jump_look_down()` : Initialise l'effet de regard vers le bas
- `_handle_jump_look_down()` : Calcule et applique l'inclinaison progressive

---

## ⚙️ SYSTÈME DE REVOLVER

### Munitions
- **Capacité :** 6 balles max
- **Rechargement :** Animation fluide + sons
- **Cadence :** 0.3s entre tirs
- **États :** IDLE, RELOAD_STARTING, RELOAD_ADDING_BULLETS, RELOAD_INTERRUPTED

### Audio
- **Sons :** Tir, rechargement, clic vide
- **Superposition :** Plusieurs sons simultanés
- **Fichiers :** GunShot-2.mp3, OpenRevolverBarrel.mp3, AddRevolverBullet.mp3, CloseRevolverBarrel.mp3, AOARevolver.mp3

### Animations
- **Tween :** Mouvements fluides
- **AnimationPlayer :** Sway_Idle (balancement)
- **SpriteFrames :** 11 frames de tir

### Effets de Tremblement
- **Fonction :** `_create_weapon_shake()` (renommée de `_create_reload_shake()`)
- **Utilisation :** Rechargement ET clic vide (plus de munitions)
- **Intensité :** 3.0 pixels
- **Durée :** 0.15s par balle
- **Fréquence :** 20 oscillations/s
- **Direction :** Aléatoire
- **Position de référence :** `base_position` (clic vide) ou `reload_position` (rechargement)

### Amélioration du Feeling
- **Clic vide :** Tremblement de l'arme + son (pas de recul de caméra)
- **Feedback visuel :** Simulation du mouvement du poignet
- **Cohérence :** Même effet que lors du rechargement

---

## ⚙️ SYSTÈME D'ENNEMIS

### Statistiques
- **Vie :** 500 points (configurable)
- **Collision Layer :** 3 (détectable par raycast)
- **Vitesse :** 3.0 (mouvement vers joueur)
- **Portée :** 15.0 (non utilisée)

### Comportement
- **États :** Vivant/mort, gelé/actif
- **Mort :** Freeze 1s puis disparition
- **Collisions :** Désactivées à la mort
- **Rotation :** Regarde toujours vers le joueur (axe X/Z uniquement)

### Pathfinding et Navigation
- **NavigationAgent3D :** Calcul de chemin vers joueur
- **Raycast d'évitement :** Détection d'obstacles à 2.0 unités
- **Contournement :** Tourne à droite quand obstacle détecté
- **Recherche joueur :** Automatique au démarrage
- **Fonctions :** _setup_navigation(), _update_navigation(), _start_navigation()

### Système de Rotation
- **Billboard :** Désactivé pour contrôle manuel
- **Rotation automatique :** Vers le joueur en temps réel
- **Axe de rotation :** X/Z uniquement (pas de rotation verticale)
- **Fonction :** _update_sprite_rotation() dans _physics_process()
- **Méthode :** look_at() avec direction normalisée (Y = 0)

### Couleurs d'Impact
- **4 couleurs exportables** dans l'inspecteur
- **Défaut :** Rouge clair, Vert, Violet, Noir
- **Méthode :** get_impact_colors()

### Effet de Rougissement
- **Feedback :** Rouge quand dégâts
- **Durée :** 0.2s
- **Intensité :** 1.5
- **Transition :** EASE_OUT
- **Déclenchement :** À l'impact

---

## ⚙️ EFFETS D'IMPACT

### ImpactEffect
- **GPUParticles3D :** Cubes 3D
- **4 couleurs simultanées** par impact
- **Durée :** 0.4s
- **Particules :** 32 cubes répartis sur 4 systèmes
- **Taille :** 0.056 (réduite d'un quart)
- **Force :** 3.0-6.0 (localisée)

### Configuration
- **Physique :** Pas de gravité
- **Explosion :** Toutes directions
- **Couleurs :** Depuis l'ennemi touché

---

## 🎨 ASSETS AUDIO

### Guns
- 8 sons de revolver (tir, rechargement, clic vide)

### Enemies
- Sons de pas lourds, rugissements, battements d'ailes

### Player
- Bruits de pas, battements de cœur, cris

### UI
- Sons de bonus, compte à rebours, succès

### Musique
- Metalcore.mp3

---

## 🎨 ASSETS VISUELS

### Sprites Ennemis
- BigMonsterV1/V2, PapillonV1/V2 (128x128)

### Armes
- Revolver.png, TurboGun.png

### UI
- Heart.png (icône de vie)

### Environnements
- Arena.glb + textures floor/wall
- Obstacles.glb + textures floor/wall
- ProceduralSkyMaterial (couleurs sombres)

---

## 🔧 CONFIGURATION TECHNIQUE

### Input Map
- **ESC :** Libérer la souris
- **WASD :** Mouvement
- **Espace :** Saut
- **Q :** Slam
- **Clic gauche :** Tir
- **R :** Rechargement

### Collision Layers
- **Layer 0 :** Environnement
- **Layer 1 :** Joueur
- **Layer 2 :** Ennemis (détectable par raycast)

### Rendering
- **Mode :** GL Compatibility
- **Filtrage :** Nearest (pixel art)
- **Ciel :** ProceduralSkyMaterial

---

## 📊 ÉTAT ACTUEL

### ✅ FONCTIONNEL
- **Architecture modulaire** : Player refactorisé en 4 composants spécialisés + orchestrateur
- **Player complet** : Mouvement, tir, effets (orchestré par composants)
- **Communication robuste** : Signaux et références directes entre composants
- **Système de saut avancé** : Boost, flottement, slam avec camera shake (PlayerMovement.gd)
- **Revolver complet** : Animations, sons, munitions, recul de caméra, tremblement clic vide
- **Enemy complet** : Vie, dégâts, mort, pathfinding
- **Système de collisions** : Configuré et optimisé
- **Effets d'impact** : Pixel explosion avec couleurs dynamiques
- **Pathfinding ennemis** : Raycast d'évitement d'obstacles
- **Feeling de tir amélioré** : Tremblement de l'arme lors du clic vide pour feedback visuel
- **Code optimisé** : Variables inutilisées supprimées, fonctions renommées, structure consolidée

### 🔄 EN COURS
- Amélioration du système d'évitement d'obstacles
- Système de vagues

### ❌ À IMPLÉMENTER
- Collectibles et pièges
- Audio ambiant
- Polissage final

### 🆕 RÉCENT (Décembre 2024)
- **Refactorisation majeure** : Architecture modulaire du joueur
- **Réduction de complexité** : player.gd passé de 424 à 70 lignes
- **Séparation des responsabilités** : 4 composants spécialisés + orchestrateur
- **Amélioration de la maintenabilité** : Code plus propre et évolutif
- **Corrections d'architecture** : PlayerCamera hérite de Camera3D, communication robuste
- **Résolution des bugs** : Double son de tir, communication recul, références @onready
- **Système de saut simplifié** : Suppression du système complexe de jump boost
- **Effet de caméra "Jump Look Down"** : Inclinaison de 30° pendant le saut pour immersion
- **Optimisations de performance** : Cache des références, gestion d'erreurs robuste
- **Documentation mise à jour** : Système de saut et effet de caméra documentés
- **Amélioration du feeling de tir** : Tremblement de l'arme lors du clic vide (plus de munitions)
- **Optimisations de code** : Suppression de variables inutilisées, consolidation des vérifications
- **Refactoring de fonctions** : `_create_reload_shake()` → `_create_weapon_shake()` (nom plus générique)

---

## 🚀 ROADMAP

### 🔥 PRIORITÉS CRITIQUES
1. **✅ MÉCANIQUE DE SAUT TERMINÉE** - Système simplifié avec effet de caméra !
   - ✅ Système de saut simple et réactif (8.0 de force)
   - ✅ Effet de caméra "Jump Look Down" (30° d'inclinaison)
   - ✅ Transition douce et immersive

2. **🚨 PATHFINDING VRAI** - NavigationMesh non fonctionnelle !
   - NavigationMesh reste vide (pas de grille bleue visible)
   - NavigationAgent3D inutile (next_path_position = même position)
   - Système actuel = simple évitement basique (raycast + tourner à droite)
   - **OBJECTIF :** Implémenter du vrai pathfinding avec NavigationMesh fonctionnelle

### PRIORITÉS ACTUELLES
3. **Sons supplémentaires** (pas player, impact slam, dégât/mort enemy)
4. **Comportement enemy** : shaking dégât, mort plus recherchée

### ✅ AMÉLIORATIONS RÉCENTES TERMINÉES
- **Feeling de tir** : Tremblement de l'arme lors du clic vide (feedback visuel cohérent)
- **Optimisations de code** : Nettoyage et consolidation du code du revolver

---

## 🎯 RÉFÉRENCE RAPIDE

### Architecture Modulaire (Player)

#### PlayerCamera.gd
- **Type :** `extends Camera3D` (hérite de Camera3D)
- **shake_intensity :** 0.8 (intensité du shake)
- **shake_duration :** 0.8s (durée du shake)
- **headbob_amplitude :** 0.06 (amplitude du head bob)
- **recoil_intensity :** 0.03 (intensité du recul)
- **Fonctions :** `start_camera_shake()`, `trigger_recoil()`

#### PlayerMovement.gd
- **max_speed :** 9.5 (vitesse maximale)
- **acceleration_duration :** 0.4s (durée d'accélération)
- **slam_velocity :** -33.0 (vitesse de slam)
- **Fonctions :** `start_jump()`, `start_slam()`, `get_current_speed()`

#### PlayerCombat.gd
- **revolver_damage :** 25 (dégâts par tir)
- **Fonctions :** `trigger_shot()`, `trigger_reload()`, `trigger_recoil()`
- **Communication :** Connexion directe avec PlayerCamera

#### PlayerInput.gd
- **mouse_sensitivity :** 0.002 (sensibilité souris)
- **Fonctions :** Délégation des inputs aux composants

### Paramètres Saut Avancé (PlayerMovement)
- **jump_boost_duration :** 0.5s (durée de la poussée)
- **jump_boost_velocity :** 25.0 (force initiale)
- **jump_boost_force_multiplier :** 5.0 (accélération progressive)
- **jump_gravity_multiplier :** 0.6 (gravité réduite)
- **jump_hover_duration :** 0.03s (flottement au sommet)
- **max_jump_height :** 2.1m (hauteur maximale)
- **fall_gravity_multiplier :** 1.1 (gravité de chute)
- **Fonctions :** _start_jump_boost(), _handle_jump_boost(), _reset_jump_states()

### Paramètres Tremblement (Revolver)
- **shake_intensity :** 3.0 pixels
- **shake_duration :** 0.15s par balle
- **shake_frequency :** 20.0 oscillations/s
- **Fonction :** _create_weapon_shake() (renommée, ligne 246-285)
- **Utilisation :** Rechargement ET clic vide
- **Position adaptative :** base_position (clic vide) ou reload_position (rechargement)

### Paramètres Rougissement (Enemy)
- **red_flash_duration :** 0.2s
- **red_flash_intensity :** 1.5
- **red_flash_color :** Rouge pur
- **Fonction :** _create_red_flash() (ligne 115-143)

### Paramètres Pathfinding (Enemy)
- **move_speed :** 3.0 (vitesse de déplacement)
- **raycast_distance :** 2.0 (distance de détection d'obstacles)
- **avoid_direction :** Vector3(-direction.z, 0, direction.x) (contournement à droite)
- **Fonctions :** _physics_process() (ligne 78-112), _setup_navigation(), _update_navigation()

### Paramètres Rotation (Enemy)
- **billboard :** false (désactivé dans enemy.tscn)
- **direction_calculation :** (player_position - enemy_position).normalized()
- **y_component :** 0 (ignoré pour rotation horizontale uniquement)
- **Fonction :** _update_sprite_rotation() (ligne 220-234)
- **look_at_target :** global_position + direction_to_player

### Optimisations de Code (Décembre 2024)
- **Variables supprimées :** `last_shot_time` (inutilisée dans la logique de cadence)
- **Fonctions renommées :** `_create_reload_shake()` → `_create_weapon_shake()` (nom plus générique)
- **Vérifications consolidées :** `play_shot_animation()` restructurée pour plus de lisibilité
- **Code nettoyé :** Suppression des commentaires redondants et optimisation de la structure

### Performance
- Une seule map pour optimiser
- Sprites 2D avec rotation manuelle (billboard désactivé)
- GPUParticles3D pour effets
- Sons optimisés avec superposition

---
