extends Node
class_name PlayerMovement

# === PARAMÈTRES EXPORTÉS ===
@export_group("Mouvement")
@export var max_speed: float = 9.5
@export var acceleration_duration: float = 0.4
@export var slam_velocity: float = -33.0
@export var freeze_duration_after_slam: float = 0.3
@export var min_time_before_slam: float = 0.4

@export_group("Jump Boost")
@export var jump_boost_duration: float = 0.5  # Durée de la poussée rapide
@export var jump_boost_velocity: float = 25.0  # Force de la poussée initiale
@export var jump_boost_force_multiplier: float = 5.0  # Multiplicateur de force maximale
@export var jump_gravity_multiplier: float = 0.6  # Gravité réduite pendant la montée
@export var jump_hover_duration: float = 0.03  # Temps de flottement au sommet
@export var max_jump_height: float = 2.1  # Hauteur maximale relative au point de saut
@export var fall_gravity_multiplier: float = 1.1  # Multiplicateur de gravité pour la chute

# === RÉFÉRENCES ===
var player: CharacterBody3D

# === VARIABLES INTERNES ===
var current_speed: float = 0.0
var is_accelerating: bool = false
var acceleration_timer: float = 0.0
var can_slam: bool = true
var is_slamming: bool = false
var is_frozen: bool = false
var freeze_timer: float = 0.0
var jump_time: float = 0.0

# --- Variables Jump Boost ---
var is_jump_boosting: bool = false
var jump_boost_timer: float = 0.0
var jump_start_height: float = 0.0  # Hauteur Y du point de départ du saut
var jump_boost_force: float = 0.0  # Force d'accélération progressive

# --- Variables Hover (Flottement) ---
var is_hovering: bool = false
var hover_timer: float = 0.0

# === INITIALISATION ===
func _ready() -> void:
	# Le joueur sera assigné par le script principal
	pass

func setup_player(player_node: CharacterBody3D) -> void:
	player = player_node

# === GESTION PRINCIPALE ===
func _physics_process(delta: float) -> void:
	if not player:
		return
		
	_handle_freeze_state(delta)
	
	if is_frozen:
		return
		
	_handle_gravity_and_jump(delta)
	_handle_slam_landing()
	_handle_movement(delta)

# === GESTION DE L'ÉTAT DE FREEZE ===
func _handle_freeze_state(delta: float) -> void:
	if not is_frozen:
		return
		
	freeze_timer -= delta
	if freeze_timer <= 0:
		is_frozen = false
		freeze_timer = 0.0
		player.velocity.x = 0.0
		player.velocity.z = 0.0

# === GESTION DE LA GRAVITÉ ET DU SAUT ===
func _handle_gravity_and_jump(delta: float) -> void:
	if not player.is_on_floor():
		_handle_jump_boost(delta)
		jump_time += delta
	else:
		# Réinitialiser tous les états de saut à l'atterrissage SEULEMENT si on n'est pas en train de sauter
		if not is_jump_boosting and not is_hovering:
			_reset_jump_states()

# === GESTION DE L'ATTERRISSAGE APRÈS SLAM ===
func _handle_slam_landing() -> void:
	if not (player.is_on_floor() and is_slamming):
		return
		
	is_slamming = false
	is_frozen = true
	freeze_timer = freeze_duration_after_slam
	# Le shake sera géré par le composant caméra

# === GESTION DU MOUVEMENT HORIZONTAL ===
func _handle_movement(delta: float) -> void:
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	# Early return - si pas d'input ou frozen, arrêter le mouvement
	if input_dir == Vector2.ZERO or is_frozen:
		is_accelerating = false
		current_speed = 0.0
		player.velocity.x = 0.0
		player.velocity.z = 0.0
		return
	
	# Calculer la direction de mouvement
	var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Gérer l'accélération
	if not is_accelerating:
		is_accelerating = true
		acceleration_timer = 0.0
	
	acceleration_timer += delta
	var speed_ratio = min(acceleration_timer / acceleration_duration, 1.0)
	current_speed = max_speed * speed_ratio
	
	# Appliquer la vitesse
	player.velocity.x = direction.x * current_speed
	player.velocity.z = direction.z * current_speed

