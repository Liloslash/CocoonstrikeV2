# 📋 DOC_PROJET - Cocoonstrike Rebuild

---

## 📑 SOMMAIRE

**GÉNÉRAL**
- Informations Générales

**ARCHITECTURE**
- Architecture Joueur & Ennemis
- Système de Collision

**SYSTÈMES**
- Systèmes Clés (Mouvement, Combat, Caméra, Vol)
- Ennemis - Détails (4 types)

**RESSOURCES**
- Assets Audio & Visuels
- Configuration
- Structure Fichiers

---

## 📋 INFORMATIONS GÉNÉRALES

**Moteur :** Godot Engine v4.4.1  
**Type :** FPS Survival Shooter 3D  
**Style :** Pixel Art / Retro  
**Plateforme :** PC (Windows, Linux)

---

## 🏗️ ARCHITECTURE

### Joueur (Architecture Modulaire)
- **PlayerCamera** : Effets visuels, shake, recul
- **PlayerMovement** : Déplacement, saut, slam
- **PlayerCombat** : Tir, dégâts, raycast
- **PlayerInput** : Inputs clavier/souris
- **Revolver** : Arme (6 balles, rechargement)

### Ennemis (Héritage depuis EnemyBase)
**4 types implémentés :**

| Ennemi | Type | PV | Dégâts | Vitesse |
|--------|------|-----|--------|---------|
| **PapillonV1** | Volant | 75 | 10 | 1.0x |
| **PapillonV2** | Volant | 75 | 20 | 1.5x |
| **BigMonsterV1** | Terrestre | 62 | 20 | 1.0x |
| **BigMonsterV2** | Terrestre | 62 | 30 | 0.75x |

**EnemyBase inclut :**
- Système vie/dégâts/mort
- Effets visuels (rougissement, vibration)
- Repoussement slam
- Rotation auto vers joueur
- **Système d'ombre portée** (raycast au sol, configurable par ennemi)

### Collision
- **Layer 0** : Environnement
- **Layer 1** : Joueur
- **Layer 2** : Ennemis

---

## ⚙️ SYSTÈMES CLÉS

### Mouvement Joueur
- **Hauteur Y** : 1.2m (visibilité sur murets)
- **Saut** : 3.5m de hauteur
- **Slam** : Repoussement 2m de rayon
- **Vitesse** : Accélération progressive

### Combat
- **Arme** : Revolver 6 balles
- **Dégâts** : 25 points/tir
- **Raycast** : Compensation automatique saut
- **Effets** : Particules colorées par ennemi

### Caméra
- **Head Bob** : Mouvement de marche réaliste
- **Shake** : Combinaison tir + slam
- **Recoil** : Recul avec variation aléatoire
- **Jump Look Down** : 25° pendant saut

### Système de Spawn
- **Scene principale :** `world.tscn`
- **Script clé :** `Enemy/SpawnTestRunner.gd`
- **Activation rapide :** Export `is_active` (case à cocher) pour démarrer/arrêter le runner.
- **Sélection zones :** Export `enabled_zones_mask` (cases Zone 1 → Zone 4). Le script recherche tous les `SpawnPoint` (`SpawnPoint.tscn`) dont `zone_id` correspond aux cases cochées.
- **Fallback :** Si aucune zone n’est cochée, le runner tente `spawn_point_path` (héritage de l’ancien système) puis annule proprement avec warning.
- **Timer interne :** crée un `Timer` pour cadencer les spawns (`spawn_interval`), gère les retries (`retry_delay`, `max_spawn_attempts`) et recycle les scenes invalides.
- **SpawnPoint.tscn :** `zone_id`, `spawn_radius`, gizmo masqué en runtime (`EditorOnly` invisible) pour placer les zones 3D.

### Vol des Papillons
**Principe :** Raycast vertical pour suivre le sol + interpolation vers une hauteur cible, avec oscillation sinus.

**Pipeline :**
1. Raycast vers le bas (`max_hover_ray_distance`) pour détecter le sol (filtré par `hover_collision_mask`).
2. Hauteur cible = `sol + hover_height + sin(float_timer) * float_amplitude`.
3. Interpolation `lerp` contrôlée par `hover_follow_speed` après `move_and_slide()`.
4. Gravité appliquée (`gravity_scale`), retombée naturelle si aucun sol détecté.

**Paramètres exportés :**
- `hover_height`, `float_amplitude`, `float_speed`
- `hover_strength`, `hover_damping`, `hover_follow_speed`
- `gravity_scale`, `max_hover_ray_distance`, `hover_collision_mask`

---

## 🎮 ENNEMIS - DÉTAILS

