extends Node
class_name PlayerInteraction

# === PLAYER INTERACTION ===
# Gère toutes les interactions du joueur avec les objets interactifs
# (interrupteurs, pièges, etc.)

# --- Références ---
var player: CharacterBody3D
var interact_label: Label

# --- État ---
var current_interactable: Interactable = null
var e_pressed_last_frame: bool = false  # Pour éviter les appuis répétés

func setup_player(player_node: CharacterBody3D, label_node: Label) -> void:
	player = player_node
	interact_label = label_node
	
	# Initialiser le label comme invisible
	if interact_label:
		interact_label.modulate = Color(1, 1, 1, 0.0)

func _unhandled_input(_event: InputEvent) -> void:
	# Vérifier si E est pressé maintenant
	var e_pressed_now: bool = Input.is_key_pressed(KEY_E) or Input.is_action_pressed("ui_accept")
	
	# Si un objet interactif est proche et qu'on vient d'appuyer sur E (just_pressed)
	if current_interactable and current_interactable.is_player_nearby():
		if e_pressed_now and not e_pressed_last_frame:
			# E vient d'être pressé (just_pressed)
			current_interactable.trigger_interaction()
	
	# Mettre à jour le flag pour le prochain frame
	e_pressed_last_frame = e_pressed_now

func _process(_delta: float) -> void:
	if not player:
		return
	
	# Chercher les objets interactifs proches
	var nearby_interactable = _find_nearby_interactable()
	
	# Afficher le texte seulement si un objet est proche ET peut être utilisé
	if nearby_interactable and nearby_interactable.is_player_nearby() and nearby_interactable.can_interact:
		# Afficher le texte d'interaction avec transition douce
		if interact_label:
			interact_label.text = nearby_interactable.get_interaction_text()
			interact_label.modulate.a = lerp(interact_label.modulate.a, 1.0, 0.2)
			interact_label.modulate = Color(1, 1, 1, interact_label.modulate.a)  # Maintenir blanc
		current_interactable = nearby_interactable
	else:
		# Cacher le texte complètement (invisible, pas sombre)
		if interact_label:
			interact_label.modulate.a = 0.0
			interact_label.modulate = Color(1, 1, 1, 0.0)
		current_interactable = null

func _find_nearby_interactable() -> Interactable:
	# Trouver tous les objets Interactable dans la scène
	var interactables = get_tree().get_nodes_in_group("interactables")
	
	var closest: Interactable = null
	var closest_distance: float = INF
	
	for node in interactables:
		if not node is Interactable:
			continue
		
		var interactable: Interactable = node as Interactable
		
		# Vérifier si le joueur est dans la zone (via les signaux Area3D)
		if interactable.is_player_nearby():
			var distance = player.global_position.distance_to(interactable.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest = interactable
	
	return closest
