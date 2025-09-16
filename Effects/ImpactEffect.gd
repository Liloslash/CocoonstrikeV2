extends Node3D

# Effet d'impact pixel explosion
# S'adapte aux couleurs du sprite touché et aux paramètres d'arme

@onready var particles: GPUParticles3D = $GPUParticles3D

# === PARAMÈTRES EXPORTÉS ===
@export_group("Durée et Intensité")
@export var effect_duration: float = 0.4  # Durée totale de l'effet
@export var particle_count: int = 32  # Nombre total de particules

@export_group("Physique")
@export var explosion_force_min: float = 3.0  # Force d'explosion minimale
@export var explosion_force_max: float = 6.0  # Force d'explosion maximale

@export_group("Couleurs")
@export var impact_colors: Array[Color] = []  # Les 4 couleurs de l'ennemi

@export_group("Apparence")
@export var cube_size: float = 0.056  # Taille des cubes de particules (réduite d'un quart de plus)

func _ready():
	# Configuration complète des particules dans le script
	_configure_particles()

func _configure_particles():
	# Configuration pour effet court et punchy
	particles.amount = particle_count
	particles.lifetime = effect_duration
	particles.one_shot = true
	particles.explosiveness = 1.0
	
	# Modifier le matériel du système original
	var material = particles.process_material as ParticleProcessMaterial
	if material:
		material.emission_shape = 0  # Point d'émission
		material.direction = Vector3(0, 0, 0)  # Direction neutre
		material.spread = 360.0  # Spread dans toutes les directions
		material.initial_velocity_min = explosion_force_min  # Utilise la variable exportable
		material.initial_velocity_max = explosion_force_max  # Utilise la variable exportable
		material.gravity = Vector3(0, 0, 0)  # Pas de gravité
	
	# Appliquer la taille des cubes
	var box_mesh = particles.draw_pass_1 as BoxMesh
	if box_mesh:
		box_mesh.size = Vector3(cube_size, cube_size, cube_size)
		box_mesh.material = null
	

# Fonction pour définir les couleurs d'impact de l'ennemi
func set_impact_colors(colors: Array[Color]):
	impact_colors = colors
	
	# Appliquer toutes les couleurs aux particules
	_apply_all_colors()
	
	# Démarrer les particules
	particles.emitting = true
	
	# Attendre la fin de l'effet puis se supprimer
	await particles.finished
	queue_free()

# Fonction pour créer plusieurs systèmes de particules avec des couleurs différentes
func _apply_all_colors():
	if impact_colors.size() == 0:
		return
	
	# Créer un système de particules pour chaque couleur
	for i in range(impact_colors.size()):
		var color_particles = GPUParticles3D.new()
		add_child(color_particles)
		
		# Configuration des particules pour effet localisé
		color_particles.amount = int(float(particle_count) / float(impact_colors.size()))  # Répartir le nombre total
		color_particles.lifetime = effect_duration
		color_particles.one_shot = true
		color_particles.explosiveness = 1.0
		color_particles.emitting = true
		
		# Matériel avec la couleur spécifique
		var material = ParticleProcessMaterial.new()
		material.emission_shape = 0  # Point d'émission (pas de sphère)
		material.direction = Vector3(0, 0, 0)  # Direction neutre
		material.spread = 360.0  # Spread dans toutes les directions
		material.initial_velocity_min = explosion_force_min  # Utilise la variable exportable
		material.initial_velocity_max = explosion_force_max  # Utilise la variable exportable
		material.gravity = Vector3(0, 0, 0)  # Pas de gravité
		material.scale_min = 0.5
		material.scale_max = 1.5
		material.color = impact_colors[i]
		color_particles.process_material = material
		
		# Mesh avec la couleur
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(cube_size, cube_size, cube_size)
		var mesh_material = StandardMaterial3D.new()
		mesh_material.albedo_color = impact_colors[i]
		box_mesh.material = mesh_material
		color_particles.draw_pass_1 = box_mesh
		
	
	# Désactiver le système original
	particles.emitting = false