### PapillonV1 (Volant Léger)
- **75 PV** | **10 dégâts** | **Vitesse 1.0x**
- Flottement paisible (speed 1.5) + suivi du sol (raycast) pour rester à `hover_height`
- Couleurs : Bleu, Cyan, Rose, Jaune

### PapillonV2 (Volant Agressif)
- **75 PV** | **20 dégâts** | **Vitesse 1.5x**
- Flottement rapide (speed 3.0) + même logique de suivi du sol
- Couleurs : Orange, Rouge, Jaune-orange

### BigMonsterV1 (Terrestre Équilibré)
- **62 PV** | **20 dégâts** | **Vitesse 1.0x**
- Gravité active (`gravity_scale` configurable) : retombe naturellement après un spawn en suspension
- Animation : 1 frame statique
- Couleurs : Rouge foncé, Orange, Brun
- **Mort** : Dissolution pixelisée (shader commun, tween 0.45s, `death_pixel_size = 156`)
- **Mort (FX)** : Lancement automatique du shader `pixel_dissolve.gdshader` (palette ennemie) avec tween Godot `create_tween()`

### BigMonsterV2 (Tank Lourd)
- **62 PV** | **30 dégâts** | **Vitesse 0.75x**
- Gravité active + même logique de retombée contrôlée que V1
- Animation : 26 frames de marche
- Couleurs : Violet foncé, Gris
- **Mort** : Dissolution pixelisée (mêmes paramètres éditables que V1)
- **Mort (FX)** : Même pipeline shader/tween que V1 (`dissolve_amount` + `pixel_size` sur 0.45s, `death_pixel_size = 156`)

### Système d'Ombres Portées
**Tous les ennemis** ont une ombre portée configurable qui suit le sol via raycast.

**Configuration par défaut :**
- **BigMonster V1/V2** : Taille 0.42x, Opacité 0.384
- **Papillon V1/V2** : Taille 0.75x, Opacité 0.384

**Paramètres exportés** (modifiables dans l'éditeur) :
- `shadow_size` : Multiplicateur de taille (0.0 à 2.0)
- `shadow_opacity` : Opacité de l'ombre (0.0 à 1.0)

**Fonctionnement :**
- Raycast vertical pour détecter le sol sous l'ennemi
- Ombre positionnée automatiquement au niveau du sol
- Rotation 90° sur Y pour orientation correcte
- Texture : `shadow_simple.svg`

### Effets de Mort (Pixel Dissolve)
- **Shader partagé** : `Effects/Shaders/pixel_dissolve.gdshader`
- **Ennemis concernés** : Papillon V1/V2, BigMonster V1/V2 (paramètres éditables par variant)
- **Paramètres principaux** : `dissolve_amount` (0→1), `pixel_size` (1→N selon taille sprite), `edge_glow`, `edge_color`
- **Tween** : `create_tween()` (0.45s par défaut) anime dissolution + pixellisation, `queue_free()` à la fin
- **Palette** : Couleurs d’impact de l’ennemi (4 teintes exportées) injectées dans le shader via `edge_color`

---

## 🎨 ASSETS

### Audio
- **Guns** : 8 sons revolver
- **Enemies** : Pas lourds, rugissements, ailes
- **Player** : Pas, cœur, cris
- **UI** : Bonus, countdown, succès
- **Musique** : Metalcore.mp3

### Visuels
- **Sprites** : 128x128 pixels
  - BigMonsterV1/V2 (1 et 26 frames)
  - PapillonV1/V2 (6 frames chacun)
- **Armes** : Revolver, TurboGun
- **Maps** : Arena.glb, Obstacles.glb

---

## 🔧 CONFIGURATION

### Input Map
- **WASD** : Déplacement
- **Espace** : Saut
- **A** : Slam
- **Clic gauche** : Tir
- **R** : Rechargement
- **ESC** : Libérer souris

### Rendering
- **Mode** : GL Compatibility
- **Filtrage** : Nearest (pixel art)

---

## 📁 STRUCTURE FICHIERS

```
/Player/          - Composants joueur (4 scripts modulaires)
/Enemy/           - EnemyBase + 4 ennemis (Papillon V1/V2, BigMonster V1/V2) + SpawnTestRunner + SpawnPoint
/Revolver/        - Script arme
/Effects/         - ImpactEffect (particules)
/Maps/            - Arena + Obstacles (glb)
/Assets/          - Audio, Sprites, Fonts
world.tscn        - Scène principale
```

---

**Voir aussi :**
- `Doc_Game_Design.md` - Concept et gameplay
- `Doc_Roadmap.md` - Roadmap et état du projet

---
