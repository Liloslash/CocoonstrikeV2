extends CharacterBody3D

# --- Paramètres exportés ---
@export_group("Mouvement")
@export var max_speed: float = 9.5  # Vitesse maximale de déplacement
@export var jump_velocity: float = 6.0  # Vitesse initiale du saut (augmentée pour une phase descendante plus longue)
@export var acceleration_duration: float = 0.5  # Temps pour atteindre la vitesse maximale
@export var slam_velocity: float = -25.0  # Vitesse verticale pour l'écrasement (négative)

# --- Variables internes ---
var current_speed: float = 0.0  # Vitesse actuelle (0 à max_speed)
var is_accelerating: bool = false  # Indique si le personnage accélère
var acceleration_timer: float = 0.0  # Temps écoulé depuis le début de l'accélération
var can_slam: bool = true  # Active la capacité d'écrasement (à désactiver en début de jeu)
var is_slamming: bool = false  # Indique si le personnage est en train d'effectuer un écrasement

# --- Gestion des inputs ---
func _input(event: InputEvent) -> void:
	# Libérer le curseur avec la touche ESC
	if event.is_action_pressed("esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Rotation horizontale avec la souris
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.002)
	# Saut initial
	if event.is_action_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	# Déclencher l'écrasement en phase descendante
	if event.is_action_pressed("jump") and !is_on_floor() and velocity.y < 0 and can_slam and !is_slamming:
		is_slamming = true
		velocity.y = slam_velocity

# --- Initialisation ---
func _ready() -> void:
	# Capturer le curseur pour le jeu
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# --- Mise à jour de la physique ---
func _physics_process(delta: float) -> void:
	# Appliquer la gravité si le personnage n'est pas au sol
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	# Réinitialiser l'état d'écrasement à l'atterrissage
	if is_on_floor() and is_slamming:
		is_slamming = false

	# Gestion du déplacement horizontal
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		# Démarrer l'accélération
		if not is_accelerating:
			is_accelerating = true
			acceleration_timer = 0.0
		# Augmenter progressivement la vitesse
		acceleration_timer += delta
		var speed_ratio = min(acceleration_timer / acceleration_duration, 1.0)
		current_speed = max_speed * speed_ratio
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		# Arrêt immédiat
		is_accelerating = false
		current_speed = 0.0
		velocity.x = 0.0
		velocity.z = 0.0

	# Appliquer le déplacement et les collisions
	move_and_slide()
