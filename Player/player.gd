extends CharacterBody3D

# --- Paramètres exportés ---
@export_group("Mouvement")
@export var max_speed: float = 9.5
@export var jump_velocity: float = 6.0
@export var acceleration_duration: float = 0.5
@export var slam_velocity: float = -25.0
@export var freeze_duration_after_slam: float = 0.5
@export var min_time_before_slam: float = 0.3

@export_group("Camera Shake")
@export var shake_intensity: float = 0.25  # Force de secousse standard
@export var shake_duration: float = 0.5    # Durée standard de secousse (en secondes)
@export var shake_rotation: float = 5      # Rotation max en degrés (pour plus d'effet)

# --- Variables internes ---
var current_speed: float = 0.0
var is_accelerating: bool = false
var acceleration_timer: float = 0.0
var can_slam: bool = true
var is_slamming: bool = false
var is_frozen: bool = false
var freeze_timer: float = 0.0
var jump_time: float = 0.0

# --- Camera Shake interne ---
var camera: Camera3D
var shake_timer: float = 0.0
var shake_time_total: float = 0.0
var shake_strength: float = 0.0
var shake_rot: float = 0.0
var original_camera_position: Vector3
var original_camera_rotation: Vector3

# --- Gestion des inputs ---
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and not is_frozen:
		rotate_y(-event.relative.x * 0.002)
	if event.is_action_pressed("jump") and is_on_floor() and not is_frozen:
		velocity.y = jump_velocity
		jump_time = 0.0
	if event.is_action_pressed("jump") and not is_on_floor() and jump_time >= min_time_before_slam and can_slam and not is_slamming and not is_frozen:
		is_slamming = true
		velocity.y = slam_velocity

# --- Initialisation ---
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera = $Camera3D
	original_camera_position = camera.position
	original_camera_rotation = camera.rotation_degrees

# --- Camera shake déclenchable de partout ---
func start_camera_shake(intensity: float = -1.0, duration: float = -1.0, rot: float = -1.0) -> void:
	# Si tu veux réutiliser les valeurs par défaut, ne mets pas les paramètres
	# Sinon tu les donnes à l'appel ! (pratique pour explosions etc.)
	shake_strength = intensity if intensity > 0 else shake_intensity
	shake_time_total = duration if duration > 0 else shake_duration
	shake_rot = rot if rot > 0 else shake_rotation
	shake_timer = shake_time_total

# --- Gestion du tremblement à chaque frame ---
func _process(delta: float) -> void:
	if shake_timer > 0:
		# Progression de 0 (début) à 1 (fin)
		var t := 1.0 - (shake_timer / shake_time_total) 
		# Courbe EaseOutElastic pour un effet “punch + amorti”
		var ease := ease_out_elastic(t)
		# Génère un mini offset random sur X et Y, diminuant avec le temps
		var offset = Vector3(
			randf_range(-1, 1) * shake_strength * (1 - ease),
			randf_range(-1, 1) * shake_strength * (1 - ease),
			0
		)
		camera.position = original_camera_position + offset
		# Petite rotation sur Z pour simuler un choc/vertige (optionnel, décommente si tu veux plus discret) :
		camera.rotation_degrees = original_camera_rotation + Vector3(0, 0, randf_range(-1, 1) * shake_rot * (1 - ease))
		shake_timer -= delta
		if shake_timer <= 0:
			camera.position = original_camera_position
			camera.rotation_degrees = original_camera_rotation

# --- Fonction d'atténuation EaseOutElastic ---
func ease_out_elastic(t: float) -> float:
	if t == 0.0 or t == 1.0:
		return t
	var c4 = (2 * PI) / 3
	return pow(2, -10 * t) * sin((t * 10 - 0.75) * c4) + 1

# --- Physique du joueur ---
func _physics_process(delta: float) -> void:
	if is_frozen:
		freeze_timer -= delta
		if freeze_timer <= 0:
			is_frozen = false
			freeze_timer = 0.0
		velocity.x = 0.0
		velocity.z = 0.0
		return

	if not is_on_floor():
		velocity.y += get_gravity().y * delta
		jump_time += delta
	if is_on_floor() and is_slamming:
		is_slamming = false
		is_frozen = true
		freeze_timer = freeze_duration_after_slam
		start_camera_shake() # Déclenche le shake avec valeurs défaut
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction != Vector3.ZERO and not is_frozen:
		if not is_accelerating:
			is_accelerating = true
			acceleration_timer = 0.0
		acceleration_timer += delta
		var speed_ratio = min(acceleration_timer / acceleration_duration, 1.0)
		current_speed = max_speed * speed_ratio
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		is_accelerating = false
		current_speed = 0.0
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()
