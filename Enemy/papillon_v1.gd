extends EnemyBase

const DISSOLVE_SHADER = preload("res://Effects/Shaders/pixel_dissolve.gdshader")

# === PAPILLON V1 ===
# Ennemi volant qui hérite de toute la logique commune d'EnemyBase
# Configuration simple : 75 PV, vol permanent, survol des obstacles

# === PARAMÈTRES EXPORTÉS SPÉCIFIQUES AU PAPILLON ===
@export_group("Papillon V1 - Statistiques")
@export var papillon_max_health: int = 75  # 3 tirs pour le tuer

@export_group("Papillon V1 - Mouvement")
@export var papillon_v1_movement_speed: float = 1.0  # Vitesse de déplacement normale

@export_group("Papillon V1 - Attaque")
@export var papillon_v1_damage_dealt: int = 10  # Dégâts de base au joueur

@export_group("Papillon - Vol")
@export var hover_height: float = 1.2  # Hauteur cible au-dessus du sol
@export var float_amplitude: float = 0.15  # Amplitude du flottement (haut/bas)
@export var float_speed: float = 1.5  # Vitesse du flottement
@export var hover_strength: float = 8.0  # Force de rappel vers la hauteur cible
@export var hover_damping: float = 0.9  # Amortissement pour éviter les oscillations infinies
@export var gravity_scale: float = 1.0  # Multiplicateur de gravité
@export var max_hover_ray_distance: float = 10.0  # Distance maximum du raycast vers le sol
@export var hover_follow_speed: float = 6.0  # Vitesse d'ajustement vers la hauteur cible (0-1 interpolée chaque frame)
@export_flags_3d_physics var hover_collision_mask: int = 1  # Layers considérées comme sol

@export_group("Papillon - Couleurs d'Impact")
@export var impact_color_1: Color = Color(0.2, 0.6, 1.0, 1)    # Bleu
@export var impact_color_2: Color = Color(0.0, 0.8, 1.0, 1)    # Cyan
@export var impact_color_3: Color = Color(1.0, 0.4, 0.8, 1)    # Rose
@export var impact_color_4: Color = Color(1.0, 0.9, 0.2, 1)    # Jaune

@export_group("Papillon V1 - Ombre Portée")
@export var papillon_v1_shadow_size: float = 0.75  # Taille de l'ombre (multiplicateur)
@export var papillon_v1_shadow_opacity: float = 0.384  # Opacité de l'ombre (0.0 à 1.0)

# === VARIABLES SPÉCIFIQUES AU PAPILLON ===
var gravity: float
var float_timer: float = 0.0
var has_ground_contact: bool = false
var desired_height: float = 0.0
@onready var dissolve_material: ShaderMaterial = null
var _dissolve_connection_established: bool = false
var _dissolve_tween: Tween = null

# === MÉTHODES VIRTUELLES SURCHARGÉES ===

func _on_enemy_ready() -> void:
	# Initialisation spécifique au papillon V1
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_scale
	
	# Configuration des collisions pour le papillon volant
	collision_layer = 2  # Ennemi sur la layer 2 (détectable par raycast)
	collision_mask = 3   # Détecte la layer 0 (environnement) + layer 1 (joueur)
	
	# Appliquer les valeurs spécifiques au papillon V1
	max_health = papillon_max_health
	current_health = max_health
	base_damage_dealt = papillon_v1_damage_dealt
	movement_speed_multiplier = papillon_v1_movement_speed
	shadow_size = papillon_v1_shadow_size
	shadow_opacity = papillon_v1_shadow_opacity
	_setup_shadow()
	
	# Démarrer l'animation de vol en permanence
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("PapillonV1IdleAnim"):
		sprite.play("PapillonV1IdleAnim")
	
	# Configurer le matériau de dissolution pixelisée
	_setup_dissolve_material()