# === FONCTIONS JUMP BOOST ===

# --- Démarrage du boost de saut ---
func _start_jump_boost() -> void:
	is_jump_boosting = true
	jump_boost_timer = 0.0
	jump_start_height = player.global_position.y  # Enregistrer la hauteur de départ
	jump_boost_force = 0.0  # Commencer avec une force nulle
	# Commencer avec une vitesse initiale plus forte
	player.velocity.y = jump_boost_velocity * 0.3

# --- Réinitialisation des états de saut ---
func _reset_jump_states() -> void:
	is_jump_boosting = false
	jump_boost_timer = 0.0
	jump_boost_force = 0.0
	is_hovering = false
	hover_timer = 0.0
	jump_start_height = 0.0

# --- Gestion du boost de saut ---
func _handle_jump_boost(delta: float) -> void:
	if is_jump_boosting:
		jump_boost_timer += delta
		
		# Calculer la hauteur actuelle par rapport au point de départ
		var current_height_above_start = player.global_position.y - jump_start_height
		
		# Si on a atteint ou dépassé la hauteur maximale, commencer le flottement
		if current_height_above_start >= max_jump_height:
			is_jump_boosting = false
			is_hovering = true
			hover_timer = 0.0
			player.velocity.y = 0.0  # Arrêter la montée
			return
		
		# Phase 1: Force d'accélération progressive
		if jump_boost_timer <= jump_boost_duration:
			# Calculer la force d'accélération progressive
			var boost_progress = jump_boost_timer / jump_boost_duration
			var target_force = jump_boost_velocity * jump_boost_force_multiplier  # Force maximale
			
			# Accélération progressive de la force (ease-in quad)
			jump_boost_force = target_force * ease_in_quad(boost_progress)
			
			# Appliquer la force d'accélération (ajouter à la vitesse existante)
			player.velocity.y += jump_boost_force * delta
		else:
			# Phase 2: Gravité normale après le boost (mais on reste en boost jusqu'à la hauteur max)
			player.velocity.y += player.get_gravity().y * delta
	
	elif is_hovering:
		# Phase 3: Flottement au sommet
		hover_timer += delta
		
		# Maintenir la vitesse verticale à 0 (flottement parfait)
		player.velocity.y = 0.0
		
		# Si le temps de flottement est écoulé, arrêter le flottement
		if hover_timer >= jump_hover_duration:
			is_hovering = false
			hover_timer = 0.0
	else:
		# Gravité normale quand pas de boost ni de flottement
		player.velocity.y += player.get_gravity().y * fall_gravity_multiplier * delta

# === FONCTIONS D'EASING ===
func ease_out_quad(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)

func ease_out_expo(t: float) -> float:
	return 1.0 - pow(2.0, -10.0 * t)

func ease_in_expo(t: float) -> float:
	return pow(2.0, 10.0 * (t - 1.0))

func ease_in_quad(t: float) -> float:
	return t * t

# === FONCTIONS PUBLIQUES POUR LE JOUEUR ===
func start_jump() -> void:
	if player.is_on_floor() and not is_frozen:
		_start_jump_boost()
		jump_time = 0.0

func start_slam() -> void:
	if not player.is_on_floor() and jump_time >= min_time_before_slam and can_slam and not is_slamming and not is_frozen:
		is_slamming = true
		player.velocity.y = slam_velocity
		# Arrêter le flottement si on slam
		if is_hovering:
			is_hovering = false
			hover_timer = 0.0

func get_current_speed() -> float:
	return current_speed

func is_moving() -> bool:
	return current_speed > 0

func is_jumping() -> bool:
	return is_jump_boosting or is_hovering

func is_slamming_state() -> bool:
	return is_slamming
