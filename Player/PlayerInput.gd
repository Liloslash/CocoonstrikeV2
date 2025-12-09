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
func setup_player(player_node: CharacterBody3D, movement_comp: Node, combat_comp: Node) -> void:
	player = player_node
	movement_component = movement_comp
	combat_component = combat_comp

# === GESTION DES INPUTS ===
func _unhandled_input(event: InputEvent) -> void:
	# Vérifier que le joueur existe
	if not player:
		return
	
	# Gestion de la rotation de la caméra avec la souris
	if event is InputEventMouseMotion:
		player.rotate_y(-event.relative.x * mouse_sensitivity)
		return
	
	# Gestion du saut
	if event.is_action_pressed("jump"):
		movement_component.start_jump()
		return
		
	# Gestion du slam
	if event.is_action_pressed("slam"):
		movement_component.start_slam()
		return
	
	# Gestion du tir
	if event.is_action("shot") and event.is_pressed():
		combat_component.trigger_shot()
		return
	
	# Gestion du rechargement
	if event.is_action("reload") and event.is_pressed():
		combat_component.trigger_reload()
		return
	
	# Gestion de l'échappement (libérer la souris)
	if event.is_action_pressed("esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
