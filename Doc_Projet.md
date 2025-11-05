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
| **BigMonsterV1** | Terrestre | 125 | 20 | 1.0x |
| **BigMonsterV2** | Terrestre | 155 | 30 | 0.75x |

**EnemyBase inclut :**
- Système vie/dégâts/mort
- Effets visuels (rougissement, vibration)
- Repoussement slam
- Rotation auto vers joueur

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

### Vol des Papillons
**Formule :** `Y = base + flight_height + sin(timer * speed) * amplitude`

**Paramètres :**
- **flight_height** : 0.2m (hauteur de base)
- **float_amplitude** : 0.15m (oscillation)
- **float_speed** : 1.5 (V1) / 3.0 (V2)

---

## 🎮 ENNEMIS - DÉTAILS

### PapillonV1 (Volant Léger)
- **75 PV** | **10 dégâts** | **Vitesse 1.0x**
- Flottement paisible (speed 1.5)
- Couleurs : Bleu, Cyan, Rose, Jaune

### PapillonV2 (Volant Agressif)
- **75 PV** | **20 dégâts** | **Vitesse 1.5x**
- Flottement rapide (speed 3.0)
- Couleurs : Orange, Rouge, Jaune-orange

### BigMonsterV1 (Terrestre Équilibré)
- **125 PV** | **20 dégâts** | **Vitesse 1.0x**
- Reste au sol (Y=0.75)
- Animation : 1 frame statique
- Couleurs : Rouge foncé, Orange, Brun

### BigMonsterV2 (Tank Lourd)
- **155 PV** | **30 dégâts** | **Vitesse 0.75x**
- Reste au sol (Y=0.75)
- Animation : 26 frames de marche
- Couleurs : Violet foncé, Gris

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
/Enemy/           - EnemyBase + 4 ennemis + EnemyTest
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
