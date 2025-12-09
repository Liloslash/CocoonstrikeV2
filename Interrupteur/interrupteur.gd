extends Interactable

# === INTERRUPTEUR ===
# Gère l'interaction avec l'interrupteur pour lancer les vagues
# Utilise le système Interactable avec Area3D pour la détection optimale

# --- Références ---
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D

# --- État ---
var is_in_wave: bool = false  # true = InWave, false = OffWave

func _ready() -> void:
	# Initialiser le rayon d'interaction (hérité de Interactable)
	interaction_radius = 2.0
	
	super._ready()  # Appeler _ready() du parent Interactable
	
	# Ajouter au groupe pour être détecté par PlayerInteraction
	add_to_group("interactables")
	
	# Initialiser le texte d'interaction
	interaction_text = "Appuyez sur E pour lancer la vague"
	
	# Initialiser l'état à OffWave
	sprite.animation = "OffWave"
	sprite.play("OffWave")
	
	# Connecter les signaux du parent
	player_entered.connect(_on_player_nearby)
	player_exited.connect(_on_player_left)
	interaction_triggered.connect(_on_interaction_requested_handler)

# --- Surcharge des méthodes virtuelles d'Interactable ---
func _on_interact(_player: CharacterBody3D) -> void:
	# Appelé quand le joueur appuie sur E dans la zone
	toggle_state()

func _on_player_nearby(_player: CharacterBody3D) -> void:
	# Le joueur est entré dans la zone
	pass

func _on_player_left(_player: CharacterBody3D) -> void:
	# Le joueur est sorti de la zone
	pass

func _on_interaction_requested_handler(_player: CharacterBody3D) -> void:
	# Géré automatiquement par _on_interact()
	pass

# --- Méthodes spécifiques à l'interrupteur ---
func toggle_state() -> void:
	# Changer l'état de l'interrupteur
	is_in_wave = not is_in_wave
	
	# TODO: Désactiver l'interaction si une vague est en cours
	# can_interact = not is_in_wave  # Activé plus tard quand le système de vagues sera connecté
	
	if is_in_wave:
		# Passer à InWave (vague lancée)
		sprite.animation = "InWave"
		sprite.play("InWave")
	else:
		# Passer à OffWave (vague finie, peut relancer)
		sprite.animation = "OffWave"
		sprite.play("OffWave")
