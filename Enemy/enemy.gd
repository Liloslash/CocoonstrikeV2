extends CharacterBody3D

# === PARAMÈTRES EXPORTÉS ===
@export_group("Statistiques")
@export var max_health: int = 100

@export_group("Comportement")
@export var move_speed: float = 3.0
@export var detection_range: float = 15.0  # Distance de détection du joueur

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

# === VARIABLES INTERNES ===
var current_health: int
var is_alive: bool = true
var is_frozen: bool = false
var player_reference: Node3D = null

# === NAVIGATION ===
@onready var nav_agent: NavigationAgent3D = $NavigationAgent
var target_position: Vector3
var is_navigating: bool = false

# === COMPOSANTS ===
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D  # Le sprite 2D billboard

func _ready():
	# Initialisation
	current_health = max_health
	
	# Mettre l'ennemi sur la layer 2 pour le raycast
	collision_layer = 2
	
	# Configuration de la navigation
	_setup_navigation()
	
	# Recherche du joueur dans la scène
	_find_player()
	
	# Commencer à naviguer vers le joueur
	_start_navigation()

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
		player_reference = get_node("/root/World/Player")
	
	# Vérifier si le joueur est trouvé
	if not player_reference:
		push_error("ERREUR : Joueur non trouvé pour la navigation !")

func _physics_process(_delta):
	if not is_alive or is_frozen:
		return
	
	# Navigation vers le joueur
	_update_navigation()
	
	# ROTATION DU SPRITE VERS LE JOUEUR
	_update_sprite_rotation()
	
	# MOUVEMENT VIA NAVIGATIONAGENT3D
	if is_navigating and player_reference:
		# Le NavigationAgent3D calcule automatiquement le chemin
		# et appelle _on_velocity_computed() avec la vitesse optimale
		pass  # Le mouvement est géré par _on_velocity_computed()

# === SYSTÈME DE DÉGÂTS ===
func take_damage(damage: int):
	if not is_alive:
		return
	
	current_health -= damage
	
	# Effet de rougissement au moment de l'impact
	_create_red_flash()
	
	# Vérification de la mort
	if current_health <= 0:
		_die()

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
	if not is_alive or not sprite:
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

# === SYSTÈME DE NAVIGATION ===
func _setup_navigation():
	# Configuration du NavigationAgent
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	nav_agent.target_reached.connect(_on_target_reached)
	
	# Paramètres du NavigationAgent
	nav_agent.radius = 0.5
	nav_agent.height = 2.0
	nav_agent.max_speed = move_speed
	nav_agent.path_max_distance = 10.0
	
	# Navigation setup terminé

func _start_navigation():
	if not player_reference:
		print("ERREUR : Pas de joueur pour la navigation !")
		return
	
	#target_position = player_reference.global_position
	#nav_agent.target_position = target_position
	is_navigating = true
	
	# Navigation démarrée

func _update_navigation():
	if not player_reference or not is_navigating:
		return
	
	# Mettre à jour la destination si le joueur bouge significativement
	var new_target = player_reference.global_position
	if new_target.distance_to(target_position) > 1.0:
		target_position = new_target
		nav_agent.target_position = target_position

func _on_velocity_computed(safe_velocity: Vector3):
	# Le NavigationAgent3D a calculé une vitesse sûre pour éviter les obstacles
	velocity = safe_velocity
	move_and_slide()

func _on_target_reached():
	# L'ennemi a atteint sa destination
	is_navigating = false

# === ROTATION DU SPRITE VERS LE JOUEUR ===
func _update_sprite_rotation():
	# Vérifier que l'ennemi est vivant, a un sprite et un joueur de référence
	if not is_alive or not sprite or not player_reference:
		return
	
	# Calculer la direction vers le joueur (SEULEMENT sur l'axe X/Z)
	var direction_to_player = (player_reference.global_position - global_position)
	direction_to_player.y = 0  # Ignorer l'axe Y (hauteur)
	direction_to_player = direction_to_player.normalized()
	
	# Créer un point cible devant l'ennemi dans la direction du joueur (même hauteur)
	var look_target = global_position + direction_to_player
	
	# Faire tourner le sprite pour regarder vers le joueur (rotation uniquement sur Y)
	sprite.look_at(look_target, Vector3.UP)
