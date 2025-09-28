# 📋 DOC_PROJET

---

## 📑 NAVIGATION RAPIDE

**=== INFORMATIONS GÉNÉRALES ===**
- Ligne 45 : Informations du projet
- Ligne 55 : Concept du jeu

**=== ARCHITECTURE ===**
- Ligne 69 : Structure des scènes
- Ligne 82 : Scene Player (Architecture Modulaire)
- Ligne 99 : Architecture Modulaire du Joueur
- Ligne 208 : Scene Enemy
- Ligne 219 : Navigation et Pathfinding

**=== SYSTÈMES ===**
- Ligne 230 : Système Joueur
- Ligne 253 : Système de Saut Simplifié
- Ligne 294 : Système Revolver
- Ligne 344 : Système de Caméra Avancé
- Ligne 377 : Système Ennemis (Pathfinding)
- Ligne 427 : Effets d'Impact

**=== RESSOURCES ===**
- Ligne 444 : Assets Audio
- Ligne 463 : Assets Visuels
- Ligne 481 : Configuration

**=== ÉTAT DU PROJET ===**
- Ligne 503 : Fonctionnel
- Ligne 521 : En cours
- Ligne 525 : À implémenter
- Ligne 530 : Récent

**=== RÉFÉRENCES ===**
- Ligne 554 : Référence Rapide

**=== ROADMAP ===**
- Voir Doc_Roadmap.md (fichier séparé)

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

#### PlayerCamera.gd (254 lignes)
- **Type :** `extends Camera3D` (hérite directement de Camera3D)
- **Responsabilités :** Shake, head bob, recul de tir, jump look down
- **Paramètres :** Intensité, durée, fréquence des effets
- **Fonctions clés :** `start_camera_shake()`, `trigger_recoil()`, `start_jump_look_down()`
- **Avantage :** Accès direct aux propriétés de la caméra (position, rotation)
- **Optimisations :** Cache de référence movement_component pour performance

#### PlayerMovement.gd (158 lignes)
- **Responsabilités :** Mouvement, saut, slam, gestion de la vitesse
- **Paramètres :** Vitesse, accélération, gravité, hauteur de saut
- **Fonctions clés :** `start_jump()`, `start_slam()`, `get_current_speed()`, `is_moving()`
- **Optimisations :** Calcul de vélocité de saut simplifié avec `max()`

#### PlayerCombat.gd (102 lignes)
- **Responsabilités :** Tir, raycast, dégâts, effets d'impact
- **Paramètres :** Dégâts du revolver
- **Fonctions clés :** `trigger_shot()`, `trigger_reload()`, `trigger_recoil()`
- **Communication :** Connexion directe avec PlayerCamera pour le recul
- **Optimisations :** Gestion robuste des références avec vérifications

#### PlayerInput.gd (45 lignes)
- **Responsabilités :** Gestion des inputs (souris, clavier)
- **Paramètres :** Sensibilité de la souris
- **Fonctions clés :** Délégation des actions aux composants
- **Optimisations :** Code concis et efficace

#### player.gd (69 lignes) - ORCHESTRATEUR
- **Responsabilités :** Coordination des composants et gestion des signaux
- **Fonctions clés :** `_ready()`, `_process()`, `_physics_process()`, `_update_revolver_movement_state()`
- **Signaux :** Connexion `slam_landed` → camera shake, `shot_fired` → recul
- **Optimisations :** Gestion optimisée du revolver avec early returns

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
│  │ • 254 lignes│  │ • 158 lignes│  │ • 102 lignes│  │ 45  │ │
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
APRÈS : 4 composants + orchestrateur (69 lignes) - SÉPARÉ ET OPTIMISÉ

### Communication entre Composants

#### Signaux Utilisés
- **`slam_landed`** : PlayerMovement → player.gd → PlayerCamera (camera shake)
- **`shot_fired`** : Revolver → PlayerCombat → PlayerCamera (recul)