func _on_physics_process(delta: float) -> void:
	# Physique spécifique au papillon V1 (vol avec flottement)
	
	# Calculer l'offset de flottement basé sur le temps
	float_timer += delta * float_speed
	var hover_offset: float = sin(float_timer) * float_amplitude
	
	# Effectuer un raycast vers le sol pour détecter la hauteur
	var ray_start: Vector3 = global_position + Vector3.UP * 0.5
	var ray_end: Vector3 = global_position + Vector3.DOWN * max_hover_ray_distance
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	has_ground_contact = false
	desired_height = global_position.y + hover_offset
	
	if space_state:
		var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		query.collision_mask = hover_collision_mask
		query.exclude = [get_rid()]  # Ne pas se toucher soi-même
		var result := space_state.intersect_ray(query)
		if result:
			var hit_position: Vector3 = result.position
			desired_height = hit_position.y + hover_height + hover_offset
			has_ground_contact = true
	
	# Appliquer la gravité
	velocity.y -= gravity * delta
	move_and_slide()
	
	# Ajuster la hauteur si contact avec le sol détecté
	if has_ground_contact:
		var t: float = clamp(hover_follow_speed * delta, 0.0, 1.0)
		global_position.y = lerp(global_position.y, desired_height, t)
		velocity.y = 0.0


func _on_damage_taken(_damage: int) -> void:
	# Aucune réaction spécifique aux dégâts pour le papillon V1
	pass

func _on_death() -> bool:
	if not sprite or dissolve_material == null:
		return false
	
	# Déconnecter le signal de mise à jour de texture
	if _dissolve_connection_established and sprite.frame_changed.is_connected(_update_dissolve_texture):
		sprite.frame_changed.disconnect(_update_dissolve_texture)
		_dissolve_connection_established = false
	
	# Arrêter le tween précédent s'il existe
	if _dissolve_tween and _dissolve_tween.is_running():
		_dissolve_tween.kill()
	
	# Créer le tween de dissolution
	_dissolve_tween = create_tween()
	_dissolve_tween.set_parallel(true)
	_dissolve_tween.tween_property(dissolve_material, "shader_parameter/dissolve_amount", 1.0, 0.45)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
	_dissolve_tween.tween_property(dissolve_material, "shader_parameter/pixel_size", 26.0, 0.45)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	# Supprimer l'ennemi à la fin de la dissolution
	_dissolve_tween.finished.connect(func():
		if is_instance_valid(sprite):
			sprite.visible = false
		queue_free()
	)
	
	return true

# === MÉTHODES SPÉCIFIQUES AU PAPILLON V1 ===

func get_impact_colors() -> Array[Color]:
	# Retourner les 4 couleurs d'impact du papillon V1 (tons bleu/cyan/rose/jaune)
	return [impact_color_1, impact_color_2, impact_color_3, impact_color_4]

func _setup_dissolve_material() -> void:
	# Configurer le matériau de dissolution pixelisée
	if not sprite:
		return
	
	dissolve_material = ShaderMaterial.new()
	dissolve_material.shader = DISSOLVE_SHADER
	
	# Calculer la couleur moyenne pour le bord de dissolution
	var average_color: Color = (impact_color_1 + impact_color_2 + impact_color_3 + impact_color_4) / 4.0
	dissolve_material.set_shader_parameter("dissolve_amount", 0.0)
	dissolve_material.set_shader_parameter("pixel_size", 1.0)
	dissolve_material.set_shader_parameter("edge_glow", 1.4)
	dissolve_material.set_shader_parameter("edge_color", Vector3(average_color.r, average_color.g, average_color.b))
	
	sprite.material_override = dissolve_material
	_update_dissolve_texture()
	
	# Connecter le signal pour mettre à jour la texture à chaque frame
	if not _dissolve_connection_established:
		sprite.frame_changed.connect(_update_dissolve_texture)
		_dissolve_connection_established = true

func _update_dissolve_texture() -> void:
	# Mettre à jour la texture du shader avec la frame actuelle du sprite
	if not sprite or not sprite.sprite_frames or dissolve_material == null:
		return
	
	var frames: SpriteFrames = sprite.sprite_frames
	var current_animation: StringName = sprite.animation
	var current_frame: int = sprite.frame
	var frame_texture: Texture2D = frames.get_frame_texture(current_animation, current_frame)
	if frame_texture:
		dissolve_material.set_shader_parameter("texture_albedo", frame_texture)
