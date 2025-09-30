extends CharacterBody3D

# === SYSTÈME D'ENNEMI ===
# Gestion de la vie, dégâts, effets visuels et rotation vers le joueur

# === PARAMÈTRES EXPORTÉS ===
@export_group("Statistiques")
@export var max_health: int = 100

@export_group("Comportement")
# (Variables de comportement supprimées - seront réimplémentées avec le nouveau système d'IA)

@export_group("Animation de Mort")
@export var death_freeze_duration: float = 1.0  # Durée du freeze avant disparition

@export_group("Effets d'Impact")
@export var impact_color_1: Color = Color(1.0, 0.5, 0.5, 1.0)  # Rouge clair
@export var impact_color_2: Color = Color.GREEN    # Couleur 2 (veines vertes)
@export var impact_color_3: Color = Color.PURPLE   # Couleur 3 (corps violet)
@export var impact_color_4: Color = Color.BLACK    # Couleur 4 (détails noirs)

@export_group("Effet de Rougissement")
@export var red_flash_duration: float = 0.2  # Durée du rougissement (0.2 secondes)
@export var red_flash_intensity: float = 1.5  # Intensité du rouge (1.5 pour un effet bien visible)
@export var red_flash_color: Color = Color.RED  # Couleur du rougissement

@export_group("Gravité")
@export var gravity_scale: float = 1.0
@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_scale

@export_group("Slam Repoussement")
@export var slam_push_force: float = 4.0  # Force du repoussement
@export var slam_bond_duration: float = 0.6  # Durée du bond avant arrêt horizontal
@export var slam_freeze_delay: float = 0.8  # Délai avant le freeze
@export var slam_cooldown_time: float = 0.2  # Cooldown entre les slams

# === VARIABLES INTERNES ===
var current_health: int
var is_alive: bool = true
var is_frozen: bool = false
var player_reference: Node3D = null
var freeze_timer: float = 0.0
var is_being_repelled: bool = false
var pending_freeze_duration: float = 0.0
var slam_cooldown: float = 0.0

# === NAVIGATION ===
# (Système de pathfinding supprimé - sera réimplémenté plus tard)

# === COMPOSANTS ===
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D  # Le sprite 2D billboard

func _ready():
	# Initialisation
	current_health = max_health
	
	# Configuration des collisions
	collision_layer = 2  # Ennemi sur la layer 2 (détectable par raycast)
	collision_mask = 3   # Détecte la layer 0 (environnement) + layer 1 (joueur)
	
	# Ajouter au groupe des ennemis pour la détection du slam
	add_to_group("enemies")
	
	# Recherche du joueur dans la scène
	_find_player()

func _find_player():
	# Cherche le joueur dans la scène (adaptez selon votre structure)
	var world = get_tree().get_first_node_in_group("world")
	if world:
		player_reference = world.get_node_or_null("Player")
	
	if not player_reference:
		# Recherche alternative - chercher directement dans la scène
		player_reference = get_tree().get_first_node_in_group("player")
	
	if not player_reference:
		# Recherche directe par nom de nœud
		player_reference = get_node_or_null("/root/World/Player")
	
	# Vérifier si le joueur est trouvé
	if not player_reference:
		push_warning("Ennemi : Joueur non trouvé - la rotation ne fonctionnera pas")
		# Ne pas utiliser push_error() car ce n'est pas critique

func _physics_process(delta):
	if not is_alive:
		return
	
	# Gérer le freeze
	_handle_freeze(delta)
	
	# Gérer le cooldown du slam
	if slam_cooldown > 0:
		slam_cooldown -= delta
	
	if is_frozen:
		return

	# Gravité + déplacement
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# Arrêter le mouvement vertical quand on touche le sol
		if velocity.y < 0.0:
			velocity.y = 0.0
		# Arrêter aussi le mouvement horizontal pour éviter le glissement
		if abs(velocity.x) < 0.1 and abs(velocity.z) < 0.1:
			velocity.x = 0.0
			velocity.z = 0.0

	move_and_slide()

	# ROTATION DU SPRITE VERS LE JOUEUR
	_update_sprite_rotation()

