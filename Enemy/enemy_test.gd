extends "res://Enemy/enemy_base.gd"

# === SYSTÈME D'ENNEMI TEST ===
# Classe de test pour développer le gameplay des ennemis
# Hérite d'EnemyBase et peut surcharger les méthodes pour des tests spécifiques

# === PARAMÈTRES EXPORTÉS SPÉCIFIQUES AU TEST ===
@export_group("Test - Comportement")
@export var test_debug_mode: bool = false  # Mode debug pour afficher des informations

@export_group("Test - Physique")
@export var test_gravity_scale: float = 1.2  # Gravité spécifique au test

@export_group("Test - Couleurs d'Impact")
@export var impact_color_1: Color = Color(0.996126, 0, 0.238011, 1)  # Rouge
@export var impact_color_2: Color = Color(0.40019, 1, 0.369744, 1)    # Vert
@export var impact_color_3: Color = Color(0.685821, 0.297101, 0.981954, 1)  # Violet
@export var impact_color_4: Color = Color(0.176419, 0.176419, 0.176419, 1)  # Noir

# === VARIABLES SPÉCIFIQUES AU TEST ===
var test_damage_count: int = 0  # Compteur de dégâts reçus pour les tests
var test_rotation_angle: float = 0.0  # Angle de rotation pour les tests visuels
var gravity: float  # Gravité pour ce test
var initial_position: Vector3  # Position initiale définie dans la scène

# === MÉTHODES VIRTUELLES SURCHARGÉES ===

func _on_enemy_ready():
	# Initialisation spécifique à l'ennemi de test
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * test_gravity_scale
	
	# Configuration des collisions spécifique au test
	collision_layer = 2  # Ennemi sur la layer 2 (détectable par raycast)
	collision_mask = 3   # Détecte la layer 0 (environnement) + layer 1 (joueur)
	
	# Sauvegarder la position initiale définie dans la scène
	initial_position = global_position
	# Juste corriger Y pour être au sol
	global_position.y = 0.75
	initial_position.y = 0.75
	
	

func _on_physics_process(delta: float):
	# Si on est en cours de repoussement slam, appliquer le mouvement puis forcer au sol
	if is_being_slam_repelled:
		# Appliquer le mouvement complet
		move_and_slide()
		# APRÈS le mouvement, forcer la position Y au sol (pas de saut pour EnemyTest)
		global_position.y = 0.75
		
		# Si l'ennemi va trop loin, le ramener à sa position initiale
		if global_position.distance_to(initial_position) > 10.0:
			global_position = initial_position
		return
	
	# Position fixe au sol pour éviter l'enfoncement
	global_position.y = 0.75
	velocity = Vector3.ZERO
	
	# Remettre le sprite à sa position d'origine (sauf rotation Y vers le joueur)
	if sprite:
		sprite.position = Vector3.ZERO
		sprite.rotation.x = 0.0
		sprite.rotation.z = 0.0
	
	# Comportement de test (rotation visuelle si debug activé)
	if test_debug_mode:
		test_rotation_angle += delta * 10.0
		if sprite:
			sprite.rotation.z = sin(test_rotation_angle) * 0.1

func _on_damage_taken(_damage: int):
	# Réaction spécifique aux dégâts pour l'ennemi de test
	test_damage_count += 1

func _on_death():
	# Effets de mort spécifiques à l'ennemi de test
	pass


# === MÉTHODES SPÉCIFIQUES AU TEST ===

func get_test_stats() -> Dictionary:
	# Retourne les statistiques de test pour debug
	return {
		"damage_count": test_damage_count,
		"health_percentage": get_health_percentage(),
		"is_alive": is_alive,
		"is_frozen": is_frozen,
		"rotation_angle": test_rotation_angle
	}

func reset_test_stats():
	# Remet à zéro les statistiques de test
	test_damage_count = 0
	test_rotation_angle = 0.0

# === GETTER POUR LES COULEURS D'IMPACT ===
func get_impact_colors() -> Array[Color]:
	return [impact_color_1, impact_color_2, impact_color_3, impact_color_4]

# === MÉTHODES DE TEST POUR LE DÉVELOPPEMENT ===

func _input(_event):
	# Méthodes de test accessibles via input (pour debug uniquement)
	if not test_debug_mode:
		return
