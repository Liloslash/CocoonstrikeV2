extends "res://Enemy/enemy_base.gd"

# === BIG MONSTER V2 ===
# Ennemi terrestre tank - plus résistant et dangereux que le V1
# 155 PV, vitesse réduite (-25%), 30 dégâts au joueur

# === PARAMÈTRES EXPORTÉS SPÉCIFIQUES AU BIG MONSTER V2 ===
@export_group("BigMonster V2 - Statistiques")
@export var big_monster_v2_max_health: int = 155

@export_group("BigMonster V2 - Mouvement")
@export var big_monster_v2_movement_speed: float = 0.75  # 25% plus lent que V1 (1.0 → 0.75)

@export_group("BigMonster V2 - Attaque")
@export var big_monster_v2_damage_dealt: int = 30  # 50% plus de dégâts que V1 (20 → 30)

@export_group("BigMonster V2 - Physique")
@export var big_monster_v2_gravity_scale: float = 1.2  # Gravité normale pour rester au sol

@export_group("BigMonster V2 - Couleurs d'Impact")
@export var impact_color_1: Color = Color(0.6, 0.1, 0.8, 1)    # Violet foncé
@export var impact_color_2: Color = Color(0.8, 0.2, 0.9, 1)    # Violet
@export var impact_color_3: Color = Color(0.4, 0.0, 0.6, 1)    # Violet très foncé
@export var impact_color_4: Color = Color(0.3, 0.3, 0.3, 1)    # Gris foncé

@export_group("BigMonster V2 - Ombre Portée")
@export var big_monster_v2_shadow_size: float = 0.42  # Taille de l'ombre (multiplicateur)
@export var big_monster_v2_shadow_opacity: float = 0.384  # Opacité de l'ombre (0.0 à 1.0)

# === VARIABLES SPÉCIFIQUES AU BIG MONSTER V2 ===
var gravity: float  # Gravité pour ce monstre
var initial_position: Vector3  # Position initiale définie dans la scène

# === MÉTHODES VIRTUELLES SURCHARGÉES ===

func _on_enemy_ready():
	# Initialisation spécifique au BigMonster V2
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * big_monster_v2_gravity_scale
	
	# Configuration des collisions spécifique au monstre terrestre
	collision_layer = 2  # Ennemi sur la layer 2 (détectable par raycast)
	collision_mask = 3   # Détecte la layer 0 (environnement) + layer 1 (joueur)
	
	# Override des valeurs d'EnemyBase avec celles du BigMonster V2
	max_health = big_monster_v2_max_health
	current_health = max_health
	base_damage_dealt = big_monster_v2_damage_dealt
	movement_speed_multiplier = big_monster_v2_movement_speed
	shadow_size = big_monster_v2_shadow_size
	shadow_opacity = big_monster_v2_shadow_opacity
	# Réappliquer la configuration de l'ombre avec la nouvelle taille
	_setup_shadow()
	
	# Sauvegarder la position initiale définie dans la scène
	initial_position = global_position
	
	# NE PAS modifier la position Y - garder celle de la scène
	# (le code forçait Y=0.75 ce qui surélevait l'ennemi)
	
	# Démarrer l'animation de marche en permanence (utilise l'animation complexe de BigMonsterV2)
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("BigMonsterV2WalkAnim"):
		sprite.play("BigMonsterV2WalkAnim")

func _on_physics_process(_delta: float):
	# Physique spécifique au BigMonster V2 (terrestre, reste au sol, plus lent)
	
	# Si on est en cours de repoussement slam, appliquer le mouvement puis forcer au sol
	if is_being_slam_repelled:
		# Appliquer le mouvement complet
		move_and_slide()
		# APRÈS le mouvement, restaurer la position Y initiale (pas de saut pour BigMonster)
		global_position.y = initial_position.y
		
		# Si l'ennemi va trop loin, le ramener à sa position initiale
		if global_position.distance_to(initial_position) > 10.0:
			global_position = initial_position
		return
	
	# Maintenir la position Y initiale pour éviter l'enfoncement
	global_position.y = initial_position.y
	velocity = Vector3.ZERO
	
	# Remettre le sprite à sa position d'origine (sauf rotation Y vers le joueur)
	if sprite:
		sprite.position = Vector3.ZERO
		sprite.rotation.x = 0.0
		sprite.rotation.z = 0.0

func _on_damage_taken(_damage: int):
	# Réactions spécifiques aux dégâts du BigMonster V2 (pour l'instant, rien de spécial)
	pass

func _on_death():
	# Effets de mort spécifiques au BigMonster V2 (pour plus tard)
	pass

# === MÉTHODE SPÉCIFIQUE AU BIG MONSTER V2 ===
# Cette méthode sera utilisée par PlayerCombat pour récupérer les couleurs d'impact
func get_impact_colors() -> Array[Color]:
	# Retourne les 4 couleurs d'impact du BigMonster V2 (tons violet/gris)
	return [impact_color_1, impact_color_2, impact_color_3, impact_color_4]
