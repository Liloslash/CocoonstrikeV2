extends EnemyBase

# === SYSTÈME D'ENNEMI TEST ===
# Classe de test pour développer le gameplay des ennemis
# Hérite d'EnemyBase et peut surcharger les méthodes pour des tests spécifiques

# === PARAMÈTRES EXPORTÉS SPÉCIFIQUES AU TEST ===
@export_group("Test - Statistiques")
@export var test_damage_multiplier: float = 1.0  # Multiplicateur de dégâts pour les tests

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

# === MÉTHODES VIRTUELLES SURCHARGÉES ===

func _on_enemy_ready():
	# Initialisation spécifique à l'ennemi de test
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * test_gravity_scale
	
	# Configuration des collisions spécifique au test
	collision_layer = 2  # Ennemi sur la layer 2 (détectable par raycast)
	collision_mask = 3   # Détecte la layer 0 (environnement) + layer 1 (joueur)
	
	if test_debug_mode:
		print("EnemyTest initialisé - Mode debug activé")
		print("Santé max: ", max_health)
		print("Force de repoussement slam: ", slam_push_force)
		print("Gravité: ", gravity)

func _on_physics_process(delta: float):
	# Physique spécifique au test (gravité + mouvement)
	
	# Gravité + déplacement
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# Arrêter le mouvement vertical quand on touche le sol
		if velocity.y < 0.0:
			velocity.y = 0.0
		# Arrêter aussi le mouvement horizontal pour éviter le glissement
		if abs(velocity.x) < 0.1 and abs(velocity.z) < 0.1:
			velocity.x = 0.0
			velocity.z = 0.0

	move_and_slide()
	
	# Comportement de test (rotation visuelle si debug activé)
	if test_debug_mode:
		test_rotation_angle += delta * 10.0  # Rotation lente pour test visuel
		if sprite:
			sprite.rotation.z = sin(test_rotation_angle) * 0.1

func _on_damage_taken(_damage: int):
	# Réaction spécifique aux dégâts pour l'ennemi de test
	test_damage_count += 1
	
	if test_debug_mode:
		print("EnemyTest - Dégâts reçus: ", _damage)
		print("EnemyTest - Total dégâts reçus: ", test_damage_count)
		print("EnemyTest - Santé restante: ", current_health)

func _on_death():
	# Effets de mort spécifiques à l'ennemi de test
	if test_debug_mode:
		print("EnemyTest - Mort détectée!")
		print("EnemyTest - Total dégâts reçus avant mort: ", test_damage_count)

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

func _input(event):
	# Méthodes de test accessibles via input (pour debug uniquement)
	if not test_debug_mode:
		return
	
	if event.is_action_pressed("ui_accept"):  # Touche Entrée
		print("=== STATS ENEMY TEST ===")
		var stats = get_test_stats()
		for key in stats:
			print(key, ": ", stats[key])
	
	elif event.is_action_pressed("ui_select"):  # Touche Espace
		print("Reset des stats de test")
		reset_test_stats()
	
	elif event.is_action_pressed("ui_cancel"):  # Touche Échap
		print("Test de dégâts (10 points)")
		take_damage(10)
