# 🚀 ROADMAP - COCOONSTRIKE REBUILD

---

## 🔥 PRIORITÉS CRITIQUES

### 1. 🎯 **NOUVELLES TÂCHES PRIORITAIRES**

#### **A. Synchronisation Raycast/Caméra pendant le Saut**
- **Problème** : Le raycast ne suit pas l'angle de la caméra pendant le saut
- **Objectif** : Tirer en suivant l'angle de la caméra pendant l'effet "Jump Look Down"
- **Impact** : 🟡 **MOYEN** - Améliore la précision de tir en saut

#### **B. Conceptualisation du Système de Vagues**
- **Objectif** : Définir avec Cursor l'architecture du système de vagues
- **Contenu** : Générateur, difficulté progressive, types d'ennemis
- **Impact** : 🔴 **ÉLEVÉ** - Système central du gameplay

#### **C. Création des Ennemis Papillons**
- **Objectif** : Créer les deux variantes de papillons (Chaser et Peintre)
- **Note** : Comportements à implémenter plus tard
- **Impact** : 🟡 **MOYEN** - Base pour le système d'ennemis

### 2. 🚨 **PATHFINDING VRAI** - NavigationMesh non fonctionnelle !
**Problème actuel :**
- NavigationMesh reste vide (pas de grille bleue visible)
- NavigationAgent3D inutile (next_path_position = même position)
- Système actuel = simple évitement basique (raycast + tourner à droite)

**Objectif :**
- Implémenter du vrai pathfinding avec NavigationMesh fonctionnelle
- NavigationRegion3D correctement configurée
- Ennemis qui suivent des chemins intelligents
- Évitement d'obstacles avancé

**Impact :** 🟡 **MOYEN** - Améliore l'IA des ennemis mais le système actuel fonctionne

### 2. 🎵 **SONS SUPPLÉMENTAIRES** - Audio manquant
**À implémenter :**
- Sons de pas du joueur
- Sons d'impact du slam
- Sons de dégâts/mort des ennemis
- Audio ambiant

**Impact :** 🟢 **FAIBLE** - Améliore l'immersion mais pas critique

### 3. 🤖 **COMPORTEMENT ENNEMI** - Améliorations
**À implémenter :**
- Shaking lors des dégâts
- Mort plus recherchée (animations, effets)
- Comportements variés selon le type d'ennemi

**Impact :** 🟢 **FAIBLE** - Améliore le feedback visuel

---

## 📋 PRIORITÉS ACTUELLES

### 🔄 **EN COURS**
- Synchronisation Raycast/Caméra pendant le saut
- Conceptualisation du système de vagues avec Cursor
- Création des deux ennemis papillons (comportements plus tard)
- Amélioration du système d'évitement d'obstacles

### ❌ **À IMPLÉMENTER**
- Collectibles et pièges
- Audio ambiant
- Polissage final

---

## 🎯 OBJECTIFS À COURT TERME

### **Phase 1 : Pathfinding (1-2 semaines)**
1. **NavigationMesh** : Configuration correcte de la zone navigable
2. **NavigationAgent3D** : Implémentation du pathfinding réel
3. **Tests** : Vérification du comportement des ennemis
4. **Optimisation** : Performance du pathfinding

### **Phase 2 : Audio (1 semaine)**
1. **Sons de pas** : Intégration avec le système de mouvement
2. **Sons d'impact** : Slam, dégâts, mort
3. **Audio ambiant** : Ambiance sonore de base

### **Phase 3 : Polissage (1-2 semaines)**
1. **Comportement ennemis** : Améliorations visuelles
2. **Collectibles** : Système de collecte
3. **Pièges** : Mécaniques de défense
4. **Tests finaux** : Équilibrage et bugs

---

## 🏆 OBJECTIFS À LONG TERME

### **Système de Vagues**
- Générateur de vagues d'ennemis
- Difficulté progressive
- Types d'ennemis variés

### **Système de Progression**
- Collectibles avec effets
- Améliorations d'armes
- Système de score

### **Polissage Final**
- Interface utilisateur
- Menus et options
- Effets visuels avancés

---

## 📈 MÉTRIQUES DE SUCCÈS

### **Performance**
- 60 FPS stable
- Pathfinding fluide (max 10 ennemis simultanés)
- Chargement rapide des scènes

### **Gameplay**
- Contrôles responsifs
- Feedback visuel/audio cohérent
- Progression claire

### **Code**
- Architecture maintenable
- Tests robustes
- Documentation à jour

---

## 📊 SYSTÈMES TERMINÉS

### ✅ **MÉCANIQUES DE CAMÉRA** - Système complet et réaliste !
- ✅ **Head Bob réaliste** avec transitions fluides
- ✅ **Camera Shake combiné** (tremblements multiples)
- ✅ **Effet de caméra "Jump Look Down"** (25° d'inclinaison)
- ✅ **Recoil avancé** avec variation aléatoire
- ✅ **Kickback** (recul vers l'arrière)
- ✅ **Optimisations** : Cache de références pour performance

### ✅ **SWAY DYNAMIQUE DU REVOLVER** - Système complet !
- ✅ **Sway idle** : Mouvement circulaire subtil (X=2.0, Y=0.5, Z=0.5 à 1.0 Hz)
- ✅ **Sway movement** : Pattern de course réaliste (X=9.0, Y=1.0, Z=2.0 à 5.0 Hz)
- ✅ **Transitions fluides** entre idle/movement avec interpolation
- ✅ **Communication temps réel** avec le joueur
- ✅ **Intégration** : Arrêt pendant tir/rechargement, reprise automatique
- ✅ **Paramètres ajustables** dans l'éditeur

### ✅ **SYSTÈME DE MOUVEMENT** - Optimisé !
- ✅ **Mouvement FPS** : ZQSD + souris
- ✅ **Saut simplifié** : Hauteur 3.3m, calcul automatique de vélocité
- ✅ **Slam aérien** : A en l'air, vitesse -33.0
- ✅ **Freeze après slam** : 0.3s de gel
- ✅ **Accélération** : 0.4s pour atteindre la vitesse max

### ✅ **SYSTÈME DE COMBAT** - Complet !
- ✅ **Revolver** : 6 balles, rechargement fluide, sons
- ✅ **Raycast** : Détection d'ennemis (collision_mask = 2)
- ✅ **Dégâts** : 25 points par tir
- ✅ **Effets d'impact** : Particules colorées dynamiques
- ✅ **Tremblement d'arme** : Rechargement + clic vide
- ✅ **Sons optimisés** : Superposition, fonction commune

### ✅ **ARCHITECTURE MODULAIRE** - Refactorisée !
- ✅ **PlayerCamera.gd** (278 lignes) : Gestion complète de la caméra
- ✅ **PlayerMovement.gd** (194 lignes) : Mouvement et saut
- ✅ **PlayerCombat.gd** (122 lignes) : Tir et raycast
- ✅ **PlayerInput.gd** (54 lignes) : Gestion des inputs
- ✅ **player.gd** (84 lignes) : Orchestrateur optimisé
- ✅ **Communication robuste** : Signaux et références directes
- ✅ **Performance** : Cache de références, early returns

---

*Dernière mise à jour : Décembre 2024*
