extends CharacterBody3D

# --- Paramètres exportés ---
@export_group("Mouvement")
@export var max_speed: float = 9.5               # Vitesse maximale de déplacement
@export var jump_velocity: float = 6.0           # Vélocité verticale initiale du saut
@export var acceleration_duration: float = 0.5   # Temps pour atteindre la vitesse max
@export var slam_velocity: float = -25.0         # Vélocité verticale lors du slam (écrasement)
@export var freeze_duration_after_slam: float = 0.5  # Durée du freeze après slam (secondes)
@export var min_time_before_slam: float = 0.3    # Temps min après saut avant slam

@export_group("Camera Shake")
@export var shake_intensity: float = 0.25        # Intensité du tremblement de caméra
@export var shake_duration: float = 0.5           # Durée du tremblement (secondes)
@export var shake_rotation: float = 5             # Rotation max en degrés pour le shake

@export_group("Head Bob")
@export var headbob_amplitude: float = 0.05       # Amplitude verticale du balancement (en unités)
@export var headbob_frequency: float = 8.0         # Fréquence du balancement (oscillations par seconde)

# --- Variables internes ---
var current_speed: float = 0.0                      # Vitesse effective du joueur
var is_accelerating: bool = false                   # Indique si on accélère vers la vitesse max
var acceleration_timer: float = 0.0                 # Timer progressif pour accélération
var can_slam: bool = true                            # Capacité à effectuer un slam
var is_slamming: bool = false                        # État d’écrasement en cours
var is_frozen: bool = false                          # Blocage du joueur après slam
var freeze_timer: float = 0.0                        # Timer du blocage après slam
var jump_time: float = 0.0                           # Temps passé en l’air depuis le saut

# --- Camera Shake interne ---
var camera: Camera3D                                 # Référence à la caméra enfant
var shake_timer: float = 0.0                         # Temps restant du tremblement actif
var shake_time_total: float = 0.0                    # Durée totale du tremblement déclenché
var shake_strength: float = 0.0                       # Intensité variable du tremblement
var shake_rot: float = 0.0                             # Rotation max du tremblement
var original_camera_position: Vector3                 # Position de caméra sans décalage
var original_camera_rotation: Vector3                 # Rotation caméra originale

# --- Head Bob interne ---
var headbob_timer: float = 0.0                         # Timer progressif pour oscillations

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

# --- Fonction générique pour déclencher le tremblement de caméra ---
func start_camera_shake(intensity: float = -1.0, duration: float = -1.0, rot: float = -1.0) -> void:
	shake_strength = intensity if intensity > 0 else shake_intensity
	shake_time_total = duration if duration > 0 else shake_duration
	shake_rot = rot if rot > 0 else shake_rotation
	shake_timer = shake_time_total

# --- Gestion du tremblement et du head bob à chaque frame ---
func _process(_delta: float) -> void:
	# -------------------------------------------------------
	# Tremblement de la caméra (camera shake)
	if shake_timer > 0:
		var t := 1.0 - (shake_timer / shake_time_total)
		var elastic := ease_out_elastic(t)  # Courbe d’atténuation élastique
		var offset = Vector3(
			randf_range(-1, 1) * shake_strength * (1 - elastic),
			randf_range(-1, 1) * shake_strength * (1 - elastic),
			0
		)
		camera.position = original_camera_position + offset
		camera.rotation_degrees = original_camera_rotation + Vector3(0, 0, randf_range(-1, 1) * shake_rot * (1 - elastic))
		shake_timer -= _delta
		if shake_timer <= 0:
			camera.position = original_camera_position
			camera.rotation_degrees = original_camera_rotation
	
	# -------------------------------------------------------
	# Head Bob (balancement de la caméra en marche)
	elif not is_frozen and current_speed > 0:
		headbob_timer += _delta
		
		# Balancement vertical en forme de "U" : valeur absolue du sinus
		var bob_offset_y = abs(sin(headbob_timer * headbob_frequency)) * headbob_amplitude
		
		# Balancement horizontal classique sinusoidal pour fluidité
		var bob_offset_x = sin(headbob_timer * headbob_frequency * 2) * headbob_amplitude * 0.5
		
		camera.position = original_camera_position + Vector3(bob_offset_x, bob_offset_y, 0)
	else:
		# Remise à la position originale quand on ne bouge pas ou freeze
		headbob_timer = 0.0
		camera.position = original_camera_position

# --- Fonction d'atténuation EaseOutElastic pour la courbe du shake ---
func ease_out_elastic(t: float) -> float:
	if t == 0.0 or t == 1.0:
		return t
	var c4 = (2 * PI) / 3
	return pow(2, -10 * t) * sin((t * 10 - 0.75) * c4) + 1

# --- Mise à jour de la physique du joueur ---
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
		start_camera_shake()
	
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
