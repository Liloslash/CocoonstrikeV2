# 🎮 COCOONSTRIKE - MORTAL BUTTERFLIES
## Documentation Complète du Projet

---

## 📋 **INFORMATIONS GÉNÉRALES**

- **Nom du Projet :** Cocoonstrike - Mortal Butterflies
- **Moteur :** Godot Engine v4.4.1.stable.official
- **Type :** FPS Survival Shooter 3D avec sprites 2D
- **Style :** Pixel Art / Rétro
- **Plateforme :** PC (Windows)
- **Dernière Mise à Jour :** Décembre 2024

---

## 🎯 **CONCEPT DU JEU**

**Cocoonstrike** est un **survival shooter FPS** basé sur un prototype de la Godot Wild Jam. Le jeu se déroule sur une map 3D unique composée de deux zones : **Arena** et **Obstacles**. 

### **Gameplay Prévu :**
- Le joueur commence au centre de la map
- Il active un déclencheur pour lancer les vagues d'ennemis
- **Objectif :** survivre le plus longtemps possible
- Entre les vagues : collecte d'objets, pose de pièges, blocage d'accès
- Instanciation dynamique des ennemis par vagues

---

## 🏗️ **ARCHITECTURE TECHNIQUE**

### **Structure des Scènes :**

```
World (Node principal)
├── Arena (Node3D) - Zone d'arène
├── Obstacles (Node3D) - Zone d'obstacles  
├── WorldEnvironment3D - Éclairage et ciel
├── Player (CharacterBody3D) - Joueur principal
└── Enemy (CharacterBody3D) - Ennemi (instancié manuellement pour tests)
```

### **Scene Player :**
```
Player (CharacterBody3D)
├── Camera3D
│   └── RayCast3D (collision_mask = 2)
├── CollisionShape3D (CapsuleShape3D)
├── AudioStreamPlayer3D (bruits de pas - non implémenté)
└── HUD_Layer (CanvasLayer)
    └── Revolver (AnimatedSprite2D)
        └── AnimationPlayer (Sway_Idle)
```

### **Scene Enemy :**
```
Enemy (CharacterBody3D)
├── AnimatedSprite3D (billboard activé)
├── CollisionShape3D (collisions environnement)
└── Area3D (détection/dégâts)
    └── CollisionShape3D
```

---

## ⚙️ **FONCTIONNALITÉS IMPLÉMENTÉES**

### ✅ **SYSTÈME DE JOUEUR (Player)**

#### **Mouvement FPS :**
- **Contrôles :** WASD + Souris
- **Saut :** Espace (jump_velocity = 5.8)
- **Slam :** Q (slam_velocity = -33.0)
- **Accélération progressive** (acceleration_duration = 0.4s)
- **Freeze après slam** (freeze_duration_after_slam = 0.3s)

#### **Effets Visuels :**
- **Camera Shake :** Tremblement avec EaseOutElastic
- **Head Bob :** Mouvement de tête pendant la marche
- **Recoil :** Effet de recul lors du tir
- **Kickback :** Recul de la caméra vers l'arrière

#### **Système de Combat :**
- **RayCast3D** configuré sur collision_mask = 2
- **Dégâts unifiés :** 25 points par tir
- **Signal shot_fired** du revolver connecté
- **Effet d'impact** avec particules colorées

### ✅ **SYSTÈME DE REVOLVER**

#### **Munitions :**
- **Capacité :** 6 balles maximum
- **Rechargement :** Animation fluide avec sons
- **Cadence :** 0.3s entre les tirs
- **États :** IDLE, RELOAD_STARTING, RELOAD_ADDING_BULLETS, RELOAD_INTERRUPTED

#### **Audio :**
- **Sons séparés :** Tir, rechargement, clic vide
- **Superposition :** Possibilité de jouer plusieurs sons simultanément
- **Sons utilisés :** GunShot-2.mp3, OpenRevolverBarrel.mp3, AddRevolverBullet.mp3, CloseRevolverBarrel.mp3, AOARevolver.mp3

#### **Animations :**
- **Tween :** Mouvements fluides de position
- **AnimationPlayer :** Sway_Idle (balancement)
- **SpriteFrames :** 11 frames d'animation de tir

### ✅ **SYSTÈME D'ENNEMIS**

#### **Statistiques :**
- **Vie :** 100 points (configurable)
- **Collision Layer :** 2 (détectable par raycast)
- **Vitesse :** 3.0 (non utilisée actuellement)
- **Portée de détection :** 15.0 (non utilisée actuellement)

#### **Comportement :**
- **États :** Vivant/mort, gelé/actif
- **Système de mort :** Freeze pendant 1 seconde puis disparition
- **Désactivation des collisions** à la mort

#### **Couleurs d'Impact :**
- **4 couleurs exportables** dans l'inspecteur
- **Couleurs par défaut :** Rouge clair, Vert, Violet, Noir
- **Méthode get_impact_colors()** pour récupérer les couleurs

### ✅ **SYSTÈME D'EFFETS D'IMPACT**

