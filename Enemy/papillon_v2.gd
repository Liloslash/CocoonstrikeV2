extends EnemyBase

# === PAPILLON V2 ===
# Ennemi volant plus agressif que le V1
# Même PV mais flottement plus rapide, déplacement 1.5× plus rapide, dégâts 2× plus importants

# === PARAMÈTRES EXPORTÉS SPÉCIFIQUES AU PAPILLON V2 ===
@export_group("Papillon V2 - Statistiques")
@export var papillon_max_health: int = 75  # Même PV que le V1

@export_group("Papillon V2 - Mouvement")
@export var papillon_v2_movement_speed: float = 1.5  # 1.5× plus rapide que le V1

@export_group("Papillon V2 - Attaque")
@export var papillon_v2_damage_dealt: int = 20  # 2× les dégâts du V1 (10 → 20)

@export_group("Papillon V2 - Vol")
@export var flight_height: float = 0.2  # Hauteur de vol (en mètres au-dessus du sol)
@export var float_amplitude: float = 0.15  # Amplitude du flottement (haut/bas)
@export var float_speed: float = 3.0  # Flottement 2× plus rapide que V1 (1.5 → 3.0)

@export_group("Papillon V2 - Couleurs d'Impact")
@export var impact_color_1: Color = Color(1.0, 0.4, 0.2, 1)    # Orange
@export var impact_color_2: Color = Color(1.0, 0.0, 0.2, 1)    # Rouge
@export var impact_color_3: Color = Color(1.0, 0.7, 0.0, 1)    # Jaune-orange
@export var impact_color_4: Color = Color(1.0, 0.5, 0.0, 1)    # Orange foncé


# === VARIABLES SPÉCIFIQUES AU PAPILLON V2 ===
var gravity: float  # Gravité pour ce papillon (très réduite pour voler)
var float_timer: float = 0.0  # Timer pour le flottement
var original_y: float  # Position Y originale pour le flottement

# === MÉTHODES VIRTUELLES SURCHARGÉES ===

func _on_enemy_ready():
	# Initialisation spécifique au papillon V2
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 0.1  # Gravité très réduite pour voler
	
	# Configuration des collisions spécifique au papillon volant
	collision_layer = 2  # Ennemi sur la layer 2 (détectable par raycast)
	collision_mask = 3   # Détecte la layer 0 (environnement) + layer 1 (joueur)
	
	# Override des valeurs d'EnemyBase avec celles du papillon V2
	max_health = papillon_max_health
	current_health = max_health
	base_damage_dealt = papillon_v2_damage_dealt
	movement_speed_multiplier = papillon_v2_movement_speed
	
	# Configurer la hauteur de vol
	original_y = global_position.y
	global_position.y = original_y + flight_height
	
	
	# Démarrer l'animation de vol en permanence
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("PapillonV2IdleAnim"):
		sprite.play("PapillonV2IdleAnim")

func _on_physics_process(delta: float):
	# Physique spécifique au papillon V2 (vol + flottement rapide + collisions)
	
	# Timer pour le flottement (plus rapide que V1)
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
	# Effets de mort spécifiques au papillon V2 (pour plus tard)
	pass

# === MÉTHODE SPÉCIFIQUE AU PAPILLON V2 ===
# Cette méthode sera utilisée par PlayerCombat pour récupérer les couleurs d'impact
func get_impact_colors() -> Array[Color]:
	# Retourne les 4 couleurs d'impact du papillon V2 (tons orange/rouge)
	return [impact_color_1, impact_color_2, impact_color_3, impact_color_4]
