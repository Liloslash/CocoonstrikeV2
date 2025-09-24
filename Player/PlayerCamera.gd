extends Camera3D
class_name PlayerCamera

# === PARAMÈTRES EXPORTÉS ===
@export_group("Camera Shake")
@export var shake_intensity: float = 0.8
@export var shake_duration: float = 0.8
@export var shake_rotation: float = 5
@export var shake_elastic_power: float = -10.0
@export var shake_elastic_cycles: float = 10.0
@export var shake_elastic_offset: float = 0.75

@export_group("Head Bob")
@export var headbob_amplitude: float = 0.06
@export var headbob_frequency: float = 6.0
@export var headbob_frequency_multiplier: float = 2.0

@export_group("Effets de Tir")
@export var recoil_intensity: float = 0.09
@export var recoil_duration: float = 0.15
@export var recoil_rotation: float = 1.5
@export var recoil_kickback: float = 0.5
@export var recoil_variation: float = 0.5  # Variation aléatoire (50% de variation)

@export_group("Jump Look Down")
@export var jump_look_angle: float = 25.0  # Angle d'inclinaison vers le bas
@export var jump_look_smoothness: float = 4.0  # Vitesse de transition

# === RÉFÉRENCES ===
var original_camera_position: Vector3
var original_camera_rotation: Vector3

# === VARIABLES INTERNES ===
# Camera Shake
var shake_timer: float = 0.0
var shake_time_total: float = 0.0
var shake_strength: float = 0.0
var shake_rot: float = 0.0

# Head Bob
var headbob_timer: float = 0.0

# Jump Look Down
var is_jumping: bool = false
var jump_start_height: float = 0.0
var jump_max_height: float = 0.0
var player_node: CharacterBody3D

# Effets de Tir
var _current_kickback: float = 0.0

# === INITIALISATION ===
func _ready() -> void:
	original_camera_position = position
	original_camera_rotation = rotation_degrees
	# Récupérer la référence au joueur
	player_node = get_parent() as CharacterBody3D

# === GESTION PRINCIPALE ===
func _process(delta: float) -> void:
	# Récupérer la vitesse actuelle du joueur via PlayerMovement
	var movement_component = player_node.get_node_or_null("PlayerMovement")
	if movement_component and movement_component.has_method("get_current_speed"):
		current_speed = movement_component.get_current_speed()
	
	_handle_camera_shake(delta)
	_handle_head_bob(delta)
	_handle_jump_look_down(delta)

# === CAMERA SHAKE ===
func start_camera_shake(intensity: float = -1.0, duration: float = -1.0, rot: float = -1.0) -> void:
	shake_strength = intensity if intensity > 0 else shake_intensity
	shake_time_total = duration if duration > 0 else shake_duration
	shake_rot = rot if rot > 0 else shake_rotation
	shake_timer = shake_time_total

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
	position = original_camera_position + offset
	
	# Appliquer le shake de rotation seulement si on n'est pas en saut
	if not is_jumping:
		rotation_degrees = original_camera_rotation + Vector3(0, 0, randf_range(-1, 1) * shake_rot * (1 - elastic))
	
	shake_timer -= delta
	
	if shake_timer <= 0:
		position = original_camera_position
		# Ne pas remettre la rotation à original_camera_rotation si on est en saut
		if not is_jumping:
			rotation_degrees = original_camera_rotation

# === HEAD BOB ===
func _handle_head_bob(delta: float) -> void:
	if current_speed <= 0 or shake_timer > 0:
		headbob_timer = 0.0
		if shake_timer <= 0:
			position = original_camera_position
		return
		
	headbob_timer += delta
	var bob_offset_y = abs(sin(headbob_timer * headbob_frequency)) * headbob_amplitude
	var bob_offset_x = sin(headbob_timer * headbob_frequency * headbob_frequency_multiplier) * headbob_amplitude * 0.5
	position = original_camera_position + Vector3(bob_offset_x, bob_offset_y, 0)

