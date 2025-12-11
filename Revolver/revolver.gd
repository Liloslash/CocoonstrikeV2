extends AnimatedSprite2D
class_name Revolver

# Signal émis au moment exact du tir
signal shot_fired

# === PARAMÈTRES EXPORTÉS ===
@export_group("Animation")
@export var tween_duration := 0.12  # Durée du tween de position

@export_group("Ammunition")
@export var max_ammo: int = 6       # Maximum de balles (6 coups)
@export var start_ammo: int = 6     # Munitions au début

@export_group("Reload Animation")
@export var reload_offset_y: float = 170.0  # Distance vers le bas pour le rechargement (réduit de 15%)
@export var reload_down_duration: float = 0.3   # Durée pour descendre l'arme
@export var reload_up_duration: float = 0.3     # Durée pour remonter l'arme
@export var interrupt_up_duration: float = 0.2  # Durée pour remonter en cas d'interruption

@export_group("Shooting")
@export var fire_rate: float = 0.5  # Délai minimum entre deux tirs (en secondes)
@export var shot_detection_frame: int = 2  # Frame où le tir se déclenche dans l'animation

@export_group("Hit Effect")
@export var hit_shake_duration: float = 0.15  # Durée de la vibration sur l'ennemi
@export var hit_shake_intensity: float = 0.06  # Intensité de la vibration (en unités)
@export var hit_shake_frequency: float = 75.0  # Fréquence de la vibration (oscillations par seconde)
@export var hit_shake_axes: Vector3 = Vector3(1.0, 1.0, 0.0)  # Axes de vibration (X, Y, Z)

@export_group("Reload Shake")
@export var shake_intensity: float = 3.0  # Intensité du tremblement (en pixels)
@export var shake_duration: float = 0.15  # Durée du tremblement pour chaque balle
@export var shake_frequency: float = 20.0  # Fréquence du tremblement (oscillations par seconde)


@export_group("Sway System")
@export var idle_sway_amplitude: Vector3 = Vector3(2.0, 0.5, 0.5)  # Amplitude du sway idle (X, Y, Z)
@export var idle_sway_frequency: float = 1.0  # Fréquence du sway idle (Hz)
@export var movement_sway_amplitude: Vector3 = Vector3(9.0, 1.0, 2.0)  # Amplitude du sway movement (X, Y, Z)
@export var movement_sway_frequency: float = 5.0  # Fréquence du sway movement (Hz)
@export var sway_transition_speed: float = 3.0  # Vitesse de transition entre idle/movement


@onready var animation_player = $AnimationPlayer
var base_position: Vector2

# === SYSTÈME DE SWAY ===
var is_sway_active: bool = false
var current_sway_amplitude: Vector3 = Vector3.ZERO
var current_sway_frequency: float = 0.0
var sway_time: float = 0.0
var sway_tween: Tween
var target_sway_amplitude: Vector3 = Vector3.ZERO
var target_sway_frequency: float = 0.0
var is_movement_sway: bool = false  # Pour distinguer idle/movement


# === SYSTÈME DE MUNITIONS ===
var current_ammo: int = 0  # Balles actuelles dans le barillet

# === SYSTÈME DE CADENCE ===
var can_shoot: bool = true        # Peut-on tirer ?
var is_shooting: bool = false     # Est-on en train de tirer ?

# === SYSTÈME DE RECHARGEMENT ===
enum ReloadState {
	IDLE,                    # État normal
	RELOAD_STARTING,         # L'arme descend + ouverture barillet
	RELOAD_ADDING_BULLETS,   # On ajoute les balles une par une
	RELOAD_INTERRUPTED       # Rechargement interrompu pour tirer
}

var reload_state = ReloadState.IDLE
var bullets_to_add: int = 0      # Combien de balles il reste à ajouter
var bullets_added: int = 0       # Combien on en a déjà ajouté

# === SONS DE RECHARGEMENT ===
var sound_open: AudioStream
var sound_add_bullet: AudioStream  
var sound_close: AudioStream
var sound_gunshot: AudioStream  # SON DE TIR
var sound_empty_click: AudioStream  # SON QUAND VIDE
var audio_player: AudioStreamPlayer2D       # Pour les sons de rechargement
var gunshot_audio_player: AudioStreamPlayer2D  # Pour les sons de tir (séparé)
var empty_click_audio_player: AudioStreamPlayer2D  # Pour les sons de clic vide (séparé)
var temp_audio_players: Array[AudioStreamPlayer2D] = []  # Pool d'objets temporaires

# === POSITIONS POUR L'ANIMATION ===
var reload_position: Vector2     # Position quand l'arme est baissée

