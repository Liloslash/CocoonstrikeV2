# 🚀 ROADMAP - COCOONSTRIKE REBUILD

## 🔥 SUR LE FEU (En cours)
- Sons de dégâts des ennemis

## ⚡ COURT TERME (1-2 semaines)
- Création de la mécanique de super shot pour le revolver
- Amélioration du système de repoussement slam
- Création du système de canal pour gérer l'audio
- Implémentation des bruits de pas du player
- Bruits de pas des ennemis

## 📅 MOYEN TERME 
- Redesign de la map avec obstacles aux particularités spécifiques
- Implémentation du nouveau système d'IA pour les ennemis
- Tests et équilibrage du gameplay
- Refonte esthétique du revolver (nouveau sprite)
- Réflexion direction artistique générale et moyens graphiques

## 🎯 LONG TERME 
- Création d'un écran titre
- Création d'un menu de pause
- Création du HUD Player
- Créations de ressources pour l'habillage de la map
- Création d'un tableau des scores

## ✅ ACCOMPLIS
- Système de vagues d'ennemis
- implmémentation de l'interrupteur de vagues
- Création d'une animation de mort pour l'ennemi
- Création des 4 points d'apparitions sur la map
- Création de "l'ombre" pour les enemies 
- Création des 6 ennemis spécifiques (PapillonV1/V2, MonsterV1/V2,
  BigMonsterV1/V2)
- Architecture modulaire du joueur (PlayerCamera, PlayerMovement,
  PlayerCombat, PlayerInput)
- Système de sway dynamique du revolver et effets de vibration ennemi
- Système de compensation du raycast (synchronisation caméra-raycast)
- Head Bob réaliste et Camera Shake combiné
- Système de saut simplifié avec effet "Jump Look Down"
- Revolver complet (animations, sons, munitions, effets, tremblement clic
  vide)
- Système de combat avec raycast et effets d'impact
- Système d'ennemis de base (vie, dégâts, gravité, repoussement slam)
- Suppression du pathfinding (NavigationAgent3D)
- Système de gravité ennemi (ennemis tombent et interagissent avec
  l'environnement)
- Système de repoussement slam (ennemis bondissent en arrière, rayon 2m)
- Configuration des collision layers (0, 1, 2)
- Variables exportées pour tous les paramètres de repoussement
- Corrections critiques de bugs et erreurs
- Code robuste avec 0 erreur de linter
- Contrôles mis à jour (Slam changé de Q vers A)
- Architecture d'héritage des ennemis (EnemyBase + EnemyTest)
- Refactorisation complète du système d'ennemis
- Bug corrigé : Tir pendant repoussement slam
- Corrections techniques (collision layers, RayCast caméra, double caméra)
- Optimisations mémoire (connexions de signal, await avec gestion
  d'erreur)
- Correction des références UID après renommage

## 🔗 DÉPÔT GITHUB
[https://github.com/Liloslash/CocoonstrikeV2](https://github.com/Liloslash/CocoonstrikeV2) -
Consultez l'historique des commits pour les dates exactes de mise à jour
