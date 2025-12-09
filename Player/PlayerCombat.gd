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
	
	# Récupérer les références aux nœuds nécessaires
	raycast = player.get_node_or_null("PlayerCamera/RayCast3D")
	revolver_sprite = player.get_node_or_null("HUD_Layer/Revolver")
	camera_component = player.get_node_or_null("PlayerCamera")
	
	# Configurer le raycast et connecter le revolver
	_setup_raycast()
	_connect_revolver()

# === CONFIGURATION DU RAYCAST ===
func _setup_raycast() -> void:
	# Créer le raycast s'il n'existe pas déjà
	if not raycast:
		var camera = player.get_node_or_null("PlayerCamera")
		if camera:
			raycast = RayCast3D.new()
			camera.add_child(raycast)
		else:
			push_error("PlayerCombat: Camera3D non trouvée pour créer le raycast")
			return
	
	# Configurer le raycast
	raycast.target_position = base_raycast_direction  # Direction de base du raycast
	raycast.enabled = true
	raycast.collision_mask = 2  # Détecter uniquement la layer 2 (ennemis)
	raycast.exclude_parent = true  # Exclure le parent du raycast

# === CONNEXION DU REVOLVER ===
func _connect_revolver() -> void:
	if revolver_sprite:
		revolver_sprite.shot_fired.connect(_handle_shot)
		revolver_connected = true
	else:
		push_error("Revolver sprite non trouvé dans HUD_Layer/Revolver")
		revolver_connected = false


# === GESTION DU TIR AVEC RAYCAST ===
func _handle_shot() -> void:
	if not raycast:
		return
	
	# Calculer la direction compensée du raycast (compensation pour le saut)
	var compensated_direction = base_raycast_direction
	if enable_jump_compensation and camera_component:
		var camera_rotation_x = camera_component.rotation_degrees.x
		var limited_angle = clamp(camera_rotation_x, -max_compensation_angle, max_compensation_angle)
		var y_offset = sin(deg_to_rad(limited_angle)) * base_raycast_direction.length() * compensation_strength
		compensated_direction = base_raycast_direction + Vector3(0, y_offset, 0)
	
	# Mettre à jour et forcer la mise à jour du raycast
	raycast.target_position = compensated_direction
	raycast.force_raycast_update()
	
	# Vérifier s'il y a une collision
	if not raycast.is_colliding():
		return
		
	var collider = raycast.get_collider()
	
	# Vérifier que l'objet touché peut prendre des dégâts
	if not collider or not collider.has_method("take_damage"):
		return
	
	# Récupérer les paramètres d'effet du revolver
	var hit_effect_params = null
	if revolver_sprite and revolver_sprite.has_method("get_hit_effect_params"):
		hit_effect_params = revolver_sprite.get_hit_effect_params()
		
	# Appliquer les dégâts à l'ennemi
	collider.take_damage(revolver_damage, hit_effect_params)
	
	# Créer l'effet d'impact visuel au point de collision
	_create_impact_effect(raycast.get_collision_point(), collider)

# === CRÉATION DE L'EFFET D'IMPACT ===
func _create_impact_effect(impact_position: Vector3, target_collider: Node):
	# Créer l'effet d'impact à la position de collision
	var impact_effect = IMPACT_EFFECT_SCENE.instantiate()
	player.get_tree().current_scene.add_child(impact_effect)
	impact_effect.global_position = impact_position
	
	# Appliquer les couleurs d'impact de l'ennemi touché si disponibles
	if target_collider.has_method("get_impact_colors"):
		var impact_colors = target_collider.get_impact_colors()
		if impact_colors.size() >= 4:
			impact_effect.set_impact_colors(impact_colors)


# === FONCTIONS PUBLIQUES POUR LE JOUEUR ===
func is_revolver_connected() -> bool:
	return revolver_connected

func trigger_shot() -> void:
	if not revolver_connected or not revolver_sprite:
		return
	revolver_sprite.play_shot_animation()

func trigger_reload() -> void:
	if not revolver_connected or not revolver_sprite:
		return
	revolver_sprite.start_reload()
