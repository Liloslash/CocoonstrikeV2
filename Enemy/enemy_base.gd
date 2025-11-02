extends CharacterBody3D
class_name EnemyBase

# === CLASSE DE BASE POUR TOUS LES ENNEMIS ===
# Cette classe abstraite contient toute la logique commune des ennemis
# Les ennemis spécifiques héritent de cette classe et peuvent surcharger les méthodes

# === PARAMÈTRES EXPORTÉS COMMUNS ===
@export_group("Statistiques")
@export var max_health: int = 100

@export_group("Effet de Rougissement")
@export var red_flash_duration: float = 0.2  # Durée du rougissement (0.2 secondes)
@export var red_flash_intensity: float = 1.5  # Intensité du rouge (1.5 pour un effet bien visible)
@export var red_flash_color: Color = Color.RED  # Couleur du rougissement

@export_group("Freeze après Dégâts")
@export var damage_freeze_duration: float = 0.25  # Durée du freeze après avoir pris des dégâts

@export_group("Slam Repoussement")
@export var slam_push_force: float = 4.0  # Force du repoussement
@export var slam_bond_duration: float = 0.6  # Durée du bond avant arrêt horizontal
@export var slam_freeze_delay: float = 0.8  # Délai avant le freeze
@export var slam_cooldown_time: float = 0.2  # Cooldown entre les slams


# === VARIABLES INTERNES ===
var current_health: int
var is_alive: bool = true
var is_frozen: bool = false
var player_reference: Node3D = null
var freeze_timer: float = 0.0
var slam_cooldown: float = 0.0
var is_being_slam_repelled: bool = false  # Pour distinguer le repoussement slam des autres freezes

# === COMPOSANTS ===
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D  # Le sprite 2D billboard

# === MÉTHODES VIRTUELLES À SURCHARGER ===
# Ces méthodes peuvent être surchargées par les ennemis spécifiques

func _on_enemy_ready():
	# Surcharger cette méthode pour l'initialisation spécifique à chaque ennemi
	pass

func _on_physics_process(_delta: float):
	# Surcharger cette méthode pour le comportement spécifique de chaque ennemi
	pass

func _on_damage_taken(_damage: int):
	# Surcharger cette méthode pour des réactions spécifiques aux dégâts
	pass

func _on_death():
	# Surcharger cette méthode pour des effets de mort spécifiques
	pass


# === INITIALISATION DE BASE ===
func _ready():
	# Initialisation commune à tous les ennemis
	current_health = max_health
	
	# Configuration des collisions (spécifique à chaque type d'ennemi)
	# Les papillons auront collision_layer/mask différents des monstres terrestres
	
	# Ajouter au groupe des ennemis pour la détection du slam
	add_to_group("enemies")
	
	# Recherche du joueur dans la scène
	_find_player()
	
	# Appeler la méthode virtuelle pour l'initialisation spécifique
	_on_enemy_ready()

func _find_player():
	# Cherche le joueur dans la scène (adaptez selon votre structure)
	var world = get_tree().get_first_node_in_group("world")
	if world:
		player_reference = world.get_node_or_null("Player")
	
	if not player_reference:
		# Recherche alternative - chercher directement dans la scène
		player_reference = get_tree().get_first_node_in_group("player")
	
	if not player_reference:
		# Recherche directe par nom de nœud
		player_reference = get_node_or_null("/root/World/Player")
	
	# Vérifier si le joueur est trouvé
	if not player_reference:
		push_warning("Ennemi : Joueur non trouvé - la rotation ne fonctionnera pas")

# === PHYSICS PROCESS DE BASE ===
func _physics_process(delta):
	if not is_alive:
		return
	
	# Gérer le freeze (pendant les animations)
	_handle_freeze(delta)
	
	# Gérer le cooldown du slam
	if slam_cooldown > 0:
		slam_cooldown -= delta
	
	# Si l'ennemi ne peut pas bouger, ne pas exécuter le comportement physique
	if not _can_move():
		return

	# Les ennemis spécifiques gèrent leur propre physique
	# (gravité, mouvement, collisions) dans _on_physics_process()

	# ROTATION DU SPRITE VERS LE JOUEUR (commune à tous)
	_update_sprite_rotation()
	
	# Appeler la méthode virtuelle pour le comportement spécifique
	_on_physics_process(delta)