func _ready() -> void:
	base_position = position
	# Position de rechargement (plus bas que la position normale)
	reload_position = base_position + Vector2(0, reload_offset_y)
	
	# Initialisation des munitions
	current_ammo = start_ammo
	
	play("Idle")
	connect("animation_finished", Callable(self, "_on_animation_finished"))
	
	# Connexion du signal frame_changed pour détecter le moment du tir
	connect("frame_changed", Callable(self, "_on_frame_changed"))
	
	# Chargement des sons
	sound_open = load("res://Assets/Audio/Guns/OpenRevolverBarrel.mp3")
	sound_add_bullet = load("res://Assets/Audio/Guns/AddRevolverBullet.mp3")
	sound_close = load("res://Assets/Audio/Guns/CloseRevolverBarrel.mp3")
	sound_gunshot = load("res://Assets/Audio/Guns/GunShot-2.mp3")
	sound_empty_click = load("res://Assets/Audio/Guns/AOARevolver.mp3")
	
	# Création des lecteurs audio
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	
	# Lecteur audio séparé pour les tirs (permet la superposition)
	gunshot_audio_player = AudioStreamPlayer2D.new()
	add_child(gunshot_audio_player)
	
	# Lecteur audio séparé pour les clics vides (permet la superposition)
	empty_click_audio_player = AudioStreamPlayer2D.new()
	add_child(empty_click_audio_player)
	
	# Initialiser le pool d'audio players et le système de sway
	_initialize_audio_pool()
	_start_sway_system()

# === GESTION PRINCIPALE ===
func _process(_delta: float) -> void:
	_update_sway(_delta)


func play_shot_animation() -> void:
	# Vérifier si on peut tirer
	if is_shooting or not can_shoot:
		return
	
	# Gérer le rechargement en cours
	if reload_state == ReloadState.RELOAD_ADDING_BULLETS:
		_interrupt_reload()
		return
	elif reload_state != ReloadState.IDLE:
		return
	
	# Gérer le tir à vide
	if current_ammo <= 0:
		_play_empty_click_sound()
		_create_weapon_shake_at_position(position)
		return
	
	is_shooting = true
	current_ammo -= 1
	can_shoot = false
	
	# Arrêter le sway pendant le tir
	stop_sway()
	
	_start_fire_rate_timer()
	
	animation_player.stop()
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", base_position, tween_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation_degrees", 0.0, tween_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	play("GunShotAnim")

# === GESTION DE LA CADENCE DE TIR ===
func _start_fire_rate_timer() -> void:
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

# === FONCTION DE RECHARGEMENT ===
func start_reload() -> void:
	if is_shooting:
		return
	if current_ammo >= max_ammo:
		return
	if reload_state != ReloadState.IDLE:
		return
	
	reload_state = ReloadState.RELOAD_STARTING
	bullets_to_add = max_ammo - current_ammo
	bullets_added = 0
	
	# Arrêter le sway avec transition fluide
	stop_sway()
	
	# Attendre que la transition soit terminée
	await get_tree().create_timer(0.3).timeout
	
	animation_player.stop()
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", reload_position, reload_down_duration)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation_degrees", -45.0, reload_down_duration)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	
	# Déclencher le tremblement immédiatement quand la rotation se termine
	_create_weapon_shake_at_position(reload_position)
	
	_play_sound(sound_open)
	await audio_player.finished
	
	reload_state = ReloadState.RELOAD_ADDING_BULLETS
	_add_next_bullet()

# === AJOUT DES BALLES UNE PAR UNE ===
func _add_next_bullet() -> void:
	if bullets_added >= bullets_to_add:
		_finish_reload()
		return
	
	if reload_state == ReloadState.RELOAD_INTERRUPTED:
		return
	
	_play_sound(sound_add_bullet)
	bullets_added += 1
	current_ammo += 1
	
	# Déclencher le tremblement à chaque balle ajoutée
	_create_weapon_shake()
	
	await audio_player.finished
	
	if reload_state == ReloadState.RELOAD_INTERRUPTED:
		return
	
	_add_next_bullet()

# === FIN DU RECHARGEMENT ===
func _finish_reload() -> void:
	_play_sound(sound_close)
	await audio_player.finished
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", base_position, reload_up_duration)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation_degrees", 0.0, reload_up_duration)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	reload_state = ReloadState.IDLE
	# Reprendre le sway après le rechargement
	resume_sway()

# === INTERRUPTION DU RECHARGEMENT ===
func _interrupt_reload() -> void:
	reload_state = ReloadState.RELOAD_INTERRUPTED
	
	if audio_player.playing:
		await audio_player.finished
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", base_position, interrupt_up_duration)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation_degrees", 0.0, interrupt_up_duration)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	reload_state = ReloadState.IDLE
	# Reprendre le sway après l'interruption
	resume_sway()

