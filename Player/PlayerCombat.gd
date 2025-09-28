extends Node
class_name PlayerCombat

# === PARAMÈTRES EXPORTÉS ===
@export_group("Combat")
@export var revolver_damage: int = 25  # Dégâts du revolver

@export_group("Raycast Compensation")
@export var enable_jump_compensation: bool = true  # Activer la compensation lors du saut
@export var compensation_strength: float = 1.0  # Force de la compensation (1.0 = parfaite, 0.5 = réduite)
@export var max_compensation_angle: float = 45.0  # Angle maximum de compensation en degrés

# === RÉFÉRENCES ===
var player: CharacterBody3D
var raycast: RayCast3D
var revolver_sprite: Node
var camera_component: PlayerCamera

# === VARIABLES POUR LA COMPENSATION ===
var base_raycast_direction: Vector3 = Vector3(0, 0, -1000)  # Direction de base du raycast

# === EFFET D'IMPACT ===
const IMPACT_EFFECT_SCENE = preload("res://Effects/ImpactEffect.tscn")

# === RÉFÉRENCE AU REVOLVER DANS LE HUD ===
var revolver_connected: bool = false

# === INITIALISATION ===
func _ready() -> void:
	player = get_parent()
	if not player:
		push_error("PlayerCombat: Parent non trouvé")
		return
	
	# Récupération des références
	raycast = player.get_node_or_null("PlayerCamera/RayCast3D")
	revolver_sprite = player.get_node_or_null("HUD_Layer/Revolver")
	camera_component = player.get_node_or_null("PlayerCamera")
	
	# Configuration des systèmes
	_setup_raycast()
	_connect_revolver()

# === CONFIGURATION DU RAYCAST ===
func _setup_raycast() -> void:
	if not raycast:
		# Créer si manquant (sécurité)
		var camera = player.get_node_or_null("Camera3D")
		if camera:
			raycast = RayCast3D.new()
			camera.add_child(raycast)
		else:
			push_error("PlayerCombat: Camera3D non trouvée pour créer le raycast")
			return
	
	# Configuration robuste même s'il existe déjà dans la scène
	raycast.target_position = base_raycast_direction  # Utiliser la direction de base
	raycast.enabled = true
	raycast.collision_mask = 2  # Ne détecter que la layer 2 (ennemis)
	raycast.exclude_parent = true  # Exclure le parent du raycast

# === CONNEXION DU REVOLVER ===
func _connect_revolver() -> void:
	if revolver_sprite:
		revolver_sprite.shot_fired.connect(_handle_shot)
		revolver_connected = true
	else:
		push_error("Revolver sprite non trouvé dans HUD_Layer/Revolver")
		revolver_connected = false


# === CALCUL DE LA COMPENSATION DU RAYCAST ===
func _calculate_raycast_compensation() -> Vector3:
	# Si la compensation est désactivée, utiliser la direction de base
	if not enable_jump_compensation or not camera_component:
		return base_raycast_direction
	
	# Récupérer l'angle d'inclinaison actuel de la caméra
	var camera_rotation_x = camera_component.rotation_degrees.x
	
	# Calculer l'offset de compensation
	# Quand la caméra s'incline vers le bas (angle négatif), on compense vers le haut
	var compensation_offset = Vector3(0, 0, 0)
	
	# Limiter l'angle de compensation pour éviter des corrections trop importantes
	var limited_angle = clamp(camera_rotation_x, -max_compensation_angle, max_compensation_angle)
	var limited_angle_radians = deg_to_rad(limited_angle)
	
	# Calculer l'offset vertical basé sur l'angle d'inclinaison
	# Utiliser la trigonométrie pour calculer l'offset Y
	var raycast_length = base_raycast_direction.length()
	var y_offset = sin(limited_angle_radians) * raycast_length * compensation_strength
	
	# Appliquer l'offset à la direction de base
	compensation_offset = base_raycast_direction + Vector3(0, y_offset, 0)
	
	return compensation_offset

func _update_raycast_direction() -> void:
	# Mettre à jour la direction du raycast avec la compensation
	if raycast:
		var compensated_direction = _calculate_raycast_compensation()
		raycast.target_position = compensated_direction

# === GESTION DU TIR AVEC RAYCAST ===
func _handle_shot() -> void:
	# Mettre à jour la direction du raycast avec la compensation avant le tir
	_update_raycast_direction()
	
	# Mettre à jour immédiatement le raycast pour éviter un frame de retard
	raycast.force_raycast_update()
	
	if not raycast.is_colliding():
		return
		
	var collider = raycast.get_collider()
	
	if not collider or not collider.has_method("take_damage"):
		return
	
	# Récupérer les paramètres d'effet du revolver
	var hit_effect_params = null
	if revolver_sprite and revolver_sprite.has_method("get_hit_effect_params"):
		var effect_data = revolver_sprite.get_hit_effect_params()
		# Créer un dictionnaire avec les paramètres d'effet
		hit_effect_params = {
			"duration": effect_data["duration"],
			"intensity": effect_data["intensity"],
			"frequency": effect_data["frequency"],
			"axes": effect_data["axes"]
		}
		
	collider.take_damage(revolver_damage, hit_effect_params)
	
	# Créer l'effet d'impact au point de collision
	_create_impact_effect(raycast.get_collision_point(), collider)

# === CRÉATION DE L'EFFET D'IMPACT ===
func _create_impact_effect(impact_position: Vector3, target_collider: Node):
	var impact_effect = IMPACT_EFFECT_SCENE.instantiate()
	player.get_tree().current_scene.add_child(impact_effect)
	impact_effect.global_position = impact_position
	
	# Récupérer les couleurs d'impact de l'ennemi touché
	if target_collider.has_method("get_impact_colors"):
		var impact_colors = target_collider.get_impact_colors()
		if impact_colors.size() >= 4:
			impact_effect.set_impact_colors(impact_colors)


# === FONCTIONS PUBLIQUES POUR LE JOUEUR ===
func trigger_recoil() -> void:
	# Cette fonction sera appelée par le signal du revolver
	# Déclencher le recul de la caméra
	if camera_component:
		camera_component.trigger_recoil()

func is_revolver_connected() -> bool:
	return revolver_connected

func trigger_shot() -> void:
	if not revolver_connected:
		return
	revolver_sprite.play_shot_animation()

func trigger_reload() -> void:
	if not revolver_connected:
		return
	revolver_sprite.start_reload()

# === FONCTIONS POUR LA COMPENSATION DU RAYCAST ===
func set_jump_compensation(enabled: bool) -> void:
	"""Active ou désactive la compensation du raycast lors du saut"""
	enable_jump_compensation = enabled

func set_compensation_strength(strength: float) -> void:
	"""Définit la force de la compensation (0.0 = aucune, 1.0 = parfaite, >1.0 = surexposée)"""
	compensation_strength = clamp(strength, 0.0, 2.0)

func set_max_compensation_angle(angle: float) -> void:
	"""Définit l'angle maximum de compensation en degrés"""
	max_compensation_angle = clamp(angle, 0.0, 90.0)