#### Références Directes
- **PlayerCombat** → **PlayerCamera** : Communication directe pour le recul
- **player.gd** → **Tous les composants** : Orchestration et délégation
- **player.gd** → **Revolver** : Transmission de la vitesse pour le sway dynamique

#### Communication Temps Réel
- **Vitesse du joueur** : `movement_component.get_current_speed()` → `revolver.set_movement_state()`
- **Cache de référence** : `movement_component` mis en cache dans PlayerCamera pour performance
- **Gestion optimisée** : Early returns et vérifications robustes pour éviter les erreurs
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
- **Camera Shake :** Système de tremblements multiples combinés avec décélération cubic
- **Head Bob Réaliste :** Mouvement de tête simulant la marche naturelle avec transitions fluides
- **Recoil :** Recul lors du tir avec variation aléatoire
- **Kickback :** Recul caméra arrière
- **Jump Look Down :** Inclinaison automatique de 25° pendant le saut

### Combat
- **RayCast3D :** collision_mask = 2
- **Dégâts :** 25 points par tir
- **Signal :** shot_fired du revolver
- **Impact :** Particules colorées

---

## ⚙️ SYSTÈME DE SAUT SIMPLIFIÉ

### Mécanique de Saut
- **Déclenchement :** Espace (quand au sol)
- **Hauteur de saut :** 3.3m (hauteur désirée)
- **Force du saut :** 4.5 (vitesse verticale calculée automatiquement)
- **Gravité de chute :** 1.0x (gravité normale)
- **Feeling :** Saut simple et réactif, contrôle immédiat