# === UTILITAIRES POUR JOUER LES SONS ===
func _play_sound(sound: AudioStream) -> void:
	audio_player.stream = sound
	audio_player.play()

func _play_gunshot_sound() -> void:
	_play_sound_with_superposition(gunshot_audio_player, sound_gunshot)

func _play_empty_click_sound() -> void:
	_play_sound_with_superposition(empty_click_audio_player, sound_empty_click)

func _play_sound_with_superposition(target_player: AudioStreamPlayer2D, sound: AudioStream) -> void:
	if target_player.playing:
		# Utiliser un player du pool pour permettre la superposition
		var temp_player = _get_temp_audio_player()
		temp_player.stream = sound
		temp_player.play()
		temp_player.finished.connect(func(): _return_temp_audio_player(temp_player))
	else:
		target_player.stream = sound
		target_player.play()

# === GESTION DU POOL D'AUDIO PLAYERS ===
func _initialize_audio_pool() -> void:
	# Créer 3 AudioStreamPlayer2D en réserve pour la superposition de sons
	for i in range(3):
		var temp_player = AudioStreamPlayer2D.new()
		add_child(temp_player)
		temp_audio_players.append(temp_player)

func _get_temp_audio_player() -> AudioStreamPlayer2D:
	# Chercher un player disponible
	for player in temp_audio_players:
		if not player.playing:
			return player
	# Si aucun disponible, en créer un nouveau
	var new_player = AudioStreamPlayer2D.new()
	add_child(new_player)
	temp_audio_players.append(new_player)
	return new_player

func _return_temp_audio_player(_player: AudioStreamPlayer2D) -> void:
	# Le player sera réutilisé automatiquement lors du prochain appel
	pass

# === FONCTIONS DE TREMBLEMENT DE L'ARME ===
func _create_weapon_shake() -> void:
	# Déterminer la position de référence selon l'état
	var reference_position = base_position
	if reload_state == ReloadState.RELOAD_ADDING_BULLETS:
		reference_position = reload_position
	
	_create_weapon_shake_at_position(reference_position)

func _create_weapon_shake_at_position(target_position: Vector2) -> void:
	# Créer un tween pour le tremblement
	var shake_tween = create_tween()
	
	# Calculer le nombre d'oscillations basé sur la durée et la fréquence
	var oscillations = int(shake_duration * shake_frequency)
	
	_create_shake_animation(shake_tween, oscillations, target_position)

# === ANIMATION DE TREMBLEMENT COMMUNE ===
func _create_shake_animation(shake_tween: Tween, oscillations: int, reference_position: Vector2) -> void:
	# Création du pattern de tremblement
	for i in range(oscillations):
		# Calcul de l'intensité qui diminue progressivement
		var current_intensity = shake_intensity * (1.0 - float(i) / float(oscillations))
		
		# Direction aléatoire pour le tremblement
		var random_direction = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()
		
		# Position de tremblement autour de la position de référence
		var shake_offset = random_direction * current_intensity
		var target_position = reference_position + shake_offset
		
		# Durée de chaque oscillation
		var oscillation_duration = shake_duration / float(oscillations)
		
		# Ajout du mouvement au tween
		shake_tween.tween_property(self, "position", target_position, oscillation_duration)
	
	# Retour à la position de référence à la fin
	shake_tween.tween_property(self, "position", reference_position, 0.05)
	
	# Arrêter le tween après la durée totale
	shake_tween.tween_callback(func(): shake_tween.kill()).set_delay(shake_duration)

# === SYSTÈME DE SWAY ===

# --- Initialisation du système de sway ---
func _start_sway_system() -> void:
	is_sway_active = true
	is_movement_sway = false
	current_sway_amplitude = idle_sway_amplitude
	current_sway_frequency = idle_sway_frequency
	target_sway_amplitude = idle_sway_amplitude
	target_sway_frequency = idle_sway_frequency
	sway_time = 0.0

# --- Mise à jour du sway ---
func _update_sway(delta: float) -> void:
	if not is_sway_active:
		return
	
	# Ne pas appliquer le sway pendant le rechargement
	if reload_state != ReloadState.IDLE:
		return
	
	# Mise à jour du temps pour l'animation
	sway_time += delta * current_sway_frequency
	
	# Calcul du mouvement circulaire sur les 3 axes
	var sway_offset = _calculate_sway_movement()
	
	# Application du mouvement à la position
	position = base_position + Vector2(sway_offset.x, sway_offset.y)
	
	# Application de la rotation Z (profondeur simulée)
	rotation_degrees = sway_offset.z