# === SYSTÈME DE DÉGÂTS (COMMUN À TOUS) ===
func take_damage(damage: int, hit_effect_params: Dictionary = {}):
	if not is_alive:
		return
	
	current_health -= damage
	
	# Effet de rougissement au moment de l'impact (commun)
	_create_red_flash()
	
	# Effet de vibration si des paramètres sont fournis (commun)
	if hit_effect_params:
		_create_hit_shake(hit_effect_params)
	
	# Freeze pendant l'animation de tremblement (commun)
	_start_damage_freeze()
	
	# Appeler la méthode virtuelle pour les réactions spécifiques
	_on_damage_taken(damage)
	
	# Vérification de la mort
	if current_health <= 0:
		_die()

# === SYSTÈME DE REPOUSSEMENT DU SLAM (COMMUN À TOUS) ===
func _apply_slam_repulsion(direction: Vector3, _push_distance: float, push_height: float, freeze_duration: float):
	if not is_alive:
		return
	
	# Vérifier le cooldown (éviter les slams trop rapides)
	if slam_cooldown > 0:
		return
	
	# Marquer qu'on est en train d'être repoussé par un slam
	is_being_slam_repelled = true
	
	# Sortir du freeze si on était gelé
	is_frozen = false
	freeze_timer = 0.0
	
	# Calculer la vélocité de repoussement (force constante, peu importe la distance)
	var push_velocity = Vector3(
		direction.x * slam_push_force,  # Force horizontale configurable
		push_height * slam_push_force,  # Force verticale configurable
		direction.z * slam_push_force
	)
	
	# Appliquer la vélocité IMMÉDIATEMENT
	velocity = push_velocity
	
	# Mettre un cooldown court pour éviter les slams multiples
	slam_cooldown = slam_cooldown_time
	
	# Programmer l'arrêt du mouvement après le bond
	_stop_after_bond()
	
	# Freeze après le bond
	await get_tree().create_timer(slam_freeze_delay).timeout
	# Vérifier que l'ennemi est toujours vivant avant de continuer
	if not is_alive:
		return
	is_frozen = true
	freeze_timer = freeze_duration
	is_being_slam_repelled = false  # Fin du repoussement slam

func _stop_after_bond():
	# Arrêter le mouvement horizontal après le bond
	await get_tree().create_timer(slam_bond_duration).timeout
	# Vérifier que l'ennemi est toujours vivant avant de continuer
	if not is_alive:
		return
	velocity.x = 0.0
	velocity.z = 0.0

func _die():
	if not is_alive:
		return
		
	is_alive = false
	is_frozen = true
	_disable_collisions()
	
	# Appeler la méthode virtuelle pour les effets de mort spécifiques
	_on_death()
	
	# SUPPRESSION DU FREEZE DE MORT - à recréer plus tard selon les besoins
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

# === EFFET DE ROUGISSEMENT (COMMUN À TOUS) ===
func _create_red_flash():
	# Vérification que l'ennemi est vivant et a un sprite
	if not is_alive or not sprite or not is_inside_tree():
		return
	
	# Sauvegarde de la couleur originale
	var original_color = sprite.modulate
	
	# Création du tween pour l'effet de rougissement
	var flash_tween = create_tween()
	
	# Calcul de la couleur de rougissement
	var flash_color = Color(
		red_flash_color.r * red_flash_intensity,
		red_flash_color.g * red_flash_intensity,
		red_flash_color.b * red_flash_intensity,
		red_flash_color.a
	)
	
	# Phase 1 : Apparition rapide du rouge (EASE_OUT)
	flash_tween.tween_property(sprite, "modulate", flash_color, red_flash_duration * 0.3)
	flash_tween.set_trans(Tween.TRANS_QUAD)
	flash_tween.set_ease(Tween.EASE_OUT)
	
	# Phase 2 : Retour à la couleur originale (EASE_OUT)
	flash_tween.tween_property(sprite, "modulate", original_color, red_flash_duration * 0.7)
	flash_tween.set_trans(Tween.TRANS_QUAD)
	flash_tween.set_ease(Tween.EASE_OUT)

