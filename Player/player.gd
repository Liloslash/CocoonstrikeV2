extends CharacterBody3D

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


# --- Gestion des inputs ---
func _input(event: InputEvent) -> void:
	# Déléguer la gestion des inputs au composant
	input_component._input(event)

func _unhandled_input(event: InputEvent) -> void:
	# Déléguer la gestion des inputs non gérés au composant
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
	
	# La connexion du signal de tir est déjà gérée dans PlayerCombat._connect_revolver()
	
	# Connexion du signal de slam pour le camera shake
	movement_component.slam_landed.connect(_on_slam_landed)

# --- Fonction générique pour déclencher le tremblement de caméra ---
func start_camera_shake(intensity: float = -1.0, duration: float = -1.0, rot: float = -1.0) -> void:
	# Déléguer directement à la caméra (wrapper pour l'API publique)
	camera_component.start_camera_shake(intensity, duration, rot)

# --- Gestionnaire du signal de slam ---
func _on_slam_landed() -> void:
	# Déclencher un camera shake intense pour l'atterrissage
	# Utiliser la durée configurée dans l'inspecteur
	camera_component.start_camera_shake(1.2, -1.0, 8.0)

# --- Gestion du tremblement, head bob et détection tir ---
func _process(_delta: float) -> void:
	# Déléguer la gestion de la caméra au composant
	camera_component._process(_delta)
	
	# Mettre à jour l'état de mouvement du revolver
	_update_revolver_movement_state()

# --- Mise à jour de la physique du joueur ---
func _physics_process(delta: float) -> void:
	# Déléguer la gestion du mouvement au composant
	movement_component._physics_process(delta)
	
	# Appliquer le mouvement
	move_and_slide()

# --- Mise à jour de l'état de mouvement du revolver ---
func _update_revolver_movement_state() -> void:
	if not combat_component.is_revolver_connected():
		return
	
	var revolver_sprite = combat_component.revolver_sprite
	
	# Ne pas envoyer d'état pendant le tir ou le rechargement
	if revolver_sprite.is_shooting or revolver_sprite.reload_state != revolver_sprite.ReloadState.IDLE:
		return
	
	# Transmettre l'état de mouvement au revolver
	revolver_sprite.set_movement_state(movement_component.is_moving())
