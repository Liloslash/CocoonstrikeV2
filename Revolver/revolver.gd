extends AnimatedSprite2D

# Signal émis au moment exact du tir
signal shot_fired

# === PARAMÈTRES EXPORTÉS ===
@export_group("Animation")
@export var tween_duration := 0.12  # Durée du tween de position

@export_group("Munitions")
@export var max_ammo: int = 6       # Maximum de balles (6 coups)
@export var start_ammo: int = 6     # Munitions au début

@export_group("Rechargement - Positions")
@export var reload_offset_y: float = 200.0  # Distance vers le bas pour le rechargement
@export var reload_down_duration: float = 0.3   # Durée pour descendre l'arme
@export var reload_up_duration: float = 0.3     # Durée pour remonter l'arme
@export var interrupt_up_duration: float = 0.2  # Durée pour remonter en cas d'interruption

@export_group("Cadence de Tir")
@export var fire_rate: float = 0.5  # Délai minimum entre deux tirs (en secondes)
@export var shot_detection_frame: int = 2  # Frame où le tir se déclenche dans l'animation

@export_group("Tremblement du Rechargement")
@export var shake_intensity: float = 3.0  # Intensité du tremblement (en pixels)
@export var shake_duration: float = 0.15  # Durée du tremblement pour chaque balle
@export var shake_frequency: float = 20.0  # Fréquence du tremblement (oscillations par seconde)


@onready var animation_player = $AnimationPlayer
var base_position: Vector2

# === SYSTÈME DE MUNITIONS ===
var current_ammo: int  # Balles actuelles dans le barillet

# === SYSTÈME DE CADENCE ===
var last_shot_time: float = 0.0  # Temps du dernier tir
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

# === POSITIONS POUR L'ANIMATION ===
var reload_position: Vector2     # Position quand l'arme est baissée

func _ready():
	base_position = position
	# Position de rechargement (plus bas que la position normale)
	reload_position = base_position + Vector2(0, reload_offset_y)
	
	# Initialisation des munitions
	current_ammo = start_ammo
	
	play("Idle")
	animation_player.play("Sway_Idle")
	connect("animation_finished", Callable(self, "_on_animation_finished"))
	
	# Connexion du signal frame_changed pour détecter le moment du tir
	connect("frame_changed", Callable(self, "_on_frame_changed"))
	
	# === CHARGEMENT DES SONS ===
	sound_open = load("res://Assets/Audio/Guns/OpenRevolverBarrel.mp3")
	sound_add_bullet = load("res://Assets/Audio/Guns/AddRevolverBullet.mp3")
	sound_close = load("res://Assets/Audio/Guns/CloseRevolverBarrel.mp3")
	sound_gunshot = load("res://Assets/Audio/Guns/GunShot-2.mp3")  # SON DE TIR
	sound_empty_click = load("res://Assets/Audio/Guns/AOARevolver.mp3")  # SON QUAND VIDE
	
	# Création des lecteurs audio
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	
	# Lecteur audio séparé pour les tirs (permet la superposition)
	gunshot_audio_player = AudioStreamPlayer2D.new()
	add_child(gunshot_audio_player)
	
	# Lecteur audio séparé pour les clics vides (permet la superposition)
	empty_click_audio_player = AudioStreamPlayer2D.new()
	add_child(empty_click_audio_player)

func play_shot_animation():
	if is_shooting:
		return
	elif reload_state == ReloadState.RELOAD_ADDING_BULLETS:
		_interrupt_reload()
		return
	elif current_ammo <= 0:
		_play_empty_click_sound()
		return
	elif reload_state != ReloadState.IDLE:
		return
	elif not can_shoot:
		return
	
	is_shooting = true
	current_ammo -= 1
	can_shoot = false
	# OPTIMISATION : Utilisation du temps plus efficace
	last_shot_time = Time.get_ticks_msec() * 0.001  # Conversion en secondes
	
	_start_fire_rate_timer()
	
	animation_player.stop()
	var tween = create_tween()
	tween.tween_property(self, "position", base_position, tween_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	play("GunShotAnim")

# === GESTION DE LA CADENCE DE TIR ===
func _start_fire_rate_timer():
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

# === FONCTION DE RECHARGEMENT ===
func start_reload():
	if is_shooting:
		return
	if current_ammo >= max_ammo:
		return
	if reload_state != ReloadState.IDLE:
		return
	
	reload_state = ReloadState.RELOAD_STARTING
	bullets_to_add = max_ammo - current_ammo
	bullets_added = 0
	
	animation_player.stop()
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", reload_position, reload_down_duration)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation_degrees", -45.0, reload_down_duration)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	
	_play_sound(sound_open)
	await audio_player.finished
	
	reload_state = ReloadState.RELOAD_ADDING_BULLETS
	_add_next_bullet()

