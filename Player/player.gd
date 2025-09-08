extends CharacterBody3D

# --- Paramètres exportés ---
@export_group("Mouvement")
@export var max_speed: float = 9.5
@export var jump_velocity: float = 6.0
@export var acceleration_duration: float = 0.5
@export var slam_velocity: float = -25.0
@export var freeze_duration_after_slam: float = 0.5
@export var min_time_before_slam: float = 0.3

@export_group("Contrôles")
@export var mouse_sensitivity: float = 0.002

@export_group("Camera Shake")
@export var shake_intensity: float = 0.25
@export var shake_duration: float = 0.5
@export var shake_rotation: float = 5
@export var shake_elastic_power: float = -10.0
@export var shake_elastic_cycles: float = 10.0
@export var shake_elastic_offset: float = 0.75

@export_group("Head Bob")
@export var headbob_amplitude: float = 0.05
@export var headbob_frequency: float = 8.0
@export var headbob_frequency_multiplier: float = 2.0

@export_group("Effets de Tir")
@export var recoil_intensity: float = 0.15
@export var recoil_duration: float = 0.2
@export var recoil_rotation: float = 3.0
@export var recoil_kickback: float = 0.08

@export_group("Combat")
@export var revolver_damage: int = 50  # Dégâts du revolver

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

# --- Head Bob interne ---
var headbob_timer: float = 0.0

# --- Combat ---
@onready var raycast: RayCast3D = $Camera3D/RayCast3D  # Raycast pour les tirs

# --- Référence au revolver dans le HUD ---
@onready var revolver_sprite = $HUD_Layer/Revolver
var revolver_connected: bool = false

# --- Gestion des inputs ---
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if event is InputEventMouseMotion and not is_frozen:
		rotate_y(-event.relative.x * mouse_sensitivity)
		
	if event.is_action_pressed("jump") and is_on_floor() and not is_frozen:
		velocity.y = jump_velocity
		jump_time = 0.0
		
	if event.is_action_pressed("slam") and not is_on_floor() and jump_time >= min_time_before_slam and can_slam and not is_slamming and not is_frozen:
		is_slamming = true
		velocity.y = slam_velocity

# --- Initialisation ---
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera = $Camera3D
	original_camera_position = camera.position
	original_camera_rotation = camera.rotation_degrees
	
	# Créer le raycast s'il n'existe pas
	if not raycast:
		raycast = RayCast3D.new()
		camera.add_child(raycast)
		raycast.target_position = Vector3(0, 0, -100)  # 100 unités vers l'avant
		raycast.enabled = true
		# Configurer pour ignorer la Map (layer 1) et ne détecter que layer 2
		raycast.collision_mask = 2  # Ne détecte que la layer 2
	
	# Connexion du signal de tir du revolver avec vérification
	if revolver_sprite:
		revolver_sprite.shot_fired.connect(_trigger_recoil)
		revolver_sprite.shot_fired.connect(_handle_shot)  # Connexion pour les dégâts
		revolver_connected = true
	else:
		push_error("Revolver sprite non trouvé dans HUD_Layer/Revolver")
		revolver_connected = false

# --- Fonction générique pour déclencher le tremblement de caméra ---
func start_camera_shake(intensity: float = -1.0, duration: float = -1.0, rot: float = -1.0) -> void:
	shake_strength = intensity if intensity > 0 else shake_intensity
	shake_time_total = duration if duration > 0 else shake_duration
	shake_rot = rot if rot > 0 else shake_rotation
	shake_timer = shake_time_total

# --- Gestion du tremblement, head bob et détection tir ---
func _process(_delta: float) -> void:
	_handle_camera_shake(_delta)
	_handle_head_bob(_delta)
	_handle_shooting()

# --- Gestion séparée du camera shake ---
func _handle_camera_shake(delta: float) -> void:
	if shake_timer <= 0:
		return
		
	var t := 1.0 - (shake_timer / shake_time_total)
	var elastic := ease_out_elastic(t)
	var offset = Vector3(
		randf_range(-1, 1) * shake_strength * (1 - elastic),
		randf_range(-1, 1) * shake_strength * (1 - elastic),
		0
	)
	camera.position = original_camera_position + offset
	camera.rotation_degrees = original_camera_rotation + Vector3(0, 0, randf_range(-1, 1) * shake_rot * (1 - elastic))
	shake_timer -= delta
	
	if shake_timer <= 0:
		camera.position = original_camera_position
		camera.rotation_degrees = original_camera_rotation

