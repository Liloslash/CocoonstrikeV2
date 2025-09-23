# 🎮 cocoonstrike - rebuild

---

## 📑 NAVIGATION RAPIDE

**=== INFORMATIONS GÉNÉRALES ===**
- Ligne 34 : Informations du projet
- Ligne 44 : Concept du jeu

**=== ARCHITECTURE ===**
- Ligne 58 : Structure des scènes
- Ligne 71 : Scene Player
- Ligne 84 : Scene Enemy
- Ligne 93 : Navigation et Pathfinding

**=== SYSTÈMES ===**
- Ligne 96 : Système Joueur
- Ligne 130 : Système de Saut Avancé
- Ligne 154 : Système Revolver
- Ligne 181 : Système Ennemis (Pathfinding)
- Ligne 208 : Effets d'Impact

**=== RESSOURCES ===**
- Ligne 233 : Assets Audio
- Ligne 252 : Assets Visuels
- Ligne 270 : Configuration

**=== ÉTAT DU PROJET ===**
- Ligne 292 : Fonctionnel
- Ligne 301 : En cours
- Ligne 312 : Roadmap

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

### Scene Player

```
Player (CharacterBody3D)
├── Camera3D
│   └── RayCast3D (collision_mask = 2)
├── CollisionShape3D (CapsuleShape3D)
├── AudioStreamPlayer3D (bruits de pas)
└── HUD_Layer (CanvasLayer)
	└── Revolver (AnimatedSprite2D)
		└── AnimationPlayer (Sway_Idle)
```

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

## ⚙️ SYSTÈME DE SAUT AVANCÉ

### Mécanique de Saut Boost
- **Déclenchement :** Espace (quand au sol)
- **Durée de poussée :** 0.5s
- **Force initiale :** 25.0 (vitesse de poussée)
- **Multiplicateur de force :** 5.0 (accélération progressive)
- **Gravité réduite :** 0.6x pendant la montée

### Hauteur et Contrôle
- **Hauteur maximale :** 2.1m (relative au point de saut)
- **Flottement au sommet :** 0.03s (suspension très courte)
- **Gravité de chute :** 1.1x (chute légèrement plus rapide)

### Courbe de Saut
- **Type :** Ease-in quadratique (accélération progressive)
- **Feeling :** Montée rapide et puissante, comme "aspiré" vers le sommet
- **Physique :** Force progressive appliquée sur la durée du boost

### Slam Aérien
- **Déclenchement :** Q (en l'air ou pendant le flottement)
- **Vitesse :** -33.0 (plonge rapide)
- **Temps minimum :** 0.4s après le saut
- **Gel après impact :** 0.3s

### Variables Exportées (Éditeur)
- `jump_boost_duration` : Durée de la poussée rapide
- `jump_boost_velocity` : Force de la poussée initiale
- `jump_boost_force_multiplier` : Multiplicateur de force maximale
- `jump_gravity_multiplier` : Gravité réduite pendant la montée
- `jump_hover_duration` : Temps de flottement au sommet
- `max_jump_height` : Hauteur maximale relative au point de saut
- `fall_gravity_multiplier` : Multiplicateur de gravité pour la chute

### Fonctions Clés
- `_start_jump_boost()` : Initialise la poussée avec vélocité de base
- `_handle_jump_boost()` : Gère la force progressive et la transition vers le flottement
- `_handle_gravity_and_jump()` : Applique la gravité selon l'état du saut
- `_reset_jump_states()` : Remet à zéro tous les états de saut

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

### Effets de Rechargement
- **Tremblement :** Micro-recul par balle
- **Intensité :** 3.0 pixels
- **Durée :** 0.15s par balle
- **Fréquence :** 20 oscillations/s
- **Direction :** Aléatoire

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
- Player complet (mouvement, tir, effets)
- Système de saut avancé (boost, flottement, slam)
- Revolver complet (animations, sons, munitions)
- Enemy complet (vie, dégâts, mort, pathfinding)
- Système de collisions configuré
- Effets d'impact pixel explosion
- Pathfinding ennemis (raycast d'évitement d'obstacles)

### 🔄 EN COURS
- Amélioration du système d'évitement d'obstacles
- Système de vagues

### ❌ À IMPLÉMENTER
- Collectibles et pièges
- Audio ambiant
- Polissage final

---

## 🚀 ROADMAP

### 🔥 PRIORITÉS CRITIQUES
1. **🎯 FINALISER LA MÉCANIQUE DE SAUT** - Effet d'arrivée au sommet !
   - Améliorer l'effet visuel/physique d'arrivée au sommet du saut
   - Polir la transition entre boost et flottement
   - Affiner la courbe de saut pour un feeling optimal
   - **OBJECTIF :** Saut parfait avec effet "aspiré" au sommet

2. **🚨 PATHFINDING VRAI** - NavigationMesh non fonctionnelle !
   - NavigationMesh reste vide (pas de grille bleue visible)
   - NavigationAgent3D inutile (next_path_position = même position)
   - Système actuel = simple évitement basique (raycast + tourner à droite)
   - **OBJECTIF :** Implémenter du vrai pathfinding avec NavigationMesh fonctionnelle

### PRIORITÉS ACTUELLES
3. **Sons supplémentaires** (pas player, impact slam, dégât/mort enemy)
4. **Comportement enemy** : shaking dégât, mort plus recherchée

---

## 🎯 RÉFÉRENCE RAPIDE

### Paramètres Saut Avancé (Player)
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
- **Fonction :** _create_reload_shake() (ligne 244-283)

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

### Performance
- Une seule map pour optimiser
- Sprites 2D avec rotation manuelle (billboard désactivé)
- GPUParticles3D pour effets
- Sons optimisés avec superposition

---

*Documentation générée le 19 décembre 2024*  
*Dernière mise à jour : 19 décembre 2024 - Système de saut avancé implémenté*  
*Projet développé avec Godot Engine v4.4.1*