### Slam Aérien
- **Déclenchement :** Q (en l'air)
- **Vitesse :** -33.0 (plonge rapide)
- **Temps minimum :** 0.4s après le saut
- **Gel après impact :** 0.3s

### Effet de Caméra "Jump Look Down"
- **Déclenchement :** Automatique au saut
- **Angle d'inclinaison :** 25° vers le bas (configurable)
- **Démarrage :** À partir de la moitié du saut
- **Progression :** Inclinaison progressive jusqu'au sommet
- **Maintien :** Angle conservé pendant la chute
- **Retour :** Transition douce vers la position normale à l'atterrissage

### Variables Exportées (Éditeur)
**PlayerMovement :**
- `jump_height` : Hauteur de saut désirée (3.3m)
- `jump_velocity` : Force du saut (4.5, calculée automatiquement)
- `fall_gravity_multiplier` : Multiplicateur de gravité pour la chute (1.0)

**PlayerCamera :**
- `jump_look_angle` : Angle d'inclinaison vers le bas (25°)
- `jump_look_smoothness` : Vitesse de transition (4.0)

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
- **Cadence :** 0.5s entre tirs
- **États :** IDLE, RELOAD_STARTING, RELOAD_ADDING_BULLETS, RELOAD_INTERRUPTED

### Audio
- **Sons :** Tir, rechargement, clic vide
- **Superposition :** Plusieurs sons simultanés
- **Fichiers :** GunShot-2.mp3, OpenRevolverBarrel.mp3, AddRevolverBullet.mp3, CloseRevolverBarrel.mp3, AOARevolver.mp3

### Animations
- **Tween :** Mouvements fluides
- **SpriteFrames :** 11 frames de tir


### Effets de Tremblement
- **Fonction :** `_create_weapon_shake()` et `_create_weapon_shake_at_position()`
- **Utilisation :** Rechargement ET clic vide (plus de munitions)
- **Intensité :** 3.0 pixels
- **Durée :** 0.15s par balle
- **Fréquence :** 20 oscillations/s
- **Direction :** Aléatoire
- **Position adaptative :** Position actuelle (clic vide) ou `reload_position` (rechargement)

### Système de Sway Dynamique
- **Sway Idle :** Mouvement circulaire subtil (X=2.0, Y=0.5, Z=0.5 à 1.0 Hz)
- **Sway Movement :** Pattern de course réaliste (X=9.0, Y=1.0, Z=2.0 à 5.0 Hz)
- **Transitions fluides :** Interpolation entre les deux patterns avec facteur de transition
- **Intégration :** Arrêt pendant tir/rechargement, reprise automatique
- **Communication :** État de mouvement transmis en temps réel depuis PlayerMovement

### Amélioration du Feeling
- **Clic vide :** Tremblement de l'arme + son (pas de recul de caméra)
- **Feedback visuel :** Simulation du mouvement du poignet
- **Cohérence :** Même effet que lors du rechargement
- **Système de sons optimisé :** Fonction commune `_play_sound_with_superposition()`

### Système d'Effet de Vibration Ennemi
- **Fonctionnalité :** Vibration du sprite ennemi lors de l'impact de tir
- **Architecture modulaire :** Dictionnaire pour paramètres personnalisables
- **Communication :** PlayerCombat transmet les paramètres du revolver à l'ennemi
- **Paramètres par défaut :** Durée 0.15s, intensité 0.06, fréquence 75 Hz
- **Axes configurables :** Vector3(1.0, 1.0, 0.0) pour vibration X et Y
- **Extensibilité :** Facilement adaptable pour d'autres armes ou types de tir

---

## ⚙️ SYSTÈME DE CAMÉRA AVANCÉ

### Head Bob Réaliste
- **Pattern de marche :** Simulation du mouvement naturel de la tête (tête vers le bas au contact du pied)
- **Transitions fluides :** Activation/désactivation progressive (vitesse: 5.0)
- **Mouvement latéral :** Décalage de phase pour le mouvement X (0.5)
- **Amplitude :** 0.06 unités
- **Fréquence :** 6.0Hz
- **Protection :** Désactivé pendant les camera shakes

### Camera Shake Combiné
- **Système multiple :** Plusieurs tremblements simultanés (slam + tir)
- **Décélération :** EaseOutCubic au lieu d'EaseOutElastic
- **Intensité :** 0.8 par défaut
- **Durée :** 0.8s par défaut
- **Rotation :** 5° par défaut
- **Gestion :** Array `active_shakes` pour les tremblements multiples

### Recoil Avancé
- **Variation aléatoire :** 50% de variation dans l'intensité
- **Intensité :** 0.09
- **Durée :** 0.15s
- **Rotation :** 1.5°
- **Kickback :** 0.5 (recul vers l'arrière)

### Jump Look Down
- **Angle :** 25° vers le bas pendant le saut
- **Smoothness :** 4.0 (vitesse de transition)
- **Timing :** Démarre à la moitié du saut
- **Maintien :** Pendant toute la durée du saut

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

### Système d'Effet de Vibration
- **Fonctionnalité :** Vibration du sprite ennemi lors de l'impact
- **Paramètres personnalisables :** Durée, intensité, fréquence, axes
- **Architecture :** Système modulaire avec dictionnaire de paramètres
- **Intégration :** Communication entre revolver et ennemi via PlayerCombat
- **Valeurs par défaut :** 0.15s, 0.06 intensité, 75 Hz, axes X/Y
- **Avantages :** Extensible pour d'autres armes, paramètres ajustables par arme

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
- **Système de saut simplifié** : Saut simple avec effet de caméra "Jump Look Down"
- **Head Bob réaliste** : Mouvement de tête simulant la marche naturelle avec transitions fluides
- **Camera Shake combiné** : Système de tremblements multiples avec décélération cubic
- **Revolver complet** : Animations, sons, munitions, recul de caméra, tremblement clic vide, effet vibration ennemi
- **Système de Sway dynamique** : Mouvement réaliste idle/movement avec transitions fluides
- **Enemy complet** : Vie, dégâts, mort, pathfinding, effet de vibration à l'impact
- **Système de collisions** : Configuré et optimisé
- **Effets d'impact** : Pixel explosion avec couleurs dynamiques
- **Pathfinding ennemis** : Raycast d'évitement d'obstacles
- **Code optimisé** : Refactorisation complète, gestion d'erreurs robuste, performance améliorée
- **Corrections de bugs** : Conflits de classe résolus, vérifications null ajoutées, architecture simplifiée

### 🔄 EN COURS
- Amélioration du système d'évitement d'obstacles
- Système de vagues

### ❌ À IMPLÉMENTER
- Collectibles et pièges
- Audio ambiant
- Polissage final

### 🆕 RÉCENT (Décembre 2024)
- **Refactorisation majeure** : Architecture modulaire du joueur
- **Réduction de complexité** : player.gd passé de 424 à 69 lignes
- **Séparation des responsabilités** : 4 composants spécialisés + orchestrateur
- **Amélioration de la maintenabilité** : Code plus propre et évolutif
- **Corrections d'architecture** : PlayerCamera hérite de Camera3D, communication robuste
- **Résolution des bugs** : Double son de tir, communication recul, références @onready
- **Système de saut simplifié** : Suppression du système complexe de jump boost
- **Effet de caméra "Jump Look Down"** : Inclinaison de 25° pendant le saut pour immersion
- **Head Bob réaliste** : Mouvement de tête simulant la marche naturelle avec transitions fluides
- **Camera Shake combiné** : Système de tremblements multiples avec décélération cubic
- **Optimisations de performance** : Cache des références, gestion d'erreurs robuste
- **Amélioration du feeling de tir** : Tremblement de l'arme lors du clic vide (plus de munitions)
- **Optimisations de code** : Suppression de variables inutilisées, consolidation des vérifications
- **Refactoring de fonctions** : `_create_reload_shake()` → `_create_weapon_shake()` (nom plus générique)
- **Système d'effet de vibration ennemi** : Vibration du sprite ennemi lors de l'impact avec paramètres personnalisables
- **Architecture modulaire pour effets** : Dictionnaire de paramètres pour communication entre armes et ennemis
- **Intégration PlayerCombat** : Communication robuste entre revolver et ennemi pour les effets d'impact
- **Paramètres optimisés** : Durée 0.15s, intensité 0.06, fréquence 75 Hz pour un effet réaliste
- **Corrections de bugs** : Résolution des conflits de classe, optimisation des performances
- **Code robuste** : Vérifications null, gestion d'erreurs améliorée, architecture simplifiée

---

## 🎯 RÉFÉRENCE RAPIDE

### Architecture Modulaire (Player)

#### PlayerCamera.gd
- **Type :** `extends Camera3D` (hérite de Camera3D)
- **shake_intensity :** 0.8 (intensité du shake)
- **shake_duration :** 0.8s (durée du shake)
- **shake_rotation :** 5.0 (rotation du shake)
- **headbob_amplitude :** 0.06 (amplitude du head bob)
- **headbob_frequency :** 6.0 (fréquence du head bob)
- **headbob_transition_speed :** 5.0 (vitesse de transition)
- **headbob_x_phase_offset :** 0.5 (décalage de phase X)
- **recoil_intensity :** 0.09 (intensité du recul)
- **recoil_duration :** 0.15s (durée du recul)
- **recoil_rotation :** 1.5 (rotation du recul)
- **recoil_kickback :** 0.5 (recul vers l'arrière)
- **recoil_variation :** 0.5 (variation aléatoire)
- **jump_look_angle :** 25.0 (angle d'inclinaison saut)
- **jump_look_smoothness :** 4.0 (vitesse de transition saut)
- **Fonctions :** `start_camera_shake()`, `trigger_recoil()`, `start_jump_look_down()`

#### PlayerMovement.gd
- **max_speed :** 9.5 (vitesse maximale)
- **acceleration_duration :** 0.4s (durée d'accélération)
- **slam_velocity :** -33.0 (vitesse de slam)
- **freeze_duration_after_slam :** 0.3s (durée de gel après slam)
- **min_time_before_slam :** 0.4s (temps minimum avant slam)
- **jump_height :** 3.3m (hauteur de saut désirée)
- **jump_velocity :** 4.5 (force du saut, calculée automatiquement)
- **fall_gravity_multiplier :** 1.0 (multiplicateur de gravité pour la chute)
- **Fonctions :** `start_jump()`, `start_slam()`, `get_current_speed()`, `is_moving()`, `is_jumping()`

#### PlayerCombat.gd
- **revolver_damage :** 25 (dégâts par tir)
- **Fonctions :** `trigger_shot()`, `trigger_reload()`, `trigger_recoil()`
- **Communication :** Connexion directe avec PlayerCamera

#### PlayerInput.gd
- **mouse_sensitivity :** 0.002 (sensibilité souris)
- **Fonctions :** Délégation des inputs aux composants

### Paramètres Saut Simplifié (PlayerMovement)
- **jump_height :** 3.3m (hauteur de saut désirée)
- **jump_velocity :** 4.5 (force du saut, calculée automatiquement)
- **fall_gravity_multiplier :** 1.0 (multiplicateur de gravité pour la chute)
- **Fonctions :** `_calculate_jump_velocity()`, `start_jump()`, `is_jumping()`


### Paramètres Sway (Revolver)
- **idle_sway_amplitude :** Vector3(2.0, 0.5, 0.5) (amplitude idle X, Y, Z)
- **idle_sway_frequency :** 1.0 Hz (fréquence idle)
- **movement_sway_amplitude :** Vector3(9.0, 1.0, 2.0) (amplitude movement X, Y, Z)
- **movement_sway_frequency :** 5.0 Hz (fréquence movement)
- **sway_transition_speed :** 3.0 (vitesse de transition entre idle/movement)

### Paramètres Tremblement (Revolver)
- **shake_intensity :** 3.0 pixels
- **shake_duration :** 0.15s par balle
- **shake_frequency :** 20.0 oscillations/s
- **Fonction :** _create_weapon_shake() et _create_weapon_shake_at_position()
- **Utilisation :** Rechargement ET clic vide
- **Position adaptative :** position actuelle (clic vide) ou reload_position (rechargement)

### Paramètres Effet de Vibration (Revolver)
- **hit_shake_duration :** 0.15s (durée de vibration sur ennemi)
- **hit_shake_intensity :** 0.06 (intensité de vibration sur ennemi)
- **hit_shake_frequency :** 75.0 Hz (fréquence d'oscillations sur ennemi)
- **hit_shake_axes :** Vector3(1.0, 1.0, 0.0) (axes de vibration X, Y)
- **Fonction :** get_hit_effect_params() (récupération des paramètres pour l'ennemi)

### Paramètres Rougissement (Enemy)
- **red_flash_duration :** 0.2s
- **red_flash_intensity :** 1.5
- **red_flash_color :** Rouge pur
- **Fonction :** _create_red_flash() (ligne 115-143)

### Paramètres Effet de Vibration (Enemy + Revolver)
- **Dictionnaire de paramètres :** Structure de données pour paramètres d'effet
- **hit_shake_duration :** 0.15s (durée de vibration)
- **hit_shake_intensity :** 0.06 (intensité de vibration)
- **hit_shake_frequency :** 75.0 Hz (fréquence d'oscillations)
- **hit_shake_axes :** Vector3(1.0, 1.0, 0.0) (axes X, Y activés)
- **Fonction Enemy :** _create_hit_shake() (effet de vibration du sprite)
- **Fonction Revolver :** get_hit_effect_params() (récupération des paramètres)
- **Intégration :** PlayerCombat transmet les paramètres du revolver à l'ennemi

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
