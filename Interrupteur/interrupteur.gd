extends StaticBody3D

# === INTERRUPTEUR ===
# Gère l'interaction avec l'interrupteur pour lancer les vagues
# Simple : Area3D détecte le joueur, E déclenche l'action

# --- Signaux ---
signal interaction_state_changed(interrupteur_id: String, is_active: bool)
signal wave_started()

# --- Références ---
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var interaction_area: Area3D = $InteractionArea

# --- Paramètres exportés ---
@export var interrupteur_id: String = "start_wave" # Identifiant unique pour différencier les interrupteurs

# --- État ---
var is_in_wave: bool = false # true = InWave, false = OffWave
var player_in_range: bool = false # Le joueur est dans la zone

func _ready() -> void:
	# Vérifier que l'Area3D existe
	if not interaction_area:
		push_error("Interrupteur: InteractionArea manquante ! Ajoutez une Area3D nommée 'InteractionArea' comme enfant.")
		return

	# Ajouter au groupe pour être trouvé par le joueur
	add_to_group("interrupteurs")

	# Connecter les signaux de l'Area3D pour détecter le joueur
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

	# Configurer les layers de collision
	interaction_area.collision_layer = 0 # Ne détecte rien
	interaction_area.collision_mask = 1 # Détecte la layer 1 (joueur)

	# Initialiser l'état à OffWave
	sprite.animation = "OffWave"
	sprite.play("OffWave")

func _unhandled_input(event: InputEvent) -> void:
	# Si le joueur est dans la zone et appuie sur E
	if player_in_range:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_E and event.pressed):
			toggle_state()

func _on_body_entered(body: Node) -> void:
	# Vérifier que c'est bien le joueur (layer 1)
	if body is CharacterBody3D and body.collision_layer == 1:
		player_in_range = true
		# Émettre le signal true si on peut interagir (pas en vague)
		interaction_state_changed.emit(interrupteur_id, not is_in_wave)

func _on_body_exited(body: Node) -> void:
	# Le joueur est sorti de la zone
	if body is CharacterBody3D and body.collision_layer == 1:
		player_in_range = false
		# Émettre le signal false pour cacher le texte
		interaction_state_changed.emit(interrupteur_id, false)

func toggle_state() -> void:
	# Changer l'état de l'interrupteur
	is_in_wave = not is_in_wave

	# TODO: Désactiver l'interaction si une vague est en cours
	# player_in_range = not is_in_wave  # Activé plus tard quand le système de vagues sera connecté

	if is_in_wave:
		# Passer à InWave (vague lancée)
		sprite.animation = "InWave"
		sprite.play("InWave")
		# Cacher le texte d'interaction (false)
		if player_in_range:
			interaction_state_changed.emit(interrupteur_id, false)
		# Émettre le signal de démarrage de vague
		wave_started.emit()
	else:
		# Passer à OffWave (vague finie, peut relancer)
		sprite.animation = "OffWave"
		sprite.play("OffWave")
		# Si le joueur est toujours dans la zone, réafficher le texte (true)
		if player_in_range:
			interaction_state_changed.emit(interrupteur_id, true)
