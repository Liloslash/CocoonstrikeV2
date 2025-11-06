extends "res://Enemy/enemy_base.gd"

# === BIG MONSTER V1 ===
# Ennemi terrestre commun - équilibré entre vitesse et résistance
# 125 PV, vitesse moyenne, 20 dégâts au joueur

# === PARAMÈTRES EXPORTÉS SPÉCIFIQUES AU BIG MONSTER V1 ===
@export_group("BigMonster V1 - Statistiques")
@export var big_monster_v1_max_health: int = 125

@export_group("BigMonster V1 - Mouvement")
@export var big_monster_v1_movement_speed: float = 1.0  # Vitesse moyenne de référence

@export_group("BigMonster V1 - Attaque")
@export var big_monster_v1_damage_dealt: int = 20  # Dégâts modérés au joueur

@export_group("BigMonster V1 - Physique")
@export var big_monster_v1_gravity_scale: float = 1.2  # Gravité normale pour rester au sol

@export_group("BigMonster V1 - Couleurs d'Impact")
@export var impact_color_1: Color = Color(0.8, 0.2, 0.2, 1)    # Rouge foncé
@export var impact_color_2: Color = Color(0.9, 0.4, 0.1, 1)    # Orange
@export var impact_color_3: Color = Color(0.7, 0.1, 0.1, 1)    # Rouge très foncé
@export var impact_color_4: Color = Color(0.5, 0.3, 0.1, 1)    # Brun

@export_group("BigMonster V1 - Ombre Portée")
@export var big_monster_v1_shadow_size: float = 0.42  # Taille de l'ombre (multiplicateur)
@export var big_monster_v1_shadow_opacity: float = 0.384  # Opacité de l'ombre (0.0 à 1.0)

# === VARIABLES SPÉCIFIQUES AU BIG MONSTER V1 ===
var gravity: float  # Gravité pour ce monstre
var initial_position: Vector3  # Position initiale définie dans la scène

# === MÉTHODES VIRTUELLES SURCHARGÉES ===

func _on_enemy_ready():
	# Initialisation spécifique au BigMonster V1
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * big_monster_v1_gravity_scale
	
	# Configuration des collisions spécifique au monstre terrestre
	collision_layer = 2  # Ennemi sur la layer 2 (détectable par raycast)
	collision_mask = 3   # Détecte la layer 0 (environnement) + layer 1 (joueur)
	
	# Override des valeurs d'EnemyBase avec celles du BigMonster V1
	max_health = big_monster_v1_max_health
	current_health = max_health
	base_damage_dealt = big_monster_v1_damage_dealt
	movement_speed_multiplier = big_monster_v1_movement_speed
	shadow_size = big_monster_v1_shadow_size
	shadow_opacity = big_monster_v1_shadow_opacity
	# Réappliquer la configuration de l'ombre avec la nouvelle taille
	_setup_shadow()
	
	# Sauvegarder la position initiale définie dans la scène
	initial_position = global_position
	
	# NE PAS modifier la position Y - garder celle de la scène
	# (le code forçait Y=0.75 ce qui surélevait l'ennemi)
	
	# Démarrer l'animation de marche en permanence
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("BigMonsterV1IdleAnim"):
		sprite.play("BigMonsterV1IdleAnim")

func _on_physics_process(_delta: float):
	# Physique spécifique au BigMonster V1 (terrestre, reste au sol)
	
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
	# Réactions spécifiques aux dégâts du BigMonster V1 (pour l'instant, rien de spécial)
	pass

func _on_death():
	# Effets de mort spécifiques au BigMonster V1 (pour plus tard)
	pass

# === MÉTHODE SPÉCIFIQUE AU BIG MONSTER V1 ===
# Cette méthode sera utilisée par PlayerCombat pour récupérer les couleurs d'impact
func get_impact_colors() -> Array[Color]:
	# Retourne les 4 couleurs d'impact du BigMonster V1 (tons rouge/orange/brun)
	return [impact_color_1, impact_color_2, impact_color_3, impact_color_4]
