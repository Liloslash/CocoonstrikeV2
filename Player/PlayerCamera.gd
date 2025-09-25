extends Camera3D
class_name PlayerCamera

# === PARAMÈTRES EXPORTÉS ===
@export_group("Camera Shake")
@export var shake_intensity: float = 0.8
@export var shake_duration: float = 0.8
@export var shake_rotation: float = 5

@export_group("Head Bob")
@export var headbob_amplitude: float = 0.06
@export var headbob_frequency: float = 6.0

# === PARAMÈTRES HEAD BOB SIMPLIFIÉS ===
@export var headbob_transition_speed: float = 5.0  # Vitesse de transition fluide
@export var headbob_x_phase_offset: float = 0.5  # Décalage de phase pour le mouvement X

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
var current_speed: float = 0.0  # Vitesse actuelle du joueur (assignée depuis l'extérieur)

# === VARIABLES INTERNES ===
# Système de tremblements multiples
var active_shakes: Array = []  # Liste des tremblements actifs

# Head Bob
var headbob_timer: float = 0.0
var headbob_active: bool = false
var headbob_transition_progress: float = 0.0

# Jump Look Down
var is_jumping: bool = false
var jump_start_height: float = 0.0
var jump_max_height: float = 0.0
var player_node: CharacterBody3D

# Effets de Tir
var _current_kickback: float = 0.0

# === RÉFÉRENCES CACHÉES ===
var movement_component: PlayerMovement

# === INITIALISATION ===
func _ready() -> void:
	original_camera_position = position
	original_camera_rotation = rotation_degrees
	player_node = get_parent() as CharacterBody3D
	movement_component = player_node.get_node_or_null("PlayerMovement")

# === GESTION PRINCIPALE ===
func _process(delta: float) -> void:
	# Récupérer la vitesse actuelle du joueur
	if movement_component:
		current_speed = movement_component.get_current_speed()
	
	_handle_camera_shake(delta)
	_handle_head_bob(delta)
	_handle_jump_look_down(delta)

# === CAMERA SHAKE ===
func start_camera_shake(intensity: float = -1.0, duration: float = -1.0, rot: float = -1.0) -> void:
	# Créer un nouveau tremblement
	var new_shake = {
		"strength": intensity if intensity > 0 else shake_intensity,
		"duration": duration if duration > 0 else shake_duration,
		"rotation": rot if rot > 0 else shake_rotation,
		"timer": duration if duration > 0 else shake_duration,
		"time_total": duration if duration > 0 else shake_duration
	}
	
	# Ajouter à la liste des tremblements actifs
	active_shakes.append(new_shake)

func _handle_camera_shake(delta: float) -> void:
	if active_shakes.is_empty():
		return
	
	var total_offset = Vector3.ZERO
	var total_rotation = 0.0
	
	# Parcourir tous les tremblements actifs
	for i in range(active_shakes.size() - 1, -1, -1):
		var shake = active_shakes[i]
		
		# Calculer le progrès du tremblement
		var t: float = 1.0 - (shake.timer / shake.time_total)
		var cubic := ease_out_cubic(t)
		
		# Ajouter l'offset de ce tremblement au total
		var shake_offset = Vector3(
			randf_range(-1, 1) * shake.strength * (1 - cubic),
			randf_range(-1, 1) * shake.strength * (1 - cubic),
			0
		)
		total_offset += shake_offset
		
		# Ajouter la rotation si on n'est pas en saut
		if not is_jumping:
			total_rotation += randf_range(-1, 1) * shake.rotation * (1 - cubic)
		
		# Décrémenter le timer
		shake.timer -= delta
		
		# Supprimer le tremblement s'il est terminé
		if shake.timer <= 0:
			active_shakes.remove_at(i)
	
	# Appliquer l'offset total
	position = original_camera_position + total_offset
	
	# Appliquer la rotation totale seulement si on n'est pas en saut
	if not is_jumping:
		rotation_degrees = original_camera_rotation + Vector3(0, 0, total_rotation)
	
	# Si plus de tremblements actifs, remettre à la position originale
	if active_shakes.is_empty():
		position = original_camera_position
		if not is_jumping:
			rotation_degrees = original_camera_rotation

# === HEAD BOB SIMPLIFIÉ ===
func _handle_head_bob(delta: float) -> void:
	var should_be_active = current_speed > 0 and active_shakes.is_empty()
	
	# Gestion des transitions fluides
	if should_be_active and not headbob_active:
		headbob_active = true
		headbob_transition_progress = 0.0
	elif not should_be_active and headbob_active:
		headbob_active = false
		headbob_transition_progress = 1.0
	
	# Mise à jour du progrès de transition
	if headbob_active:
		headbob_transition_progress = min(headbob_transition_progress + delta * headbob_transition_speed, 1.0)
	else:
		headbob_transition_progress = max(headbob_transition_progress - delta * headbob_transition_speed, 0.0)
	
	# Si pas de mouvement et transition terminée, remettre à la position originale
	# MAIS seulement si il n'y a pas de camera shake actif
	if not headbob_active and headbob_transition_progress <= 0:
		if active_shakes.is_empty():  # Ne pas interférer avec le shake
			position = original_camera_position
		return
	
	# Si pas de transition active, ne pas appliquer le head bob
	if headbob_transition_progress <= 0:
		return
	
	# Mise à jour du timer
	if headbob_active:
		headbob_timer += delta
	
	# Calcul des mouvements réalistes de marche
	var bob_phase = headbob_timer * headbob_frequency
	
	# Mouvement Y : la tête descend quand le pied touche le sol (sin négatif)
	var bob_offset_y = -sin(bob_phase) * headbob_amplitude
	
	# Mouvement X : oscillation latérale naturelle, décalée de phase
	var bob_phase_x = bob_phase + (headbob_x_phase_offset * PI)
	var bob_offset_x = sin(bob_phase_x) * headbob_amplitude * 0.5
	
	# Application du mouvement avec transition fluide
	var smooth_transition = ease_out_cubic(headbob_transition_progress)
	var headbob_offset = Vector3(
		bob_offset_x * smooth_transition,
		bob_offset_y * smooth_transition,
		0
	)
	position = original_camera_position + headbob_offset

# === FONCTIONS UTILITAIRES ===
func ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)

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
	if not active_shakes.is_empty():  # Ne pas interférer avec le shake
		return
		
	var kickback_offset = Vector3(0, 0, _current_kickback * progress)
	position = original_camera_position + kickback_offset


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
