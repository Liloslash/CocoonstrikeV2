extends StaticBody3D
class_name Interactable

# === INTERACTABLE - CLASSE DE BASE ===
# Classe de base pour tous les objets interactifs (interrupteurs, pièges, etc.)
# Utilise Area3D pour détecter le joueur de manière optimale

# --- Signaux ---
signal player_entered(player: CharacterBody3D)
signal player_exited(player: CharacterBody3D)
signal interaction_triggered(player: CharacterBody3D)

# --- Références ---
@onready var interaction_area: Area3D = $InteractionArea
@onready var collision_shape: CollisionShape3D = $InteractionArea/CollisionShape3D

# --- Paramètres exportés ---
@export_group("Interaction")
@export var interaction_text: String = "Appuyez sur E pour interagir"
@export var interaction_radius: float = 2.0
@export var can_interact: bool = true  # Permet de désactiver temporairement l'interaction

# --- État interne ---
var player_in_range: bool = false
var current_player: CharacterBody3D = null

func _ready() -> void:
	# S'assurer que l'Area3D existe
	if not interaction_area:
		push_error("Interactable: InteractionArea manquante ! Ajoutez une Area3D nommée 'InteractionArea' comme enfant.")
		return
	
	# Configurer l'Area3D
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	# Créer la forme de collision si elle n'existe pas
	if not collision_shape.shape:
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = interaction_radius
		collision_shape.shape = sphere_shape
	else:
		# Ajuster le rayon si c'est une sphère
		if collision_shape.shape is SphereShape3D:
			collision_shape.shape.radius = interaction_radius
	
	# Configurer les layers de collision
	interaction_area.collision_layer = 0  # Ne détecte rien
	interaction_area.collision_mask = 1   # Détecte la layer 1 (joueur)

# L'input est géré par PlayerInteraction, pas ici

func _on_body_entered(body: Node) -> void:
	# Vérifier que c'est bien le joueur
	if body is CharacterBody3D and body.collision_layer == 1:  # Layer 1 = joueur
		current_player = body
		player_in_range = true
		player_entered.emit(current_player)
		_on_player_entered_range()

func _on_body_exited(body: Node) -> void:
	# Vérifier que c'est bien le joueur qui sort
	if body == current_player:
		player_exited.emit(current_player)
		current_player = null
		player_in_range = false
		_on_player_exited_range()

# Méthode publique pour déclencher l'interaction depuis l'extérieur (PlayerInteraction)
func trigger_interaction() -> void:
	if player_in_range and current_player and can_interact:
		_on_interact(current_player)
		interaction_triggered.emit(current_player)

func _on_interaction_requested() -> void:
	# Ancienne méthode, conservée pour compatibilité
	trigger_interaction()

# --- Méthodes virtuelles à surcharger dans les classes enfants ---
func _on_player_entered_range() -> void:
	# Surcharger cette méthode pour réagir quand le joueur entre dans la zone
	pass

func _on_player_exited_range() -> void:
	# Surcharger cette méthode pour réagir quand le joueur sort de la zone
	pass

func _on_interact(_player: CharacterBody3D) -> void:
	# Surcharger cette méthode pour définir le comportement lors de l'interaction
	push_warning("Interactable: _on_interact() non implémentée !")
	pass

# --- Méthodes publiques ---
func is_player_nearby() -> bool:
	return player_in_range and can_interact

func get_interaction_text() -> String:
	return interaction_text