# === AJOUT DES BALLES UNE PAR UNE ===
func _add_next_bullet():
	if bullets_added >= bullets_to_add:
		_finish_reload()
		return
	
	if reload_state == ReloadState.RELOAD_INTERRUPTED:
		return
	
	_play_sound(sound_add_bullet)
	bullets_added += 1
	current_ammo += 1
	
	# Déclenchement du tremblement à chaque balle ajoutée
	_create_reload_shake()
	
	await audio_player.finished
	
	if reload_state == ReloadState.RELOAD_INTERRUPTED:
		return
	
	_add_next_bullet()

# === FIN DU RECHARGEMENT ===
func _finish_reload():
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
	animation_player.play("Sway_Idle")

# === INTERRUPTION DU RECHARGEMENT ===
func _interrupt_reload():
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
	animation_player.play("Sway_Idle")

# === UTILITAIRE POUR JOUER LES SONS ===
func _play_sound(sound: AudioStream):
	audio_player.stream = sound
	audio_player.play()

# === UTILITAIRE POUR JOUER LES SONS DE TIR (avec superposition) ===
func _play_gunshot_sound():
	if gunshot_audio_player.playing:
		var temp_player = AudioStreamPlayer2D.new()
		add_child(temp_player)
		temp_player.stream = sound_gunshot
		temp_player.play()
		temp_player.finished.connect(func(): temp_player.queue_free())
	else:
		gunshot_audio_player.stream = sound_gunshot
		gunshot_audio_player.play()

# === UTILITAIRE POUR JOUER LES SONS DE CLIC VIDE (avec superposition) ===
func _play_empty_click_sound():
	if empty_click_audio_player.playing:
		var temp_player = AudioStreamPlayer2D.new()
		add_child(temp_player)
		temp_player.stream = sound_empty_click
		temp_player.play()
		temp_player.finished.connect(func(): temp_player.queue_free())
	else:
		empty_click_audio_player.stream = sound_empty_click
		empty_click_audio_player.play()

# === FONCTION DE TREMBLEMENT PENDANT LE RECHARGEMENT ===
func _create_reload_shake():
	# On s'assure qu'on est bien en position de rechargement
	if reload_state != ReloadState.RELOAD_ADDING_BULLETS:
		return
	
	# Création d'un tween pour le tremblement
	var shake_tween = create_tween()
	shake_tween.set_loops()  # Le tween se répète
	
	# Calcul du nombre d'oscillations basé sur la durée et la fréquence
	var oscillations = int(shake_duration * shake_frequency)
	
	# Création du pattern de tremblement
	for i in range(oscillations):
		# Calcul de l'intensité qui diminue progressivement
		var current_intensity = shake_intensity * (1.0 - float(i) / float(oscillations))
		
		# Direction aléatoire pour le tremblement
		var random_direction = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()
		
		# Position de tremblement autour de la position de rechargement
		var shake_offset = random_direction * current_intensity
		var target_position = reload_position + shake_offset
		
		# Durée de chaque oscillation
		var oscillation_duration = shake_duration / float(oscillations)
		
		# Ajout du mouvement au tween
		shake_tween.tween_property(self, "position", target_position, oscillation_duration)
	
	# Retour à la position de rechargement à la fin
	shake_tween.tween_property(self, "position", reload_position, 0.05)
	
	# Arrêt du tween après la durée totale
	await get_tree().create_timer(shake_duration).timeout
	shake_tween.kill()


func _on_animation_finished():
	if animation == "GunShotAnim":
		is_shooting = false
		play("Idle")
		animation_player.play("Sway_Idle")

func _on_frame_changed():
	if animation == "GunShotAnim":
		if frame == shot_detection_frame:
			shot_fired.emit()
			_play_gunshot_sound()
