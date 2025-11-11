extends "res://Enemy/enemy_base.gd"

const DISSOLVE_SHADER = preload("res://Effects/Shaders/pixel_dissolve.gdshader")

# === BIG MONSTER V2 ===
# Ennemi terrestre tank - plus résistant et dangereux que le V1
# 155 PV, vitesse réduite (-25%), 30 dégâts au joueur

# === PARAMÈTRES EXPORTÉS SPÉCIFIQUES AU BIG MONSTER V2 ===
@export_group("BigMonster V2 - Statistiques")
@export var big_monster_v2_max_health: int = 62

@export_group("BigMonster V2 - Dissolution")
@export var death_dissolve_duration: float = 0.45
@export var death_pixel_size: float = 156.0
@export var death_edge_glow: float = 1.0

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
@onready var dissolve_material: ShaderMaterial = null
var _dissolve_connection_established: bool = false
var _dissolve_tween: Tween = null

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
	
	if sprite:
		dissolve_material = ShaderMaterial.new()
		dissolve_material.shader = DISSOLVE_SHADER
		var average_color: Color = (impact_color_1 + impact_color_2 + impact_color_3 + impact_color_4) / 4.0
		dissolve_material.set_shader_parameter("dissolve_amount", 0.0)
		dissolve_material.set_shader_parameter("pixel_size", 1.0)
		dissolve_material.set_shader_parameter("edge_glow", death_edge_glow)
		dissolve_material.set_shader_parameter("edge_color", Vector3(average_color.r, average_color.g, average_color.b))
		sprite.material_override = dissolve_material
		_update_dissolve_texture()
		if not _dissolve_connection_established:
			sprite.frame_changed.connect(_update_dissolve_texture)
			_dissolve_connection_established = true

func _on_physics_process(_delta: float):
	# Physique spécifique au BigMonster V2 (terrestre, reste au sol, plus lent)
	
	# Appliquer la gravité
	velocity.y -= gravity * _delta

	# Si on est en cours de repoussement slam, laisser la physique gérer puis sortir
	if is_being_slam_repelled:
		move_and_slide()
		return
	
	# Le BigMonster V2 reste statique à l'horizontale pour le moment
	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()

	# Éviter les rebonds lorsqu'il touche le sol
	if is_on_floor():
		velocity.y = 0.0
	
	# Remettre le sprite à sa position d'origine (sauf rotation Y vers le joueur)
	if sprite:
		sprite.position = Vector3.ZERO
		sprite.rotation.x = 0.0
		sprite.rotation.z = 0.0

func _on_damage_taken(_damage: int):
	# Réactions spécifiques aux dégâts du BigMonster V2 (pour l'instant, rien de spécial)
	pass

func _on_death():
	if not sprite or dissolve_material == null:
		return false
	
	if _dissolve_connection_established and sprite.frame_changed.is_connected(_update_dissolve_texture):
		sprite.frame_changed.disconnect(_update_dissolve_texture)
		_dissolve_connection_established = false
	
	if _dissolve_tween and _dissolve_tween.is_running():
		_dissolve_tween.kill()
	
	_dissolve_tween = create_tween()
	_dissolve_tween.set_parallel(true)
	_dissolve_tween.tween_property(dissolve_material, "shader_parameter/dissolve_amount", 1.0, death_dissolve_duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
	_dissolve_tween.tween_property(dissolve_material, "shader_parameter/pixel_size", death_pixel_size, death_dissolve_duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	_dissolve_tween.finished.connect(func():
		if is_instance_valid(sprite):
			sprite.visible = false
		queue_free()
	)
	
	return true

# === MÉTHODE SPÉCIFIQUE AU BIG MONSTER V2 ===
# Cette méthode sera utilisée par PlayerCombat pour récupérer les couleurs d'impact
func get_impact_colors() -> Array[Color]:
	# Retourne les 4 couleurs d'impact du BigMonster V2 (tons violet/gris)
	return [impact_color_1, impact_color_2, impact_color_3, impact_color_4]

func _update_dissolve_texture():
	if not sprite or not sprite.sprite_frames or dissolve_material == null:
		return
	var frames: SpriteFrames = sprite.sprite_frames
	var current_animation: StringName = sprite.animation
	var current_frame: int = sprite.frame
	var frame_texture: Texture2D = frames.get_frame_texture(current_animation, current_frame)
	if frame_texture:
		dissolve_material.set_shader_parameter("texture_albedo", frame_texture)
