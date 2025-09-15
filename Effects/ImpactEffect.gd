extends Node3D

# Effet d'impact pixel explosion
# S'adapte aux couleurs du sprite touché et aux paramètres d'arme

@onready var particles: GPUParticles3D = $GPUParticles3D

# === PARAMÈTRES EXPORTÉS ===
@export_group("Durée et Intensité")
@export var effect_duration: float = 1.5  # Durée totale de l'effet
@export var particle_count: int = 20  # Nombre de particules

@export_group("Physique")
@export var explosion_force_min: float = 3.0  # Force d'explosion minimale
@export var explosion_force_max: float = 8.0  # Force d'explosion maximale
@export var bounce_strength: float = 0.6  # Force de rebond (0 = pas de rebond, 1 = rebond parfait)
@export var bounce_randomness: float = 0.2  # Variation des rebonds pour plus de réalisme

@export_group("Couleurs")
@export var color1: Color = Color.WHITE  # Couleur dominante du sprite
@export var color2: Color = Color.ORANGE  # Couleur secondaire
@export var color3: Color = Color.RED  # Couleur tertiaire

func _ready():
	print("ImpactEffect: _ready() appelé")
	
	# Configuration complète des particules dans le script
	_configure_particles()
	
	# Démarrer l'effet immédiatement
	particles.emitting = true
	print("ImpactEffect: particules démarrées")
	
	# Attendre la fin de l'effet puis se supprimer
	await particles.finished
	print("ImpactEffect: effet terminé, suppression")
	queue_free()

func _configure_particles():
	# Configuration ultra-simple des particules
	particles.amount = 20
	particles.lifetime = 1.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	
	print("ImpactEffect: particules configurées")

# Fonction pour définir les couleurs d'impact de l'ennemi
func set_sprite_colors(dominant_color: Color, secondary_color: Color, tertiary_color: Color):
	color1 = dominant_color
	color2 = secondary_color
	color3 = tertiary_color
	
	# Créer un gradient simple avec les 3 couleurs
	_create_simple_gradient(dominant_color, secondary_color, tertiary_color)
	print("Couleurs d'impact appliquées: ", dominant_color, " | ", secondary_color, " | ", tertiary_color)

# Fonction pour créer un gradient simple avec les 3 couleurs
func _create_simple_gradient(_color1: Color, _color2: Color, _color3: Color):
	# Créer un gradient avec les 3 couleurs
	var gradient = Gradient.new()
	gradient.add_point(0.0, _color1)  # Couleur au début (dominante)
	gradient.add_point(0.5, _color2)  # Couleur au milieu (secondaire)
	gradient.add_point(1.0, _color3)  # Couleur à la fin (tertiaire)
	
	# Appliquer le gradient au matériel des particules
	var material = particles.process_material as ParticleProcessMaterial
	if material:
		material.color_ramp = gradient
		print("Gradient appliqué avec 3 couleurs")

# Fonction pour adapter l'effet selon le type d'arme
func set_weapon_intensity(_intensity_multiplier: float):
	# Pour l'instant, on garde les paramètres par défaut
	# Cette fonction sera utilisée pour les armes futures
	pass