# --- Calcul du mouvement de sway circulaire ---
func _calculate_sway_movement() -> Vector3:
	# Calculer les deux patterns
	var idle_x = sin(sway_time) * idle_sway_amplitude.x
	var idle_y = cos(sway_time * 0.7) * idle_sway_amplitude.y
	var idle_z = sin(sway_time * 1.3) * idle_sway_amplitude.z
	
	var movement_rhythm = sin(sway_time * 2.0)
	var movement_x = movement_rhythm * movement_sway_amplitude.x
	var movement_y = abs(movement_rhythm) * movement_sway_amplitude.y
	var movement_z = sin(sway_time * 0.3) * movement_sway_amplitude.z
	
	# Interpolation fluide entre les deux patterns
	var transition_factor = _get_sway_transition_factor()
	
	var x_offset = lerp(idle_x, movement_x, transition_factor)
	var y_offset = lerp(idle_y, movement_y, transition_factor)
	var z_offset = lerp(idle_z, movement_z, transition_factor)
	
	return Vector3(x_offset, y_offset, z_offset)

# --- Calcul du facteur de transition ---
func _get_sway_transition_factor() -> float:
	if is_movement_sway:
		# Transition vers movement : utiliser la progression du tween
		if sway_tween and sway_tween.is_valid():
			# Calculer la progression du tween (0.0 à 1.0)
			var elapsed = sway_tween.get_total_elapsed_time()
			var duration = 1.0 / sway_transition_speed
			return min(elapsed / duration, 1.0)
		else:
			return 1.0
	else:
		# Transition vers idle : utiliser la progression du tween
		if sway_tween and sway_tween.is_valid():
			var elapsed = sway_tween.get_total_elapsed_time()
			var duration = 1.0 / sway_transition_speed
			return 1.0 - min(elapsed / duration, 1.0)
		else:
			return 0.0

# --- Transition vers le sway idle ---
func set_sway_idle() -> void:
	if not is_movement_sway:
		return
	
	is_movement_sway = false
	target_sway_amplitude = idle_sway_amplitude
	target_sway_frequency = idle_sway_frequency
	_transition_sway_parameters()

# --- Transition vers le sway movement ---
func set_sway_movement() -> void:
	if is_movement_sway:
		return
	
	is_movement_sway = true
	target_sway_amplitude = movement_sway_amplitude
	target_sway_frequency = movement_sway_frequency
	_transition_sway_parameters()

# --- Transition fluide des paramètres de sway ---
func _transition_sway_parameters() -> void:
	if sway_tween:
		sway_tween.kill()
	
	sway_tween = create_tween()
	sway_tween.set_parallel(true)
	sway_tween.tween_method(_update_sway_amplitude, current_sway_amplitude, target_sway_amplitude, 1.0 / sway_transition_speed)
	sway_tween.tween_method(_update_sway_frequency, current_sway_frequency, target_sway_frequency, 1.0 / sway_transition_speed)

# --- Mise à jour de l'amplitude de sway ---
func _update_sway_amplitude(new_amplitude: Vector3) -> void:
	current_sway_amplitude = new_amplitude

# --- Mise à jour de la fréquence de sway ---
func _update_sway_frequency(new_frequency: float) -> void:
	current_sway_frequency = new_frequency

# --- Arrêt du sway (pour les tirs, rechargement, etc.) ---
func stop_sway() -> void:
	is_sway_active = false
	if sway_tween:
		sway_tween.kill()
	
	# Transition fluide vers la position de base
	var return_tween = create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(self, "position", base_position, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return_tween.tween_property(self, "rotation_degrees", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# --- Reprise du sway ---
func resume_sway() -> void:
	is_sway_active = true

# --- Fonction publique pour définir l'état de mouvement ---
func set_movement_state(is_moving: bool) -> void:
	if is_moving:
		set_sway_movement()
	else:
		set_sway_idle()

func _on_animation_finished() -> void:
	if animation == "GunShotAnim":
		is_shooting = false
		# Reprendre le sway après le tir
		resume_sway()
		play("Idle")

func _on_frame_changed() -> void:
	if animation == "GunShotAnim":
		if frame == shot_detection_frame:
			shot_fired.emit()
			_play_gunshot_sound()

# === FONCTION POUR CRÉER LES PARAMÈTRES D'EFFET ===
func get_hit_effect_params() -> Dictionary:
	# Retourner un dictionnaire avec les paramètres d'effet du revolver
	return {
		"duration": hit_shake_duration,
		"intensity": hit_shake_intensity,
		"frequency": hit_shake_frequency,
		"axes": hit_shake_axes
	}
