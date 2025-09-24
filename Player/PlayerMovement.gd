extends Node
class_name PlayerMovement

# === PARAMÈTRES EXPORTÉS ===
@export_group("Mouvement")
@export var max_speed: float = 9.5
@export var acceleration_duration: float = 0.4
@export var slam_velocity: float = -33.0
@export var freeze_duration_after_slam: float = 0.3
@export var min_time_before_slam: float = 0.4

@export_group("Saut")
@export var jump_height: float = 3.3  # Hauteur de saut désirée (en mètres)
@export var jump_velocity: float = 4.5  # Force du saut (calculée automatiquement)
@export var fall_gravity_multiplier: float = 1.0  # Multiplicateur de gravité pour la chute

# === RÉFÉRENCES ===
var player: CharacterBody3D
var camera_component: PlayerCamera

# === SIGNAUX ===
signal slam_landed

# === VARIABLES INTERNES ===
var current_speed: float = 0.0
var is_accelerating: bool = false
var acceleration_timer: float = 0.0
var can_slam: bool = true
var is_slamming: bool = false
var is_frozen: bool = false
var freeze_timer: float = 0.0
var jump_time: float = 0.0
var is_jumping_state: bool = false


# === INITIALISATION ===
func _ready() -> void:
	# Le joueur sera assigné par le script principal
	pass

func setup_player(player_node: CharacterBody3D) -> void:
	player = player_node
	# Récupérer la référence à la caméra avec vérification
	camera_component = player.get_node_or_null("PlayerCamera") as PlayerCamera
	# Calculer la vélocité de saut basée sur la hauteur désirée
	call_deferred("_calculate_jump_velocity")

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
		# Appliquer la gravité
		player.velocity.y += player.get_gravity().y * fall_gravity_multiplier * delta
		jump_time += delta
		is_jumping_state = true
		
		# Mettre à jour la hauteur de saut pour la caméra
		if camera_component:
			camera_component.update_jump_height(player.global_position.y)
	else:
		# Réinitialiser l'état de saut à l'atterrissage
		if is_jumping_state:
			is_jumping_state = false
			jump_time = 0.0
			# Arrêter l'effet de regard vers le bas
			if camera_component:
				camera_component.stop_jump_look_down()

# === GESTION DE L'ATTERRISSAGE APRÈS SLAM ===
func _handle_slam_landing() -> void:
	if not (player.is_on_floor() and is_slamming):
		return
		
	is_slamming = false
	is_frozen = true
	freeze_timer = freeze_duration_after_slam
	
	# Émettre le signal pour déclencher le camera shake
	slam_landed.emit()

# === GESTION DU MOUVEMENT HORIZONTAL ===
func _handle_movement(delta: float) -> void:
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	# Early return - si pas d'input ou frozen, arrêter le mouvement
	if input_dir == Vector2.ZERO or is_frozen:
		_stop_movement()
		return
	
	# Calculer la direction de mouvement
	var direction = _calculate_movement_direction(input_dir)
	
	# Gérer l'accélération et appliquer la vitesse
	_update_movement_speed(delta)
	_apply_movement_velocity(direction)

# === FONCTIONS DE SAUT ===

# --- Calcul de la vélocité de saut ---
func _calculate_jump_velocity() -> void:
	if not player:
		return
	# Formule physique : v = sqrt(2 * g * h)
	# où g = gravité et h = hauteur désirée
	var gravity = abs(player.get_gravity().y)
	if gravity > 0:
		jump_velocity = sqrt(2.0 * gravity * jump_height)
	else:
		# Fallback si la gravité n'est pas encore initialisée
		jump_velocity = sqrt(2.0 * 9.8 * jump_height)

# --- Recalcul automatique quand la hauteur change ---
func _validate_property(property: Dictionary) -> void:
	if property.name == "jump_height":
		property.usage = PROPERTY_USAGE_EDITOR
		# Recalculer la vélocité quand la hauteur change
		call_deferred("_calculate_jump_velocity")

# === FONCTIONS PUBLIQUES POUR LE JOUEUR ===
func start_jump() -> void:
	if player.is_on_floor() and not is_frozen:
		player.velocity.y = jump_velocity
		jump_time = 0.0
		# Démarrer l'effet de regard vers le bas
		if camera_component:
			camera_component.start_jump_look_down(player.global_position.y)

func start_slam() -> void:
	if not player.is_on_floor() and jump_time >= min_time_before_slam and can_slam and not is_slamming and not is_frozen:
		is_slamming = true
		player.velocity.y = slam_velocity

func get_current_speed() -> float:
	return current_speed

func is_moving() -> bool:
	return current_speed > 0

func is_jumping() -> bool:
	return is_jumping_state

func is_slamming_state() -> bool:
	return is_slamming

# === FONCTIONS UTILITAIRES PRIVÉES ===


# --- Arrêt du mouvement ---
func _stop_movement() -> void:
	is_accelerating = false
	current_speed = 0.0
	player.velocity.x = 0.0
	player.velocity.z = 0.0

# --- Calcul de la direction de mouvement ---
func _calculate_movement_direction(input_dir: Vector2) -> Vector3:
	return (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

# --- Mise à jour de la vitesse de mouvement ---
func _update_movement_speed(delta: float) -> void:
	if not is_accelerating:
		is_accelerating = true
		acceleration_timer = 0.0
	
	acceleration_timer += delta
	var speed_ratio = min(acceleration_timer / acceleration_duration, 1.0)
	current_speed = max_speed * speed_ratio

# --- Application de la vélocité de mouvement ---
func _apply_movement_velocity(direction: Vector3) -> void:
	player.velocity.x = direction.x * current_speed
	player.velocity.z = direction.z * current_speed