# === SYSTÈME DE DÉGÂTS ===
func take_damage(damage: int, hit_effect_params: Dictionary = {}):
	if not is_alive:
		return
	
	current_health -= damage
	
	# Effet de rougissement au moment de l'impact
	_create_red_flash()
	
	# Effet de vibration si des paramètres sont fournis
	if hit_effect_params:
		_create_hit_shake(hit_effect_params)
	
	# Freeze pendant l'animation de tremblement
	_start_damage_freeze()
	
	# Vérification de la mort
	if current_health <= 0:
		_die()

# === SYSTÈME DE REPOUSSEMENT DU SLAM ===
func _apply_slam_repulsion(direction: Vector3, _push_distance: float, push_height: float, freeze_duration: float):
	if not is_alive:
		return
	
	# Vérifier le cooldown (éviter les slams trop rapides)
	if slam_cooldown > 0:
		return
	
	# Sortir du freeze si on était gelé
	is_frozen = false
	freeze_timer = 0.0
	
	# Calculer la vélocité de repoussement (force constante, peu importe la distance)
	var push_velocity = Vector3(
		direction.x * slam_push_force,  # Force horizontale configurable
		push_height * slam_push_force,  # Force verticale configurable
		direction.z * slam_push_force
	)
	
	# Appliquer la vélocité IMMÉDIATEMENT
	velocity = push_velocity
	
	# Mettre un cooldown court pour éviter les slams multiples
	slam_cooldown = slam_cooldown_time
	
	# Programmer l'arrêt du mouvement après le bond
	_stop_after_bond()
	
	# Freeze après le bond
	await get_tree().create_timer(slam_freeze_delay).timeout
	is_frozen = true
	freeze_timer = freeze_duration

func _stop_after_bond():
	# Arrêter le mouvement horizontal après le bond
	await get_tree().create_timer(slam_bond_duration).timeout
	velocity.x = 0.0
	velocity.z = 0.0

func _die():
	if not is_alive:
		return
		
	is_alive = false
	is_frozen = true
	_disable_collisions()
	
	# Freeze pendant 1 seconde puis disparition
	await get_tree().create_timer(death_freeze_duration).timeout
	queue_free()

func _disable_collisions():
	# Désactiver collisions du corps
	var body_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")
	if body_shape:
		body_shape.disabled = true
	
	# Désactiver l'Area3D et sa forme
	var area: Area3D = get_node_or_null("Area3D")
	if area:
		area.monitoring = false
		area.monitorable = false
		var area_shape: CollisionShape3D = area.get_node_or_null("CollisionShape3D")
		if area_shape:
			area_shape.disabled = true
	
	# Retirer des layers/masks pour ne plus être raycastable
	collision_layer = 0
	collision_mask = 0

# === GETTERS POUR DEBUG/HUD ===
func get_health_percentage() -> float:
	return float(current_health) / float(max_health)

func is_dead() -> bool:
	return not is_alive

# === GETTERS POUR LES COULEURS D'IMPACT ===
func get_impact_colors() -> Array[Color]:
	return [impact_color_1, impact_color_2, impact_color_3, impact_color_4]

# === EFFET DE ROUGISSEMENT ===
func _create_red_flash():
	# Vérification que l'ennemi est vivant et a un sprite
	if not is_alive or not sprite or not is_inside_tree():
		return
	
	# Sauvegarde de la couleur originale
	var original_color = sprite.modulate
	
	# Création du tween pour l'effet de rougissement
	var flash_tween = create_tween()
	
	# Calcul de la couleur de rougissement
	var flash_color = Color(
		red_flash_color.r * red_flash_intensity,
		red_flash_color.g * red_flash_intensity,
		red_flash_color.b * red_flash_intensity,
		red_flash_color.a
	)
	
	# Phase 1 : Apparition rapide du rouge (EASE_OUT)
	flash_tween.tween_property(sprite, "modulate", flash_color, red_flash_duration * 0.3)
	flash_tween.set_trans(Tween.TRANS_QUAD)
	flash_tween.set_ease(Tween.EASE_OUT)
	
	# Phase 2 : Retour à la couleur originale (EASE_OUT)
	flash_tween.tween_property(sprite, "modulate", original_color, red_flash_duration * 0.7)
	flash_tween.set_trans(Tween.TRANS_QUAD)
	flash_tween.set_ease(Tween.EASE_OUT)

