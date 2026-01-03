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
- Système d'Interaction (Interrupteurs, Pièges)
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
- **Gestion Interactions** : Gestion HUD + textes d'interaction
  (intégré dans `player.gd`)

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
- **Saut** : 3.3m de hauteur
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

### Système de Vagues
**Script principal :** `world.gd` (attaché au nœud `World` dans `world.tscn`)

**Architecture :**
- Gère les cycles de 5 vagues avec progression automatique
- Système de spawn par paquets d'ennemis
- Timer de vague avec limite de temps
- Connexion automatique aux interrupteurs via groupe `"interrupteurs"`

**Paramètres exportés (configurables dans l'éditeur) :**
- `base_enemy_count` : Nombre de base d'ennemis (n) - défaut : 5
- `base_timer` : Timer de base en secondes - défaut : 30.0
- `packet_size` : Nombre d'ennemis par paquet - défaut : 5
- `spawn_interval` : Intervalle entre chaque spawn dans un paquet (secondes) - défaut : 0.5

**Cycle de 5 vagues :**
- **Vague 1** : n ennemis, n simultanés
- **Vague 2** : n+2 ennemis, n+2 simultanés
- **Vague 3** : n+2 ennemis, n+4 simultanés
- **Vague 4** : n+4 ennemis, n+4 simultanés, tous types
- **Vague 5** : n+2 ennemis, n+2 simultanés, +25% PV/dégâts, timer × 0.8

**Progression inter-cycles :**
- Après chaque cycle de 5 vagues : n augmente de +1, timer diminue de 1s (minimum 5s)

**Système de spawn :**
- Spawn par paquets progressifs (respecte la limite simultanée)
- 4 zones de spawn (`SpawnPointZone1` à `SpawnPointZone4`)
- Sélection aléatoire du type d'ennemi et de la zone
- Respawn intelligent : quand il reste 15% d'ennemis, nouveaux paquets si possible

**SpawnPoint :**
- **Scene :** `Enemy/SpawnPoint.tscn`
- **Paramètres :** `zone_id` (1-4), `spawn_radius` (rayon de spawn), `editor_color` (gizmo éditeur)
- **Fonction :** `get_spawn_position()` retourne une position aléatoire dans le rayon

### Vol des Papillons
**Principe :** Raycast vertical pour suivre le sol + interpolation vers une
hauteur cible, avec oscillation sinus.

**Pipeline :**
1. Raycast vers le bas (`max_hover_ray_distance`) pour détecter le sol
   (filtré par `hover_collision_mask`).
2. Hauteur cible = `sol + hover_height + sin(float_timer) * float_amplitude`.
3. Interpolation `lerp` contrôlée par `hover_follow_speed` après
   `move_and_slide()`.
4. Gravité appliquée (`gravity_scale`), retombée naturelle si aucun sol
   détecté.

**Paramètres exportés :**
- `hover_height`, `float_amplitude`, `float_speed`
- `hover_strength`, `hover_damping`, `hover_follow_speed`
- `gravity_scale`, `max_hover_ray_distance`, `hover_collision_mask`

### Système d'Interaction
**Architecture basée sur signaux et identifiants** pour objets interactifs
réutilisables (interrupteurs, pièges, etc.)

**Principe :**
- Chaque objet interactif est **autonome** et gère sa propre détection via
  **Area3D**
- Communication via **signaux** avec identification unique (ID)
- Le joueur centralise l'affichage des textes dans un dictionnaire

**Interrupteur de Vagues** (`Interrupteur/interrupteur.gd`)
- Hérite directement de `StaticBody3D` (autonome, pas de classe de base)
- Utilise `Area3D` nommé `InteractionArea` pour détecter le joueur
- Paramètre exporté : `interrupteur_id` (ex: `"start_wave"`) pour identification unique
- **Signaux :**
  - `interaction_state_changed(interrupteur_id: String, is_active: bool)` : Pour le HUD du joueur
	- Émet `true` quand le joueur entre dans la zone (si interaction possible)
	- Émet `false` quand le joueur sort ou quand l'interaction est désactivée
  - `wave_started()` : Pour déclencher une vague dans `world.gd`
- **2 états :** `OffWave` (prêt) et `InWave` (vague en cours)
- Sprite 2D avec 2 animations affiché sur le dessus du pavé 3D
- Gère directement l'input E pour déclencher l'action
- S'ajoute au groupe `"interrupteurs"` pour être détecté par le joueur et `world.gd`
- **Connexion automatique :** `world.gd` cherche tous les interrupteurs du groupe et se connecte au signal `wave_started`

**Gestion côté Joueur** (`Player/player.gd`)
- Dictionnaire exporté `interaction_texts` : mappe les IDs aux textes
  d'affichage
  - Exemple : `{"start_wave": "Appuyez sur E pour lancer la vague"}`
  - Modifiable dans l'éditeur, facilement extensible
- Dans `_ready()` : cherche tous les objets du groupe `"interrupteurs"` et
  se connecte à leurs signaux
- Gestionnaire `_on_interaction_state_changed(interrupteur_id, is_active)` :
  - Cherche le texte correspondant dans `interaction_texts[interrupteur_id]`
  - Affiche/cache le label avec transition douce (lerp d'opacité)
  - Texte par défaut si l'ID n'existe pas dans le dictionnaire

**HUD Interface :**
- Conteneur `UI_Interactions` dans `HUD_Layer` (organisé pour extensions futures)
- Label `InteractLabel` : affiche le texte quand `is_active = true`
- Transition douce d'apparition/disparition (lerp dans `_process()`)
- Intégré à l'interface du casque high-tech du joueur (esthétique diégétique)

**HUD Vagues (intégré dans `player.gd`) :**
- `WaveCounter` : Affiche le numéro de vague actuel ("Vague X")
- `EnemiesCounter` : Affiche "Ennemis : X/Y" (ennemis vivants / total de la vague)
- `Timer` : Affiche le temps restant ("Temps : X")
- Mise à jour automatique via `world.gd` :
  - `update_wave_counter(wave_number)` : Met à jour le numéro de vague
  - `update_enemies_counter(enemies_count, max_enemies)` : Met à jour le compteur d'ennemis
  - `update_timer_counter(timer_value)` : Met à jour le timer

**Créer un nouvel objet interactif :**
1. Créer un script qui hérite de `StaticBody3D` (ou autre selon besoin)
2. Ajouter une `Area3D` nommée `InteractionArea` comme enfant
3. Paramètre exporté `interrupteur_id: String` (ex: `"open_door"`)
4. Signal `interaction_state_changed(interrupteur_id: String, is_active: bool)`
5. Gérer la détection joueur (`body_entered`/`body_exited`) et émettre le
   signal
6. S'ajouter au groupe `"interrupteurs"`
7. Gérer l'input E localement pour déclencher l'action
8. Dans le joueur, ajouter l'entrée dans `interaction_texts` :
   `{"open_door": "Appuyez sur E pour ouvrir"}`

---

## 🎮 ENNEMIS - DÉTAILS

### PapillonV1 (Volant Léger)
- **75 PV** | **10 dégâts** | **Vitesse 1.0x**
- Flottement paisible (speed 1.5) + suivi du sol (raycast) pour rester à
  `hover_height`
- Couleurs : Bleu, Cyan, Rose, Jaune

### PapillonV2 (Volant Agressif)
- **75 PV** | **20 dégâts** | **Vitesse 1.5x**
- Flottement rapide (speed 3.0) + même logique de suivi du sol
- Couleurs : Orange, Rouge, Jaune-orange

### BigMonsterV1 (Terrestre Équilibré)
- **62 PV** | **20 dégâts** | **Vitesse 1.0x**
- Gravité active (`gravity_scale` configurable) : retombe naturellement
  après un spawn en suspension
- Animation : Animation de marche disponible (26 frames) mais actuellement statique
- Couleurs : Rouge foncé, Orange, Brun
- **Mort** : Dissolution pixelisée (shader commun, tween 0.45s,
  `death_pixel_size = 156`)
- **Mort (FX)** : Lancement automatique du shader `pixel_dissolve.gdshader`
  (palette ennemie) avec tween Godot `create_tween()`

### BigMonsterV2 (Tank Lourd)
- **62 PV** | **30 dégâts** | **Vitesse 0.75x**
- Gravité active + même logique de retombée contrôlée que V1
- Animation : 26 frames de marche
- Couleurs : Violet foncé, Gris
- **Mort** : Dissolution pixelisée (mêmes paramètres éditables que V1)
- **Mort (FX)** : Même pipeline shader/tween que V1 (`dissolve_amount` +
  `pixel_size` sur 0.45s, `death_pixel_size = 156`)

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
- **Ennemis concernés** : Papillon V1/V2, BigMonster V1/V2 (paramètres
  éditables par variant)
- **Paramètres principaux** : `dissolve_amount` (0→1), `pixel_size`
  (1→N selon taille sprite), `edge_glow`, `edge_color`
- **Tween** : `create_tween()` anime dissolution + pixellisation, `queue_free()` à la fin
  - **BigMonster V1/V2** : 0.45s, `pixel_size = 156`
  - **PapillonV1** : 0.45s, `pixel_size = 26`
  - **PapillonV2** : 0.4s, `pixel_size = 30`
- **Palette** : Couleurs d'impact de l'ennemi (4 teintes exportées) injectées dans le shader via `edge_color`

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
/Player/          - Composants joueur (4 scripts modulaires : Camera,
					Movement, Combat, Input) + player.gd (orchestrateur +
					gestion interactions + HUD)
/Enemy/           - EnemyBase + 4 ennemis (Papillon V1/V2, BigMonster
					V1/V2) + SpawnPoint
/Revolver/        - Script arme
/Interrupteur/    - interrupteur.gd (interrupteur de vagues autonome)
/Effects/         - ImpactEffect (particules) + Shaders (pixel_dissolve)
/Maps/            - Arena + Obstacles (glb)
/Assets/          - Audio, Sprites, Fonts
world.gd          - Script système de vagues (attaché à world.tscn)
world.tscn        - Scène principale (World + Player + SpawnPoints + Interrupteur)
```

---

**Voir aussi :**
- `Doc_Game_Design.md` - Concept et gameplay
- `Doc_Roadmap.md` - Roadmap et état du projet

---
