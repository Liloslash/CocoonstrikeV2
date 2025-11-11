extends "res://Enemy/enemy_base.gd"

const DISSOLVE_SHADER = preload("res://Effects/Shaders/pixel_dissolve.gdshader")

# === PAPILLON V2 ===
# Ennemi volant plus agressif que le V1
# Même PV mais flottement plus rapide, déplacement 1.5× plus rapide, dégâts 2× plus importants

# === PARAMÈTRES EXPORTÉS SPÉCIFIQUES AU PAPILLON V2 ===
@export_group("Papillon V2 - Statistiques")
@export var papillon_max_health: int = 75

@export_group("Papillon V2 - Mouvement")
@export var papillon_v2_movement_speed: float = 1.5

@export_group("Papillon V2 - Attaque")
@export var papillon_v2_damage_dealt: int = 20

@export_group("Papillon V2 - Vol")
@export var hover_height: float = 1.2
@export var float_amplitude: float = 0.15
@export var float_speed: float = 3.0
@export var hover_strength: float = 10.0
@export var hover_damping: float = 0.9
@export var gravity_scale: float = 1.0
@export var max_hover_ray_distance: float = 10.0
@export var hover_follow_speed: float = 7.5
@export_flags_3d_physics var hover_collision_mask: int = 1

@export_group("Papillon V2 - Couleurs d'Impact")
@export var impact_color_1: Color = Color(1.0, 0.4, 0.2, 1)
@export var impact_color_2: Color = Color(1.0, 0.0, 0.2, 1)
@export var impact_color_3: Color = Color(1.0, 0.7, 0.0, 1)
@export var impact_color_4: Color = Color(1.0, 0.5, 0.0, 1)

@export_group("Papillon V2 - Ombre Portée")
@export var papillon_v2_shadow_size: float = 0.75
@export var papillon_v2_shadow_opacity: float = 0.384

# === VARIABLES SPÉCIFIQUES AU PAPILLON V2 ===
var gravity: float
var float_timer: float = 0.0
var has_ground_contact: bool = false
var desired_height: float = 0.0
@onready var dissolve_material: ShaderMaterial = null
var _dissolve_connection_established: bool = false
var _dissolve_tween: Tween = null

# === MÉTHODES VIRTUELLES SURCHARGÉES ===

func _on_enemy_ready():
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_scale
	
	collision_layer = 2
	collision_mask = 3
	
	max_health = papillon_max_health
	current_health = max_health
	base_damage_dealt = papillon_v2_damage_dealt
	movement_speed_multiplier = papillon_v2_movement_speed
	shadow_size = papillon_v2_shadow_size
	shadow_opacity = papillon_v2_shadow_opacity
	_setup_shadow()
	
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("PapillonV2IdleAnim"):
		sprite.play("PapillonV2IdleAnim")
	
	if sprite:
		dissolve_material = ShaderMaterial.new()
		dissolve_material.shader = DISSOLVE_SHADER
		var average_color: Color = (impact_color_1 + impact_color_2 + impact_color_3 + impact_color_4) / 4.0
		dissolve_material.set_shader_parameter("dissolve_amount", 0.0)
		dissolve_material.set_shader_parameter("pixel_size", 1.0)
		dissolve_material.set_shader_parameter("edge_glow", 1.6)
		dissolve_material.set_shader_parameter("edge_color", Vector3(average_color.r, average_color.g, average_color.b))
		sprite.material_override = dissolve_material
		_update_dissolve_texture()
		if not _dissolve_connection_established:
			sprite.frame_changed.connect(_update_dissolve_texture)
			_dissolve_connection_established = true

func _on_physics_process(delta: float):
	float_timer += delta * float_speed
	var hover_offset: float = sin(float_timer) * float_amplitude
	
	var ray_start: Vector3 = global_position + Vector3.UP * 0.5
	var ray_end: Vector3 = global_position + Vector3.DOWN * max_hover_ray_distance
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	has_ground_contact = false
	desired_height = global_position.y + hover_offset
	
	if space_state:
		var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		query.collision_mask = hover_collision_mask
		query.exclude = [get_rid()]
		var result := space_state.intersect_ray(query)
		if result:
			var hit_position: Vector3 = result.position
			desired_height = hit_position.y + hover_height + hover_offset
			has_ground_contact = true
	
	velocity.y -= gravity * delta
	
	move_and_slide()
	
	if has_ground_contact:
		var t: float = clamp(hover_follow_speed * delta, 0.0, 1.0)
		global_position.y = lerp(global_position.y, desired_height, t)
		velocity.y = 0.0

func _on_damage_taken(_damage: int):
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
	_dissolve_tween.tween_property(dissolve_material, "shader_parameter/dissolve_amount", 1.0, 0.4)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
	_dissolve_tween.tween_property(dissolve_material, "shader_parameter/pixel_size", 30.0, 0.4)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	_dissolve_tween.finished.connect(func():
		if is_instance_valid(sprite):
			sprite.visible = false
		queue_free()
	)
	
	return true

func get_impact_colors() -> Array[Color]:
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
