extends Node
class_name PlayerCombat

# === PARAMÈTRES EXPORTÉS ===
@export_group("Combat")
@export var revolver_damage: int = 25  # Dégâts du revolver

# === RÉFÉRENCES ===
var player: CharacterBody3D
var raycast: RayCast3D

# === EFFET D'IMPACT ===
const IMPACT_EFFECT_SCENE = preload("res://Effects/ImpactEffect.tscn")

# === RÉFÉRENCE AU REVOLVER DANS LE HUD ===
var revolver_sprite: Node
var revolver_connected: bool = false

# === INITIALISATION ===
func _ready() -> void:
	# Le joueur sera assigné par le script principal
	pass

func setup_player(player_node: CharacterBody3D) -> void:
	player = player_node
	raycast = player.get_node("Camera3D/RayCast3D")
	revolver_sprite = player.get_node("HUD_Layer/Revolver")
	
	# Configuration du raycast
	_setup_raycast()
	
	# Connexion du revolver
	_connect_revolver()

# === CONFIGURATION DU RAYCAST ===
func _setup_raycast() -> void:
	if not raycast:
		# Créer si manquant (sécurité)
		raycast = RayCast3D.new()
		player.get_node("Camera3D").add_child(raycast)
	
	# Configuration robuste même s'il existe déjà dans la scène
	raycast.target_position = Vector3(0, 0, -1000)  # Portée vers l'avant
	raycast.enabled = true
	raycast.collision_mask = 2  # Ne détecter que la layer 2 (ennemis)
	if raycast.has_method("set_exclude_parent_body"):
		# Godot 4 expose exclude_parent comme propriété, mais on garde une compat de méthode
		raycast.set_exclude_parent_body(true)
	elif "exclude_parent" in raycast:
		raycast.exclude_parent = true

# === CONNEXION DU REVOLVER ===
func _connect_revolver() -> void:
	if revolver_sprite:
		revolver_sprite.shot_fired.connect(_handle_shot)
		revolver_connected = true
	else:
		push_error("Revolver sprite non trouvé dans HUD_Layer/Revolver")
		revolver_connected = false

# === GESTION DU TIR ===
func _process(_delta: float) -> void:
	_handle_shooting()

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

# === GESTION DU TIR AVEC RAYCAST ===
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

# === CRÉATION DE L'EFFET D'IMPACT ===
func _create_impact_effect(impact_position: Vector3, target_collider: Node):
	var impact_effect = IMPACT_EFFECT_SCENE.instantiate()
	player.get_tree().current_scene.add_child(impact_effect)
	impact_effect.global_position = impact_position
	
	# Récupérer les couleurs d'impact de l'ennemi touché
	if target_collider.has_method("get_impact_colors"):
		var impact_colors = target_collider.get_impact_colors()
		if impact_colors.size() >= 4:
			impact_effect.set_impact_colors(impact_colors)

# === FONCTION POUR TROUVER LE SPRITE DANS UN ENNEMI ===
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

# === FONCTIONS PUBLIQUES POUR LE JOUEUR ===
func trigger_recoil() -> void:
	# Cette fonction sera appelée par le signal du revolver
	# Le recul sera géré par le composant caméra
	pass

func is_revolver_connected() -> bool:
	return revolver_connected
