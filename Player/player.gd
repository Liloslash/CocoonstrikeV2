extends CharacterBody3D
class_name Player

# === JOUEUR PRINCIPAL - ORCHESTRATEUR ===
# Ce script orchestre les différents composants du joueur :
# - PlayerCamera : Gestion de la caméra (shake, head bob, recul)
# - PlayerMovement : Mouvement, saut, slam
# - PlayerCombat : Tir, raycast, dégâts
# - PlayerInput : Gestion des inputs

# --- Composants ---
@onready var camera_component: PlayerCamera = $PlayerCamera
@onready var movement_component: PlayerMovement = $PlayerMovement
@onready var combat_component: PlayerCombat = $PlayerCombat
@onready var input_component: PlayerInput = $PlayerInput
@onready var interact_label: Label = $HUD_Layer/UI_Interactions/InteractLabel

# --- État pour l'optimisation ---
var last_movement_state: bool = false

const DEFAULT_INTERACTION_TEXT = "Appuyez sur E pour interagir"

# --- État pour les interactions ---
@export var interaction_texts: Dictionary = {
	"start_wave": "Appuyez sur E pour lancer la vague"
}

var should_show_interaction: bool = false
var current_interrupteur_id: String = ""


# --- Gestion des inputs ---
func _unhandled_input(event: InputEvent) -> void:
	# Déléguer la gestion des inputs aux composants
	input_component._unhandled_input(event)

# --- Initialisation ---
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Configuration des collisions
	collision_layer = 1  # Joueur sur la layer 1
	collision_mask = 3   # Détecte la layer 0 (environnement) + layer 2 (ennemis)
	
	# Initialiser les composants
	movement_component.setup_player(self)
	input_component.setup_player(self, movement_component, combat_component)
	
	# Connexion du signal de slam pour déclencher le camera shake
	movement_component.slam_landed.connect(_on_slam_landed)
	
	# Se connecter aux signaux des interrupteurs
	_connect_to_interrupteurs()

# --- Fonction générique pour déclencher le tremblement de caméra ---
func start_camera_shake(intensity: float = -1.0, duration: float = -1.0, rot: float = -1.0) -> void:
	# Déléguer directement à la caméra
	camera_component.start_camera_shake(intensity, duration, rot)

# --- Gestionnaire du signal de slam ---
func _on_slam_landed() -> void:
	# Déclencher un camera shake intense pour l'atterrissage
	camera_component.start_camera_shake(1.2, -1.0, 8.0)

# --- Mise à jour de la physique du joueur ---
func _physics_process(delta: float) -> void:
	# Déléguer la gestion du mouvement au composant
	movement_component._physics_process(delta)
	
	_update_revolver_movement_state()
	# Appliquer le mouvement
	move_and_slide()

# --- Mise à jour de l'état de mouvement du revolver ---
func _update_revolver_movement_state() -> void:
	
	var revolver_sprite = combat_component.revolver_sprite
	
	# Ne pas envoyer d'état pendant le tir ou le rechargement
	if revolver_sprite.is_shooting or revolver_sprite.reload_state != revolver_sprite.ReloadState.IDLE:
		return
	
	# Ne mettre à jour que si l'état a changé
	var current_movement_state = movement_component.is_moving()
	if current_movement_state != last_movement_state:
		last_movement_state = current_movement_state
		revolver_sprite.set_movement_state(current_movement_state)

# --- Gestion des interactions ---
func _connect_to_interrupteurs() -> void:
	# Trouver tous les interrupteurs dans la scène
	var interrupteurs = get_tree().get_nodes_in_group("interrupteurs")

	# Se connecter aux signaux de chaque interrupteur
	for interrupteur in interrupteurs:
		if interrupteur.has_signal("interaction_state_changed"):
			interrupteur.interaction_state_changed.connect(_on_interaction_state_changed)

func _on_interaction_state_changed(interrupteur_id: String, is_active: bool) -> void:
	# Mettre à jour l'état d'affichage selon le signal reçu
	should_show_interaction = is_active
	current_interrupteur_id = interrupteur_id if is_active else ""
	
	# Mettre à jour le texte du label si on l'affiche
	if interact_label and is_active:
		# Chercher le texte correspondant à cet ID dans le dictionnaire
		if interrupteur_id in interaction_texts:
			interact_label.text = interaction_texts[interrupteur_id]
		else:
			# Texte par défaut si l'ID n'existe pas
			interact_label.text = DEFAULT_INTERACTION_TEXT

func _process(_delta: float) -> void:
	# Mettre à jour l'opacité du label d'interaction avec transition douce
	if not interact_label:
		return
	
	var target_alpha: float = 1.0 if should_show_interaction else 0.0
	interact_label.modulate.a = lerp(interact_label.modulate.a, target_alpha, 0.2)
	interact_label.modulate = Color(1, 1, 1, interact_label.modulate.a)