# --- Gestion séparée du head bob ---
func _handle_head_bob(delta: float) -> void:
	if is_frozen or current_speed <= 0 or shake_timer > 0:
		headbob_timer = 0.0
		if shake_timer <= 0:
			camera.position = original_camera_position
		return
		
	headbob_timer += delta
	var bob_offset_y = abs(sin(headbob_timer * headbob_frequency)) * headbob_amplitude
	var bob_offset_x = sin(headbob_timer * headbob_frequency * headbob_frequency_multiplier) * headbob_amplitude * 0.5
	camera.position = original_camera_position + Vector3(bob_offset_x, bob_offset_y, 0)

# --- Gestion séparée du tir et rechargement ---
func _handle_shooting() -> void:
	if not revolver_connected:
		return
		
	# Gestion du tir
	if Input.is_action_just_pressed("shot"):
		revolver_sprite.play_shot_animation()
		# Le recul sera déclenché par le signal shot_fired du revolver
	
	# Gestion du rechargement - délégué entièrement au revolver
	if Input.is_action_just_pressed("reload"):
		revolver_sprite.start_reload()

# --- Gestion du tir avec Raycast ---
func _handle_shot() -> void:
	print("_handle_shot() appelée !")
	
	if not raycast.is_colliding():
		print("Raycast ne touche rien")
		return
		
	print("Raycast en collision !")
	var collider = raycast.get_collider()
	print("Collider: ", collider)
	
	if not collider or not collider.has_method("take_damage"):
		print("Collider n'a pas de méthode take_damage")
		return
		
	print("Ennemi a la méthode take_damage, envoi des dégâts...")
	collider.take_damage(revolver_damage)
	print("Ennemi touché pour ", revolver_damage, " dégâts!")

# --- Effet de recul lors du tir ---
func _trigger_recoil() -> void:
	# Shake de recul avec paramètres spécifiques
	start_camera_shake(recoil_intensity, recoil_duration, recoil_rotation)
	
	# Effet de kickback (recul vers l'arrière)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Recul puis retour à la position normale
	tween.tween_method(_apply_kickback_offset, 0.0, 1.0, recoil_duration * 0.3)
	tween.tween_method(_apply_kickback_offset, 1.0, 0.0, recoil_duration * 0.7)

# --- Application de l'offset de kickback ---
func _apply_kickback_offset(progress: float) -> void:
	if shake_timer > 0:  # Ne pas interférer avec le shake
		return
		
	var kickback_offset = Vector3(0, 0, recoil_kickback * progress)
	camera.position = original_camera_position + kickback_offset

# --- Fonction d'atténuation EaseOutElastic pour la courbe du shake ---
func ease_out_elastic(t: float) -> float:
	if t == 0.0 or t == 1.0:
		return t
	var c4 = (2 * PI) / 3
	return pow(2, shake_elastic_power * t) * sin((t * shake_elastic_cycles - shake_elastic_offset) * c4) + 1

# --- Mise à jour de la physique du joueur ---
func _physics_process(delta: float) -> void:
	_handle_freeze_state(delta)
	
	if is_frozen:
		return
		
	_handle_gravity_and_jump(delta)
	_handle_slam_landing()
	_handle_movement(delta)
	
	move_and_slide()

# --- Gestion de l'état de freeze ---
func _handle_freeze_state(delta: float) -> void:
	if not is_frozen:
		return
		
	freeze_timer -= delta
	if freeze_timer <= 0:
		is_frozen = false
		freeze_timer = 0.0
	velocity.x = 0.0
	velocity.z = 0.0

# --- Gestion de la gravité et du saut ---
func _handle_gravity_and_jump(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
		jump_time += delta

# --- Gestion de l'atterrissage après slam ---
func _handle_slam_landing() -> void:
	if not (is_on_floor() and is_slamming):
		return
		
	is_slamming = false
	is_frozen = true
	freeze_timer = freeze_duration_after_slam
	start_camera_shake()

# --- Gestion du mouvement horizontal (VERSION REFACTORISÉE) ---
func _handle_movement(delta: float) -> void:
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	# Early return - si pas d'input ou frozen, arrêter le mouvement
	if input_dir == Vector2.ZERO or is_frozen:
		is_accelerating = false
		current_speed = 0.0
		velocity.x = 0.0
		velocity.z = 0.0
		return
	
	# Calculer la direction de mouvement
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Gérer l'accélération
	if not is_accelerating:
		is_accelerating = true
		acceleration_timer = 0.0
	
	acceleration_timer += delta
	var speed_ratio = min(acceleration_timer / acceleration_duration, 1.0)
	current_speed = max_speed * speed_ratio
	
	# Appliquer la vitesse
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