# === EFFET DE VIBRATION (COMMUN À TOUS) ===
func _create_hit_shake(effect_params: Dictionary):
	# Vérification que l'ennemi est vivant et a un sprite
	if not is_alive or not sprite or not is_inside_tree():
		return
	
	# Sauvegarde de la position et rotation originales
	var original_position = sprite.position
	var original_rotation = sprite.rotation
	
	# Création du tween pour l'effet de vibration
	var shake_tween = create_tween()
	
	# Récupération des paramètres avec valeurs par défaut
	var duration = effect_params.get("duration", 0.25)
	var intensity = effect_params.get("intensity", 0.1)
	var frequency = effect_params.get("frequency", 20.0)
	var axes = effect_params.get("axes", Vector3(1.0, 1.0, 0.0))
	
	# Calcul du nombre d'oscillations basé sur la durée et la fréquence
	var oscillations = int(duration * frequency)
	
	# Création du pattern de vibration
	for i in range(oscillations):
		# Calcul de l'intensité qui diminue progressivement
		var current_intensity = intensity * (1.0 - float(i) / float(oscillations))
		
		# Direction aléatoire pour la vibration (seulement sur les axes activés)
		var random_direction = Vector3(
			randf_range(-1.0, 1.0) * axes.x,
			randf_range(-1.0, 1.0) * axes.y,
			randf_range(-1.0, 1.0) * axes.z
		).normalized()
		
		# Décalage de vibration
		var shake_offset = random_direction * current_intensity
		var shake_rotation_offset = Vector3(0, 0, random_direction.z * current_intensity)
		
		# Durée de chaque oscillation
		var oscillation_duration = duration / float(oscillations)
		
		# Ajout du mouvement au tween (relatif à la position originale)
		shake_tween.tween_property(sprite, "position", original_position + shake_offset, oscillation_duration)
		shake_tween.tween_property(sprite, "rotation", original_rotation + shake_rotation_offset, oscillation_duration)
	
	# Retour à la position originale à la fin
	shake_tween.tween_property(sprite, "position", original_position, 0.1)
	shake_tween.tween_property(sprite, "rotation", original_rotation, 0.1)
	
	# Arrêt du tween après la durée totale
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func(): 
		if shake_tween and shake_tween.is_valid():
			shake_tween.kill()
	, CONNECT_ONE_SHOT)  # Connexion automatique supprimée après utilisation
	
	# Forcer le retour à la position originale (sécurité)
	sprite.position = original_position
	sprite.rotation = original_rotation

# === ROTATION DU SPRITE VERS LE JOUEUR (COMMUNE À TOUS) ===
func _update_sprite_rotation():
	# Vérifier que l'ennemi est vivant, a un sprite et un joueur de référence
	if not is_alive or not sprite or not player_reference or not is_inside_tree() or not is_instance_valid(player_reference):
		return
	
	# Calculer la direction vers le joueur (SEULEMENT sur l'axe X/Z)
	var direction_to_player = (player_reference.global_position - global_position)
	direction_to_player.y = 0  # Ignorer l'axe Y (hauteur)
	direction_to_player = direction_to_player.normalized()
	
	# Créer un point cible devant l'ennemi dans la direction du joueur (même hauteur)
	var look_target = global_position + direction_to_player
	
	# Faire tourner le sprite pour regarder vers le joueur (rotation uniquement sur Y)
	sprite.look_at(look_target, Vector3.UP)

# === SYSTÈME DE FREEZE (PENDANT LES ANIMATIONS) ===
func _handle_freeze(delta: float) -> void:
	if not is_frozen:
		return
	
	freeze_timer -= delta
	if freeze_timer <= 0:
		is_frozen = false
		freeze_timer = 0.0

# === MÉTHODE UTILITAIRE POUR VÉRIFIER SI L'ENNEMI PEUT BOUGER ===
func _can_move() -> bool:
	# L'ennemi peut bouger s'il est vivant ET :
	# - Soit il n'est pas gelé
	# - Soit il est gelé MAIS en train d'être repoussé par un slam
	return is_alive and (not is_frozen or is_being_slam_repelled)

func _start_damage_freeze() -> void:
	# Freeze pendant la durée de l'animation de tremblement
	# MAIS seulement si on n'est pas en train d'être repoussé par un slam
	if not is_being_slam_repelled:
		is_frozen = true
		freeze_timer = damage_freeze_duration
