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
@export var recoil_intensity: float = 0.03
@export var recoil_duration: float = 0.4
@export var recoil_rotation: float = 1.5
@export var recoil_kickback: float = 0.25

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

# === INITIALISATION ===
func _ready() -> void:
	original_camera_position = position
	original_camera_rotation = rotation_degrees

# === GESTION PRINCIPALE ===
func _process(delta: float) -> void:
	_handle_camera_shake(delta)
	_handle_head_bob(delta)

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
	rotation_degrees = original_camera_rotation + Vector3(0, 0, randf_range(-1, 1) * shake_rot * (1 - elastic))
	shake_timer -= delta
	
	if shake_timer <= 0:
		position = original_camera_position
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
	# Shake de recul avec paramètres spécifiques
	start_camera_shake(recoil_intensity, recoil_duration, recoil_rotation)
	
	# Effet de kickback (recul vers l'arrière)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Recul puis retour à la position normale
	tween.tween_method(_apply_kickback_offset, 0.0, 1.0, recoil_duration * 0.3)
	tween.tween_method(_apply_kickback_offset, 1.0, 0.0, recoil_duration * 0.7)

func _apply_kickback_offset(progress: float) -> void:
	if shake_timer > 0:  # Ne pas interférer avec le shake
		return
		
	var kickback_offset = Vector3(0, 0, recoil_kickback * progress)
	position = original_camera_position + kickback_offset

# === FONCTIONS D'EASING ===
func ease_out_elastic(t: float) -> float:
	if t == 0.0 or t == 1.0:
		return t
	var c4 = (2 * PI) / 3
	return pow(2, shake_elastic_power * t) * sin((t * shake_elastic_cycles - shake_elastic_offset) * c4) + 1

# === FONCTIONS PUBLIQUES POUR LE JOUEUR ===
var current_speed: float = 0.0