# === EFFET DE VIBRATION ===
func _create_hit_shake(effect_params: Dictionary):
	# Vérification que l'ennemi est vivant et a un sprite
	if not is_alive or not sprite or not is_inside_tree():
		return
	
	# Sauvegarde de la position et rotation originales
	var original_position = sprite.position
	var original_rotation = sprite.rotation
	
	# Création du tween pour l'effet de vibration
	var shake_tween = create_tween()
	# Pas de set_loops() - on contrôle manuellement la durée
	
	# Récupération des paramètres avec valeurs par défaut
	var duration = effect_params.get("duration", 0.25)
	var intensity = effect_params.get("intensity", 0.1)
	var frequency = effect_params.get("frequency", 20.0)
	var axes = effect_params.get("axes", Vector3(1.0, 1.0, 0.0))
	
	# Calcul du nombre d'oscillations basé sur la durée et la fréquence
	var oscillations = int(duration * frequency)
	
	# Création du pattern de vibration
	for i in range(oscillations):
		# Calcul de l'intensité qui diminue progressivement
		var current_intensity = intensity * (1.0 - float(i) / float(oscillations))
		
		# Direction aléatoire pour la vibration (seulement sur les axes activés)
		var random_direction = Vector3(
			randf_range(-1.0, 1.0) * axes.x,
			randf_range(-1.0, 1.0) * axes.y,
			randf_range(-1.0, 1.0) * axes.z
		).normalized()
		
		# Décalage de vibration
		var shake_offset = random_direction * current_intensity
		var shake_rotation_offset = Vector3(0, 0, random_direction.z * current_intensity)
		
		# Durée de chaque oscillation
		var oscillation_duration = duration / float(oscillations)
		
		# Ajout du mouvement au tween (relatif à la position originale)
		shake_tween.tween_property(sprite, "position", original_position + shake_offset, oscillation_duration)
		shake_tween.tween_property(sprite, "rotation", original_rotation + shake_rotation_offset, oscillation_duration)
	
	# Retour à la position originale à la fin
	shake_tween.tween_property(sprite, "position", original_position, 0.1)
	shake_tween.tween_property(sprite, "rotation", original_rotation, 0.1)
	
	# Arrêt du tween après la durée totale
	get_tree().create_timer(duration).timeout.connect(func(): 
		if shake_tween and shake_tween.is_valid():
			shake_tween.kill()
	)
	
	# Forcer le retour à la position originale (sécurité)
	sprite.position = original_position
	sprite.rotation = original_rotation

# === SYSTÈME DE NAVIGATION ===
# (Système de pathfinding supprimé - sera réimplémenté plus tard)

# === ROTATION DU SPRITE VERS LE JOUEUR ===
func _update_sprite_rotation():
	# Vérifier que l'ennemi est vivant, a un sprite et un joueur de référence
	if not is_alive or not sprite or not player_reference or not is_inside_tree() or not is_instance_valid(player_reference):
		return
	
	# Calculer la direction vers le joueur (SEULEMENT sur l'axe X/Z)
	var direction_to_player = (player_reference.global_position - global_position)
	direction_to_player.y = 0  # Ignorer l'axe Y (hauteur)
	direction_to_player = direction_to_player.normalized()
	
	# Créer un point cible devant l'ennemi dans la direction du joueur (même hauteur)
	var look_target = global_position + direction_to_player
	
	# Faire tourner le sprite pour regarder vers le joueur (rotation uniquement sur Y)
	sprite.look_at(look_target, Vector3.UP)

# === SYSTÈME DE FREEZE ===
func _handle_freeze(delta: float) -> void:
	if not is_frozen:
		return
	
	freeze_timer -= delta
	if freeze_timer <= 0:
		is_frozen = false
		freeze_timer = 0.0

func _start_damage_freeze() -> void:
	# Freeze pendant la durée de l'animation de tremblement
	var shake_duration = 0.25  # Durée par défaut du tremblement
	is_frozen = true
	freeze_timer = shake_duration

# Fonctions supprimées - logique simplifiée

func _trigger_landing_shake() -> void:
	# Déclencher l'animation de tremblement à l'atterrissage
	if not is_alive or not sprite or not is_inside_tree():
		return
	
	# Créer les paramètres d'effet pour le tremblement
	var shake_params = {
		"duration": 0.25,
		"intensity": 0.1,
		"frequency": 20.0,
		"axes": Vector3(1.0, 1.0, 0.0)
	}
	
	# Déclencher l'animation de tremblement
	_create_hit_shake(shake_params)
	
	# Freeze pendant l'animation
	_start_damage_freeze()
