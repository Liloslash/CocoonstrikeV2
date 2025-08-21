# PlayerMovement.gd
extends RefCounted

@export var max_speed: float = 9.5
@export var jump_velocity: float = 4.5

var player: CharacterBody3D
var current_speed: float = 0.0  # Vitesse actuelle (0 à max_speed)
var is_accelerating: bool = false
var acceleration_timer: float = 0.0
var acceleration_duration: float = 0.5  # 0.5 seconde pour atteindre max_speed

func _init(p_player: CharacterBody3D) -> void:
	player = p_player

func update(delta: float) -> void:
	# Appliquer la gravité
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta

	# Récupérer l'input de direction
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		# Démarrer l'accélération si ce n'est pas déjà fait
		if not is_accelerating:
			is_accelerating = true
			acceleration_timer = 0.0

		# Augmenter progressivement la vitesse
		acceleration_timer += delta
		var speed_ratio = min(acceleration_timer / acceleration_duration, 1.0)
		current_speed = max_speed * speed_ratio

		# Appliquer la vitesse actuelle
		player.velocity.x = direction.x * current_speed
		player.velocity.z = direction.z * current_speed
	else:
		# Arrêt immédiat
		is_accelerating = false
		current_speed = 0.0
		player.velocity.x = 0.0
		player.velocity.z = 0.0

	player.move_and_slide()

func handle_input(event: InputEvent) -> void:
	# Gestion du saut
	if event.is_action_pressed("ui_accept") and player.is_on_floor():
		player.velocity.y = jump_velocity
