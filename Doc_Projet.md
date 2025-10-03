# 📋 DOC_PROJET

---

## 📑 NAVIGATION RAPIDE

**=== INFORMATIONS GÉNÉRALES ===**
- Ligne 36 : Informations du projet

**=== ARCHITECTURE ===**
- Ligne 46 : Structure des scènes
- Ligne 59 : Scene Player (Architecture Modulaire)
- Ligne 74 : Architecture Modulaire du Joueur
- Ligne 90 : Scene Enemy (Architecture d'héritage)
- Ligne 107 : Collision Layers et Masks

**=== SYSTÈMES ===**
- Ligne 126 : Système Joueur
- Ligne 150 : Système de Saut Simplifié
- Ligne 192 : Système Revolver
- Ligne 242 : Système de Caméra Avancé
- Ligne 275 : Système de Compensation du Raycast
- Ligne 324 : Système Ennemis (Architecture Modulaire)
- Ligne 384 : Effets d'Impact

**=== RESSOURCES ===**
- Ligne 401 : Assets Audio
- Ligne 420 : Assets Visuels
- Ligne 438 : Configuration

**=== RÉFÉRENCES ===**
- Voir Doc_Roadmap.md pour l'état du projet et la roadmap

---

## 📋 INFORMATIONS GÉNÉRALES

**Nom :** Cocoonstrike - Rebuild  
**Moteur :** Godot Engine v4.4.1  
**Type :** FPS Survival Shooter 3D  
**Style :** Pixel Art et 3D / Retro  
**Plateforme :** PC (Windows, Linux)

---

## 🏗️ ARCHITECTURE TECHNIQUE

### Structure des Scènes

```
World (Node principal)
├── Arena (Node3D) - Zone d'arène
├── Obstacles (Node3D) - Zone d'obstacles  
├── WorldEnvironment3D - Éclairage et ciel
├── Player (CharacterBody3D) - Joueur principal
└── EnemyTest (CharacterBody3D) - Ennemi de test (instancié manuellement)
```

### Scene Player (Architecture Modulaire)

```
Player (CharacterBody3D) - ORCHESTRATEUR
├── PlayerCamera (Camera3D) - Gestion caméra (hérite de Camera3D)
├── PlayerMovement (Node) - Mouvement et saut
├── PlayerCombat (Node) - Tir et raycast
├── PlayerInput (Node) - Gestion des inputs
├── CollisionShape3D (CapsuleShape3D)
├── AudioStreamPlayer3D (bruits de pas)
└── HUD_Layer (CanvasLayer)
	└── Revolver (AnimatedSprite2D)
		└── AnimationPlayer (Sway_Idle)
```

### Architecture Modulaire du Joueur

**Principe :** Séparation des responsabilités en composants spécialisés

- **PlayerCamera** : Shake, head bob, recul de tir, jump look down
- **PlayerMovement** : Mouvement, saut, slam, gestion de la vitesse
- **PlayerCombat** : Tir, raycast, dégâts, effets d'impact
- **PlayerInput** : Gestion des inputs (souris, clavier)
- **player.gd** : Orchestrateur qui coordonne tous les composants

### Avantages de l'Architecture Modulaire
- **Maintenabilité** : Code plus lisible, modifications isolées
- **Évolutivité** : Ajout de fonctionnalités facile
- **Performance** : Chargement optimisé, gestion mémoire efficace
- **Collaboration** : Travail en équipe facilité

### Scene Enemy

```
EnemyTest (CharacterBody3D) - ENNEMI DE DÉVELOPPEMENT
├── AnimatedSprite3D (billboard désactivé - rotation manuelle)
├── CollisionShape3D (collisions environnement)
└── Area3D (détection/dégâts)
	└── CollisionShape3D
```

**Architecture d'héritage :**
- **EnemyBase** : Classe abstraite avec logique commune (vie, effets, slam, rotation)
- **EnemyTest** : Ennemi de développement qui hérite d'EnemyBase
- **Futurs ennemis** : 6 ennemis spécifiques (PapillonV1/V2, MonsterV1/V2, BigMonsterV1/V2)

**Note :** Le système de pathfinding (NavigationAgent3D) a été temporairement supprimé pour repartir sur des bases propres. Il sera réimplémenté plus tard avec un nouveau système d'IA.

### Collision Layers et Masks

```
Layer 0 : Environnement (sol, murs, obstacles)
Layer 1 : Joueur (collision_layer = 1, collision_mask = 3)
Layer 2 : Ennemis (collision_layer = 2, collision_mask = 3)
```

**Configuration :**
- **Joueur** : Détecte l'environnement (layer 0) et les ennemis (layer 2)
- **Ennemis** : Détecte l'environnement (layer 0) et le joueur (layer 1)
- **Environnement** : Détecté par tous (layers 1 et 2)

**Structure RayCast :**
- **PlayerCamera/RayCast3D** : collision_mask = 2 (détecte seulement les ennemis)
- **Position** : RayCast3D est maintenant directement dans PlayerCamera (plus dans une caméra générique)

---

## ⚙️ SYSTÈME DE JOUEUR

### Mouvement FPS
- **Contrôles :** WASD + Souris
- **Slam :** A (slam_velocity = -33.0)
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
- **🚀 NOUVEAU : Système de compensation du raycast** : Synchronisation automatique entre la caméra et le raycast lors du saut

---

## ⚙️ SYSTÈME DE SAUT SIMPLIFIÉ

### Mécanique de Saut
- **Déclenchement :** Espace (quand au sol)
- **Hauteur de saut :** 3.3m (hauteur désirée)
- **Force du saut :** 4.5 (vitesse verticale calculée automatiquement)
- **Gravité de chute :** 1.0x (gravité normale)
- **Feeling :** Saut simple et réactif, contrôle immédiat

### Slam Aérien
- **Déclenchement :** A (en l'air)
- **Vitesse :** -33.0 (plonge rapide)
- **Temps minimum :** 0.4s après le saut
- **Gel après impact :** 0.3s
- **Effet sur ennemis :** Repoussement dans un rayon de 2m

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

## ⚙️ SYSTÈME DE COMPENSATION DU RAYCAST

### Problème Résolu
- **Problème initial** : Désynchronisation entre l'inclinaison de la caméra et la direction du raycast lors du saut
- **Symptôme** : Le joueur vise un ennemi mais le tir rate à cause de l'inclinaison de la caméra
- **Impact** : Frustration du joueur, feeling de jeu dégradé

### Solution Implémentée
- **Approche** : Raycast avec offset dynamique basé sur l'angle d'inclinaison de la caméra
- **Méthode** : Calcul trigonométrique de l'offset vertical pour compenser l'inclinaison
- **Intégration** : Mise à jour automatique de la direction du raycast avant chaque tir

### Paramètres Configurables (PlayerCombat.gd)
- **`enable_jump_compensation`** : `bool = true` - Activation/désactivation du système
- **`compensation_strength`** : `float = 1.0` - Force de la compensation
  - `1.0` = compensation parfaite (recommandé)
  - `0.5` = compensation réduite (plus réaliste)
  - `1.5` = surexposition (pour effets spéciaux)
- **`max_compensation_angle`** : `float = 45.0` - Angle maximum de compensation en degrés

### Fonctions Clés
- **`_calculate_raycast_compensation()`** : Calcule l'offset basé sur l'angle de la caméra
- **`_update_raycast_direction()`** : Applique la direction compensée au raycast
- **`set_jump_compensation(bool)`** : Active/désactive la compensation depuis l'extérieur
- **`set_compensation_strength(float)`** : Ajuste la force de la compensation
- **`set_max_compensation_angle(float)`** : Définit l'angle maximum de compensation

### Algorithme de Compensation
1. **Détection** : Récupération de l'angle d'inclinaison actuel de la caméra (`rotation_degrees.x`)
2. **Limitation** : Clamp de l'angle entre `-max_compensation_angle` et `+max_compensation_angle`
3. **Calcul trigonométrique** : `y_offset = sin(angle_radians) * raycast_length * compensation_strength`
4. **Application** : `compensated_direction = base_raycast_direction + Vector3(0, y_offset, 0)`
5. **Mise à jour** : Application de la direction compensée au raycast avant le tir

### Avantages
- **Précision** : Le tir va exactement où le joueur vise, même avec l'inclinaison de la caméra
- **Configurabilité** : Paramètres ajustables pour différents styles de jeu
- **Performance** : Calculs légers, pas d'impact sur les performances
- **Robustesse** : Limitation des angles pour éviter les corrections excessives
- **Intégration** : Fonctionne automatiquement avec tous les mouvements de caméra

### Utilisation
- **Automatique** : Le système s'active automatiquement lors du saut
- **Transparent** : Aucune intervention du joueur nécessaire
- **Ajustable** : Paramètres modifiables dans l'inspecteur Godot
- **Extensible** : Peut être étendu pour d'autres mouvements de caméra

---

## ⚙️ SYSTÈME D'ENNEMIS

### Architecture Modulaire
- **EnemyBase** : Classe abstraite avec toute la logique commune
- **EnemyTest** : Ennemi de développement/test (instancié dans world.tscn)
- **Système d'héritage** : Prêt pour 6 ennemis spécifiques (PapillonV1/V2, MonsterV1/V2, BigMonsterV1/V2)

### Fonctionnalités Communes (EnemyBase)
- **Système de vie/dégâts** : take_damage(), _die(), gestion de la santé
- **Effets visuels** : Rougissement rouge + tremblement (communs à tous)
- **Système de slam** : Repoussement automatique (réaction commune)
- **Rotation intelligente** : Tous les ennemis regardent vers le joueur
- **Gestion des groupes** : Tous dans le groupe "enemies" (pour les vagues)
- **Freeze pendant animations** : Pendant dégâts/slam

### Fonctionnalités Spécifiques (par ennemi)
- **Physique** : Chaque ennemi gère sa propre physique (gravité, collisions, mouvement)
- **4 couleurs d'impact** : Spécifiques à chaque ennemi (méthode get_impact_colors())
- **Comportements** : Chaque ennemi peut surcharger les méthodes virtuelles

### EnemyTest (Ennemi de Développement)
- **Statistiques** : 500 points de vie, gravité 1.2x
- **Collision Layer** : 2 (détectable par raycast)
- **Collision Mask** : 3 (détecte environnement + joueur)
- **Fonctionnalités de test** : Mode debug, statistiques, contrôles clavier
- **4 couleurs d'impact** : Rouge, Vert, Violet, Noir

### Système de Repoussement Slam
- **Déclenchement** : Quand le joueur fait un slam à proximité (rayon 2m)
- **Force** : slam_push_force (4.0 par défaut, configurable)
- **Durée du bond** : slam_bond_duration (0.6s par défaut)
- **Délai avant freeze** : slam_freeze_delay (0.8s par défaut)
- **Cooldown** : slam_cooldown_time (0.2s par défaut)
- **Effet** : Bond en arrière + freeze temporaire
- **Bug corrigé** : Tir pendant repoussement n'interrompt plus le mouvement

### Système de Rotation
- **Billboard** : Désactivé pour contrôle manuel
- **Rotation automatique** : Vers le joueur en temps réel
- **Axe de rotation** : X/Z uniquement (pas de rotation verticale)
- **Méthode** : look_at() avec direction normalisée (Y = 0)
- **Vérifications** : is_instance_valid() pour éviter les erreurs

### Effet de Rougissement
- **Feedback** : Rouge quand dégâts
- **Durée** : 0.2s
- **Intensité** : 1.5
- **Transition** : EASE_OUT
- **Déclenchement** : À l'impact

### Système d'Effet de Vibration
- **Fonctionnalité** : Vibration du sprite ennemi lors de l'impact
- **Paramètres personnalisables** : Durée, intensité, fréquence, axes
- **Architecture** : Système modulaire avec dictionnaire de paramètres
- **Intégration** : Communication entre revolver et ennemi via PlayerCombat
- **Valeurs par défaut** : 0.15s, 0.06 intensité, 75 Hz, axes X/Y
- **Avantages** : Extensible pour d'autres armes, paramètres ajustables par arme

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
- **A :** Slam
- **Clic gauche :** Tir
- **R :** Rechargement

### Corrections et Optimisations
- **Collision layers** : Correction des layers incorrects dans world.tscn
- **RayCast caméra** : RayCast3D déplacé vers PlayerCamera (correspondance parfaite)
- **Double caméra** : Suppression de la caméra en double
- **Connexions de signal** : Ajout de CONNECT_ONE_SHOT pour éviter les fuites mémoire
- **Await avec gestion d'erreur** : Vérification is_alive après chaque await
- **UID des fichiers** : Correction des références UID après renommage

### Collision Layers
- **Layer 0 :** Environnement
- **Layer 1 :** Joueur
- **Layer 2 :** Ennemis (détectable par raycast)

### Rendering
- **Mode :** GL Compatibility
- **Filtrage :** Nearest (pixel art)
- **Ciel :** ProceduralSkyMaterial

---