# === EFFETS DE TIR ===
func trigger_recoil() -> void:
	# Ajouter de la variation aléatoire aux paramètres
	var variation_factor = randf_range(1.0 - recoil_variation, 1.0 + recoil_variation)
	var current_intensity = recoil_intensity * variation_factor
	var current_duration = recoil_duration * variation_factor
	var current_rotation = recoil_rotation * variation_factor
	var current_kickback = recoil_kickback * variation_factor
	
	# Shake de recul avec paramètres variables
	start_camera_shake(current_intensity, current_duration, current_rotation)
	
	# Ne pas créer l'effet de kickback si on est en saut
	if is_jumping:
		return
	
	# Effet de kickback (recul vers l'arrière) avec variation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Stocker le kickback variable pour _apply_kickback_offset
	_current_kickback = current_kickback
	
	# Recul puis retour à la position normale
	tween.tween_method(_apply_kickback_offset, 0.0, 1.0, current_duration * 0.3)
	tween.tween_method(_apply_kickback_offset, 1.0, 0.0, current_duration * 0.7)

func _apply_kickback_offset(progress: float) -> void:
	if shake_timer > 0:  # Ne pas interférer avec le shake
		return
		
	var kickback_offset = Vector3(0, 0, _current_kickback * progress)
	position = original_camera_position + kickback_offset

# === FONCTIONS D'EASING ===
func ease_out_elastic(t: float) -> float:
	if t == 0.0 or t == 1.0:
		return t
	var c4 = (2 * PI) / 3
	return pow(2, shake_elastic_power * t) * sin((t * shake_elastic_cycles - shake_elastic_offset) * c4) + 1

# === JUMP LOOK DOWN ===
func start_jump_look_down(start_height: float) -> void:
	is_jumping = true
	jump_start_height = start_height
	jump_max_height = start_height  # Sera mis à jour pendant le saut

func stop_jump_look_down() -> void:
	is_jumping = false
	# Ne pas remettre brutalement à 0, laisser la transition naturelle se faire

func reset_jump_look_down() -> void:
	is_jumping = false
	jump_start_height = 0.0
	jump_max_height = 0.0
	# Remettre la rotation à la normale immédiatement
	rotation_degrees.x = original_camera_rotation.x

func update_jump_height(current_height: float) -> void:
	if is_jumping and current_height > jump_max_height:
		jump_max_height = current_height

func _handle_jump_look_down(delta: float) -> void:
	if not player_node or jump_max_height <= jump_start_height:
		return
		
	# Calculer le progrès du saut (0 = début, 0.5 = milieu, 1.0 = sommet)
	var current_height = player_node.global_position.y
	var height_range = jump_max_height - jump_start_height
	
	# Éviter la division par zéro
	if height_range <= 0.0:
		return
		
	var height_progress = (current_height - jump_start_height) / height_range
	
	if is_jumping:
		# Pendant le saut
		# Commencer l'inclinaison à partir de la moitié du saut
		if height_progress >= 0.5:
			# Calculer le progrès de l'inclinaison (0 = milieu du saut, 1.0 = sommet)
			var look_progress = (height_progress - 0.5) / 0.5
			look_progress = clamp(look_progress, 0.0, 1.0)
			
			# Appliquer l'inclinaison avec une transition douce
			var target_angle = original_camera_rotation.x - (jump_look_angle * look_progress)
			var current_angle = rotation_degrees.x
			
			# Transition douce vers l'angle cible
			rotation_degrees.x = lerp(current_angle, target_angle, jump_look_smoothness * delta)
		else:
			# Avant la moitié du saut, maintenir l'angle original
			rotation_degrees.x = lerp(rotation_degrees.x, original_camera_rotation.x, jump_look_smoothness * delta)
	else:
		# Après l'atterrissage, retour doux à la position normale
		rotation_degrees.x = lerp(rotation_degrees.x, original_camera_rotation.x, jump_look_smoothness * delta)

# === FONCTIONS PUBLIQUES POUR LE JOUEUR ===
var current_speed: float = 0.0  # Vitesse actuelle du joueur (assignée depuis l'extérieur)
