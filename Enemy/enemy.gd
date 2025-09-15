extends CharacterBody3D

# === PARAMÈTRES EXPORTÉS ===
@export_group("Statistiques")
@export var max_health: int = 100

@export_group("Comportement")
@export var move_speed: float = 3.0
@export var detection_range: float = 15.0  # Distance de détection du joueur

@export_group("Animation de Mort")
@export var death_freeze_duration: float = 1.0  # Durée du freeze avant disparition

@export_group("Effets d'Impact")
@export var impact_color_1: Color = Color(1.0, 0.5, 0.5, 1.0)  # Rouge clair
@export var impact_color_2: Color = Color.GREEN    # Couleur 2 (veines vertes)
@export var impact_color_3: Color = Color.PURPLE   # Couleur 3 (corps violet)
@export var impact_color_4: Color = Color.BLACK    # Couleur 4 (détails noirs)

# === VARIABLES INTERNES ===
var current_health: int
var is_alive: bool = true
var is_frozen: bool = false
var player_reference: Node3D = null

# === COMPOSANTS ===
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D  # Le sprite 2D billboard

func _ready():
	# Initialisation
	current_health = max_health
	
	# Mettre l'ennemi sur la layer 2 pour le raycast
	collision_layer = 2
	
	# Recherche du joueur dans la scène
	_find_player()

func _find_player():
	# Cherche le joueur dans la scène (adaptez selon votre structure)
	var world = get_tree().get_first_node_in_group("world")
	if world:
		player_reference = world.get_node_or_null("Player")
	
	if not player_reference:
		# Recherche alternative
		player_reference = get_tree().get_first_node_in_group("player")

func _physics_process(_delta):
	if not is_alive or is_frozen:
		return
	
	# Pour l'instant, l'ennemi reste statique
	# TODO: Ajouter logique de mouvement/pathfinding plus tard
	pass

# === SYSTÈME DE DÉGÂTS ===
func take_damage(damage: int):
	if not is_alive:
		return
	
	current_health -= damage
	
	# Vérification de la mort
	if current_health <= 0:
		_die()

func _die():
	if not is_alive:
		return
		
	is_alive = false
	is_frozen = true
	_disable_collisions()
	
	# Freeze pendant 1 seconde puis disparition
	await get_tree().create_timer(death_freeze_duration).timeout
	queue_free()

func _disable_collisions():
	# Désactiver collisions du corps
	var body_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")
	if body_shape:
		body_shape.disabled = true
	
	# Désactiver l'Area3D et sa forme
	var area: Area3D = get_node_or_null("Area3D")
	if area:
		area.monitoring = false
		area.monitorable = false
		var area_shape: CollisionShape3D = area.get_node_or_null("CollisionShape3D")
		if area_shape:
			area_shape.disabled = true
	
	# Retirer des layers/masks pour ne plus être raycastable
	collision_layer = 0
	collision_mask = 0

# === GETTERS POUR DEBUG/HUD ===
func get_health_percentage() -> float:
	return float(current_health) / float(max_health)

func is_dead() -> bool:
	return not is_alive

# === GETTERS POUR LES COULEURS D'IMPACT ===
func get_impact_colors() -> Array[Color]:
	return [impact_color_1, impact_color_2, impact_color_3, impact_color_4]