#### **ImpactEffect (Nouveau !) :**
- **GPUParticles3D** avec cubes 3D
- **4 couleurs simultanées** par impact
- **Effet localisé** et court (0.4s)
- **32 particules** réparties sur 4 systèmes
- **Taille des cubes :** 0.056 (réduite d'un quart)
- **Force d'explosion :** 3.0-6.0 (localisée)

#### **Configuration :**
- **Durée :** 0.4 secondes
- **Particules :** 32 cubes 3D
- **Couleurs :** Récupérées depuis l'ennemi touché
- **Physique :** Pas de gravité, explosion dans toutes les directions

---

## 🎨 **ASSETS ET RESSOURCES**

### **Audio :**
- **Guns :** 8 sons de revolver (tir, rechargement, clic vide)
- **Enemies :** Sons de pas lourds, rugissements, battements d'ailes
- **Player :** Bruits de pas, battements de cœur, cris
- **UI :** Sons de bonus, compte à rebours, succès
- **Musique :** Metalcore.mp3

### **Sprites :**
- **Ennemis :** BigMonsterV1/V2, PapillonV1/V2 (128x128)
- **Armes :** Revolver.png, TurboGun.png
- **UI :** Heart.png (icône de vie)

### **Environnements :**
- **Arena :** Arena.glb avec textures floor/wall
- **Obstacles :** Obstacles.glb avec textures floor/wall
- **Ciel :** ProceduralSkyMaterial avec couleurs sombres

---

## 🔧 **CONFIGURATION TECHNIQUE**

### **Input Map :**
- **ESC :** Libérer la souris
- **WASD :** Mouvement
- **Espace :** Saut
- **Q :** Slam
- **Clic gauche :** Tir
- **R :** Rechargement

### **Collision Layers :**
- **Layer 0 :** Environnement
- **Layer 1 :** Joueur
- **Layer 2 :** Ennemis (détectable par raycast)

### **Rendering :**
- **Mode :** GL Compatibility
- **Filtrage :** Nearest (pixel art)
- **Ciel :** ProceduralSkyMaterial

---

## 🚀 **ROADMAP ET AMÉLIORATIONS**

### **Priorité HAUTE :**
1. **✅ Système de collisions** - CONFIGURÉ
2. **✅ Effets d'impact** - IMPLÉMENTÉ
3. **🔄 Tir des ennemis** - Système similaire au joueur
4. **🔄 Pathfinding** - IA de déplacement des ennemis

### **Priorité MOYENNE :**
5. **Système de vagues** - Spawning dynamique d'ennemis
6. **Collectibles** - Objets à ramasser entre les vagues
7. **Pièges/Barricades** - Mécaniques défensives
8. **Audio ambiant** - Bruits de pas, sons d'ambiance

### **Priorité BASSE :**
9. **Polissage** - Effets visuels supplémentaires
10. **Optimisation** - Performance et mémoire
11. **UI/UX** - Interface utilisateur améliorée
12. **Sons d'ambiance** - Immersion audio

---

## 📊 **ÉTAT ACTUEL DU PROJET**

### **✅ FONCTIONNEL :**
- ✅ Player complet (mouvement, tir, effets)
- ✅ Revolver complet (animations, sons, munitions)
- ✅ Enemy basique (vie, dégâts, mort)
- ✅ Système de collisions configuré
- ✅ Effets d'impact pixel explosion

### **🔄 EN COURS :**
- 🔄 IA ennemis (pathfinding, tir)
- 🔄 Système de vagues

### **❌ À IMPLÉMENTER :**
- ❌ Collectibles et pièges
- ❌ Audio ambiant
- ❌ Polissage final

---

## 🎯 **POINTS TECHNIQUES IMPORTANTS**

### **Performance :**
- **Une seule map** pour optimiser les performances
- **Sprites 2D billboard** pour les ennemis (performance)
- **GPUParticles3D** pour les effets d'impact
- **Système de sons optimisé** avec superposition

### **Game Design :**
- **Survival shooter** avec vagues d'ennemis
- **Pixel art** dans un monde 3D
- **Effets visuels punchy** et satisfaisants
- **Système de progression** entre les vagues

### **Code Quality :**
- **Scripts modulaires** et bien documentés
- **Variables exportables** pour le tuning
- **Signals** pour la communication entre nodes
- **Gestion d'erreurs** robuste

---

## 🏆 **CONCLUSION**

Le projet **Cocoonstrike - Mortal Butterflies** est dans un **excellent état** avec toutes les fonctionnalités de base implémentées et fonctionnelles. Le système d'effets d'impact récemment ajouté apporte une **satisfaction visuelle** importante au gameplay.

**Prochaines étapes prioritaires :**
1. Implémenter l'IA des ennemis
2. Créer le système de vagues
3. Ajouter les collectibles et pièges

Le projet est **prêt pour la phase de développement avancé** ! 🚀✨

---

*Documentation générée le 19 décembre 2024*
*Projet développé avec Godot Engine v4.4.1*

