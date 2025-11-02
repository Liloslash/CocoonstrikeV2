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

@export_group("Slam")
@export var slam_radius: float = 2.0  # Rayon de la sphère d'effet du slam
@export var slam_push_distance: float = 1.5  # Distance horizontale du repoussement
@export var slam_push_height: float = 0.2  # Hauteur du bond de repoussement (plus subtil)
@export var slam_freeze_duration: float = 1.0  # Durée minimum du freeze après slam

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
	_calculate_jump_velocity()

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
			can_slam = true  # Réactiver le slam pour le prochain saut
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
	
	# Gérer l'impact du slam sur les ennemis
	_handle_slam_impact()
	
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
func _calculate_jump_velocity() -> void:
	if not player:
		return
	
	# Formule physique : v = sqrt(2 * g * h)
	var gravity = abs(player.get_gravity().y)
	jump_velocity = sqrt(2.0 * max(gravity, 9.8) * jump_height)


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
		can_slam = false  # Empêcher les slams multiples
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

# --- Gestion de l'impact du slam ---
func _handle_slam_impact() -> void:
	if not player:
		return
	
	# Méthode simple : chercher tous les ennemis dans la scène
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if not enemy or not is_instance_valid(enemy):
			continue
			
		# Calculer la distance au joueur
		var distance = player.global_position.distance_to(enemy.global_position)
		
		# Si l'ennemi est dans la zone de slam
		if distance <= slam_radius:
			# Calculer la direction de repoussement (opposée au joueur)
			var direction_away = (enemy.global_position - player.global_position).normalized()
			
			# Appliquer le repoussement immédiatement
			enemy._apply_slam_repulsion(direction_away, slam_push_distance, slam_push_height, slam_freeze_duration)

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
