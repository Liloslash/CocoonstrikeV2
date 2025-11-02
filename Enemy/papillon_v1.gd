extends EnemyBase

# === PAPILLON V1 ===
# Ennemi volant qui hérite de toute la logique commune d'EnemyBase
# Configuration simple : 75 PV, vol permanent, survol des obstacles

# === PARAMÈTRES EXPORTÉS SPÉCIFIQUES AU PAPILLON ===
@export_group("Papillon - Statistiques")
@export var papillon_max_health: int = 75  # 3 tirs pour le tuer

@export_group("Papillon - Vol")
@export var flight_height: float = 0.2  # Hauteur de vol (en mètres au-dessus du sol)
@export var float_amplitude: float = 0.2  # Amplitude du flottement (haut/bas)
@export var float_speed: float = 1.5  # Vitesse du flottement

@export_group("Papillon - Couleurs d'Impact")
@export var impact_color_1: Color = Color(0.2, 0.6, 1.0, 1)    # Bleu
@export var impact_color_2: Color = Color(0.0, 0.8, 1.0, 1)    # Cyan
@export var impact_color_3: Color = Color(1.0, 0.4, 0.8, 1)    # Rose
@export var impact_color_4: Color = Color(1.0, 0.9, 0.2, 1)    # Jaune


# === VARIABLES SPÉCIFIQUES AU PAPILLON ===
var gravity: float  # Gravité pour ce papillon (très réduite pour voler)
var float_timer: float = 0.0  # Timer pour le flottement
var original_y: float  # Position Y originale pour le flottement

# === MÉTHODES VIRTUELLES SURCHARGÉES ===

func _on_enemy_ready():
	# Initialisation spécifique au papillon
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 0.1  # Gravité très réduite pour voler
	
	# Configuration des collisions spécifique au papillon volant
	collision_layer = 2  # Ennemi sur la layer 2 (détectable par raycast)
	collision_mask = 3   # Détecte la layer 0 (environnement) + layer 1 (joueur)
	
	# Override de la santé max d'EnemyBase avec celle du papillon
	max_health = papillon_max_health
	current_health = max_health
	
	# Configurer la hauteur de vol
	original_y = global_position.y
	global_position.y = original_y + flight_height
	
	
	# Démarrer l'animation de vol en permanence
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("PapillonIdleAnim"):
		sprite.play("PapillonIdleAnim")

func _on_physics_process(delta: float):
	# Physique spécifique au papillon (vol + flottement + collisions)
	
	# Timer pour le flottement
	float_timer += delta * float_speed
	
	# Calculer la position de flottement (mouvement sinusoïdal)
	var target_y = original_y + flight_height + sin(float_timer) * float_amplitude
	
	# Maintenir la hauteur de vol avec une gravité très faible
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
	
	# Appliquer le mouvement AVANT de forcer la position Y
	move_and_slide()
	
	
	# Forcer la position Y pour le flottement APRÈS les collisions
	# (pour éviter de passer à travers les murs)
	global_position.y = target_y


func _on_damage_taken(_damage: int):
	# Réactions spécifiques aux dégâts (pour l'instant, rien de spécial)
	pass

func _on_death():
	# Effets de mort spécifiques au papillon (pour plus tard)
	pass

# === MÉTHODE SPÉCIFIQUE AU PAPILLON ===
# Cette méthode sera utilisée par PlayerCombat pour récupérer les couleurs d'impact
func get_impact_colors() -> Array[Color]:
	# Retourne les 4 couleurs d'impact du papillon
	return [impact_color_1, impact_color_2, impact_color_3, impact_color_4]
