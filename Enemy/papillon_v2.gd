extends "res://Enemy/enemy_base.gd"

# === PAPILLON V2 ===
# Ennemi volant plus agressif que le V1
# Même PV mais flottement plus rapide, déplacement 1.5× plus rapide, dégâts 2× plus importants

# === PARAMÈTRES EXPORTÉS SPÉCIFIQUES AU PAPILLON V2 ===
@export_group("Papillon V2 - Statistiques")
@export var papillon_max_health: int = 75  # Même PV que le V1

@export_group("Papillon V2 - Mouvement")
@export var papillon_v2_movement_speed: float = 1.5  # 1.5× plus rapide que le V1

@export_group("Papillon V2 - Attaque")
@export var papillon_v2_damage_dealt: int = 20  # 2× les dégâts du V1 (10 → 20)

@export_group("Papillon V2 - Vol")
@export var hover_height: float = 1.2  # Hauteur cible au-dessus du sol
@export var float_amplitude: float = 0.15  # Amplitude du flottement (haut/bas)
@export var float_speed: float = 3.0  # Flottement 2× plus rapide que V1 (1.5 → 3.0)
@export var hover_strength: float = 10.0  # Force de rappel vers la hauteur cible (un peu plus ferme que V1)
@export var hover_damping: float = 0.9  # Amortissement pour éviter les oscillations infinies
@export var gravity_scale: float = 1.0  # Multiplicateur de gravité
@export var max_hover_ray_distance: float = 10.0  # Distance maximum du raycast vers le sol
@export var hover_follow_speed: float = 7.5  # Lerp vers la hauteur cible
@export_flags_3d_physics var hover_collision_mask: int = 1  # Layers considérées comme sol

@export_group("Papillon V2 - Couleurs d'Impact")
@export var impact_color_1: Color = Color(1.0, 0.4, 0.2, 1)    # Orange
@export var impact_color_2: Color = Color(1.0, 0.0, 0.2, 1)    # Rouge
@export var impact_color_3: Color = Color(1.0, 0.7, 0.0, 1)    # Jaune-orange
@export var impact_color_4: Color = Color(1.0, 0.5, 0.0, 1)    # Orange foncé

@export_group("Papillon V2 - Ombre Portée")
@export var papillon_v2_shadow_size: float = 0.75  # Taille de l'ombre (multiplicateur)
@export var papillon_v2_shadow_opacity: float = 0.384  # Opacité de l'ombre (0.0 à 1.0)

# === VARIABLES SPÉCIFIQUES AU PAPILLON V2 ===
var gravity: float
var float_timer: float = 0.0
var has_ground_contact: bool = false
var desired_height: float = 0.0

# === MÉTHODES VIRTUELLES SURCHARGÉES ===

func _on_enemy_ready():
	# Initialisation spécifique au papillon V2
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_scale
	
	# Configuration des collisions spécifique au papillon volant
	collision_layer = 2  # Ennemi sur la layer 2 (détectable par raycast)
	collision_mask = 3   # Détecte la layer 0 (environnement) + layer 1 (joueur)
	
	# Override des valeurs d'EnemyBase avec celles du papillon V2
	max_health = papillon_max_health
	current_health = max_health
	base_damage_dealt = papillon_v2_damage_dealt
	movement_speed_multiplier = papillon_v2_movement_speed
	shadow_size = papillon_v2_shadow_size
	shadow_opacity = papillon_v2_shadow_opacity
	# Réappliquer la configuration de l'ombre avec la nouvelle taille
	_setup_shadow()
	
	# Démarrer l'animation de vol en permanence
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("PapillonV2IdleAnim"):
		sprite.play("PapillonV2IdleAnim")

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
	# Réactions spécifiques aux dégâts (pour l'instant, rien de spécial)
	pass

func _on_death():
	# Effets de mort spécifiques au papillon V2 (pour plus tard)
	pass

# === MÉTHODE SPÉCIFIQUE AU PAPILLON V2 ===
# Cette méthode sera utilisée par PlayerCombat pour récupérer les couleurs d'impact
func get_impact_colors() -> Array[Color]:
	# Retourne les 4 couleurs d'impact du papillon V2 (tons orange/rouge)
	return [impact_color_1, impact_color_2, impact_color_3, impact_color_4]
