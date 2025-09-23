extends CharacterBody3D

# --- Paramètres exportés ---
@export_group("Mouvement")
@export var max_speed: float = 9.5
@export var acceleration_duration: float = 0.4
@export var slam_velocity: float = -33.0
@export var freeze_duration_after_slam: float = 0.3
@export var min_time_before_slam: float = 0.4

@export_group("Jump Boost")
@export var jump_boost_duration: float = 0.5  # Durée de la poussée rapide
@export var jump_boost_velocity: float = 25.0  # Force de la poussée initiale
@export var jump_boost_force_multiplier: float = 5.0  # Multiplicateur de force maximale
@export var jump_gravity_multiplier: float = 0.6  # Gravité réduite pendant la montée
@export var jump_hover_duration: float = 0.03  # Temps de flottement au sommet
@export var max_jump_height: float = 2.1  # Hauteur maximale relative au point de saut
@export var fall_gravity_multiplier: float = 1.1  # Multiplicateur de gravité pour la chute

@export_group("Contrôles")
@export var mouse_sensitivity: float = 0.002

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

@export_group("Combat")
@export var revolver_damage: int = 25  # Dégâts du revolver

# --- Variables internes ---
var current_speed: float = 0.0
var is_accelerating: bool = false
var acceleration_timer: float = 0.0
var can_slam: bool = true
var is_slamming: bool = false
var is_frozen: bool = false
var freeze_timer: float = 0.0
var jump_time: float = 0.0

# --- Variables Jump Boost ---
var is_jump_boosting: bool = false
var jump_boost_timer: float = 0.0
var jump_start_height: float = 0.0  # Hauteur Y du point de départ du saut
var jump_boost_force: float = 0.0  # Force d'accélération progressive

# --- Variables Hover (Flottement) ---
var is_hovering: bool = false
var hover_timer: float = 0.0

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

# --- Effet d'impact ---
const IMPACT_EFFECT_SCENE = preload("res://Effects/ImpactEffect.tscn")

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
		_start_jump_boost()
		jump_time = 0.0
		
	if event.is_action_pressed("slam") and not is_on_floor() and jump_time >= min_time_before_slam and can_slam and not is_slamming and not is_frozen:
		is_slamming = true
		velocity.y = slam_velocity
		# Arrêter le flottement si on slam
		if is_hovering:
			is_hovering = false
			hover_timer = 0.0

# --- Initialisation ---
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera = $Camera3D
	original_camera_position = camera.position
	original_camera_rotation = camera.rotation_degrees
	
	# S'assurer que le RayCast3D est correctement configuré
	if not raycast:
		# Créer si manquant (sécurité)
		raycast = RayCast3D.new()
		camera.add_child(raycast)
	# Configuration robuste même s'il existe déjà dans la scène
	raycast.target_position = Vector3(0, 0, -1000)  # Portée vers l'avant
	raycast.enabled = true
	raycast.collision_mask = 2  # Ne détecter que la layer 2 (ennemis)
	if raycast.has_method("set_exclude_parent_body"):
		# Godot 4 expose exclude_parent comme propriété, mais on garde une compat de méthode
		raycast.set_exclude_parent_body(true)
	elif "exclude_parent" in raycast:
		raycast.exclude_parent = true
	
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
	# Mettre à jour immédiatement le raycast pour éviter un frame de retard
	raycast.force_raycast_update()
	
	if not raycast.is_colliding():
		return
		
	var collider = raycast.get_collider()
	
	if not collider or not collider.has_method("take_damage"):
		return
		
	collider.take_damage(revolver_damage)
	
	# Créer l'effet d'impact au point de collision
	_create_impact_effect(raycast.get_collision_point(), collider)

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

