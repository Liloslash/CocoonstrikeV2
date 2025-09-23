extends Node
class_name PlayerInput

# === PARAMÈTRES EXPORTÉS ===
@export_group("Contrôles")
@export var mouse_sensitivity: float = 0.002

# === RÉFÉRENCES ===
var player: CharacterBody3D
var movement_component: Node
var combat_component: Node

# === INITIALISATION ===
func _ready() -> void:
	# Le joueur sera assigné par le script principal
	pass

func setup_player(player_node: CharacterBody3D, movement_comp: Node, combat_comp: Node) -> void:
	player = player_node
	movement_component = movement_comp
	combat_component = combat_comp

# === GESTION DES INPUTS ===
func _input(event: InputEvent) -> void:
	# Gestion de la souris
	if event is InputEventMouseMotion:
		player.rotate_y(-event.relative.x * mouse_sensitivity)
	
	# Gestion des actions de mouvement (pressed)
	if event.is_action_pressed("jump"):
		movement_component.start_jump()
		
	if event.is_action_pressed("slam"):
		movement_component.start_slam()
	
	# Gestion de l'échappement
	if event.is_action_pressed("esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	# Gestion des actions de combat (just_pressed)
	if event.is_action("shot") and event.is_pressed():
		if combat_component.is_revolver_connected():
			combat_component.revolver_sprite.play_shot_animation()
	
	if event.is_action("reload") and event.is_pressed():
		if combat_component.is_revolver_connected():
			combat_component.revolver_sprite.start_reload()

# === FONCTIONS PUBLIQUES ===
func set_mouse_sensitivity(sensitivity: float) -> void:
	mouse_sensitivity = sensitivity

func get_mouse_sensitivity() -> float:
	return mouse_sensitivity