# --- Création de l'effet d'impact ---
func _create_impact_effect(impact_position: Vector3, target_collider: Node):
	var impact_effect = IMPACT_EFFECT_SCENE.instantiate()
	get_tree().current_scene.add_child(impact_effect)
	impact_effect.global_position = impact_position
	
	# Récupérer les couleurs d'impact de l'ennemi touché
	if target_collider.has_method("get_impact_colors"):
		var impact_colors = target_collider.get_impact_colors()
		if impact_colors.size() >= 4:
			impact_effect.set_impact_colors(impact_colors)

# --- Fonction pour trouver le sprite dans un ennemi ---
func _find_sprite_in_target(target: Node) -> Node:
	# Chercher un AnimatedSprite3D dans la cible
	var animated_sprite = target.get_node_or_null("AnimatedSprite3D")
	if animated_sprite:
		return animated_sprite
	
	# Chercher récursivement dans les enfants
	for child in target.get_children():
		var sprite = _find_sprite_in_target(child)
		if sprite:
			return sprite
	
	return null

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
		_handle_jump_boost(delta)
		jump_time += delta
	else:
		# Réinitialiser tous les états de saut à l'atterrissage SEULEMENT si on n'est pas en train de sauter
		if not is_jump_boosting and not is_hovering:
			_reset_jump_states()

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

# --- Fonctions Jump Boost ---

# --- Démarrage du boost de saut ---
func _start_jump_boost() -> void:
	is_jump_boosting = true
	jump_boost_timer = 0.0
	jump_start_height = global_position.y  # Enregistrer la hauteur de départ
	jump_boost_force = 0.0  # Commencer avec une force nulle
	# Commencer avec une vitesse initiale plus forte
	velocity.y = jump_boost_velocity * 0.3

# --- Réinitialisation des états de saut ---
func _reset_jump_states() -> void:
	is_jump_boosting = false
	jump_boost_timer = 0.0
	jump_boost_force = 0.0
	is_hovering = false
	hover_timer = 0.0
	jump_start_height = 0.0

# --- Gestion du boost de saut ---
func _handle_jump_boost(delta: float) -> void:
	if is_jump_boosting:
		jump_boost_timer += delta
		
		# Calculer la hauteur actuelle par rapport au point de départ
		var current_height_above_start = global_position.y - jump_start_height
		
		# Si on a atteint ou dépassé la hauteur maximale, commencer le flottement
		if current_height_above_start >= max_jump_height:
			is_jump_boosting = false
			is_hovering = true
			hover_timer = 0.0
			velocity.y = 0.0  # Arrêter la montée
			return
		
		# Phase 1: Force d'accélération progressive
		if jump_boost_timer <= jump_boost_duration:
			# Calculer la force d'accélération progressive
			var boost_progress = jump_boost_timer / jump_boost_duration
			var target_force = jump_boost_velocity * jump_boost_force_multiplier  # Force maximale
			
			# Accélération progressive de la force (ease-in quad)
			jump_boost_force = target_force * ease_in_quad(boost_progress)
			
			# Appliquer la force d'accélération (ajouter à la vitesse existante)
			velocity.y += jump_boost_force * delta
		else:
			# Phase 2: Gravité normale après le boost (mais on reste en boost jusqu'à la hauteur max)
			velocity.y += get_gravity().y * delta
	
	elif is_hovering:
		# Phase 3: Flottement au sommet
		hover_timer += delta
		
		
		# Maintenir la vitesse verticale à 0 (flottement parfait)
		velocity.y = 0.0
		
		# Si le temps de flottement est écoulé, arrêter le flottement
		if hover_timer >= jump_hover_duration:
			is_hovering = false
			hover_timer = 0.0
	else:
		# Gravité normale quand pas de boost ni de flottement
		velocity.y += get_gravity().y * fall_gravity_multiplier * delta

# --- Fonctions d'easing ---
func ease_out_quad(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)

func ease_out_expo(t: float) -> float:
	return 1.0 - pow(2.0, -10.0 * t)

func ease_in_expo(t: float) -> float:
	return pow(2.0, 10.0 * (t - 1.0))

func ease_in_quad(t: float) -> float:
	return t * t
