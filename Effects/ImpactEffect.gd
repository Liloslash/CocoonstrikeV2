extends Node3D

# === EFFET D'IMPACT ===
# Effet d'impact pixel explosion qui s'adapte aux couleurs du sprite touché

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
@export var cube_size: float = 0.056  # Taille des cubes de particules

# === VARIABLES INTERNES ===
var created_particle_systems: Array[GPUParticles3D] = []

# === INITIALISATION ===
func _ready() -> void:
	# Le système original sera configuré si aucune couleur n'est fournie
	pass

# === FONCTION PUBLIQUE ===
func set_impact_colors(colors: Array[Color]) -> void:
	impact_colors = colors
	
	# Si aucune couleur n'est fournie, utiliser le système original
	if impact_colors.size() == 0:
		_configure_original_particles()
		particles.emitting = true
		await particles.finished
		queue_free()
		return
	
	# Créer un système de particules pour chaque couleur
	_apply_all_colors()
	
	# Attendre la fin de tous les systèmes de particules créés
	await _wait_for_all_particles_finished()
	queue_free()

# === FONCTIONS PRIVÉES ===

# --- Configuration du système original (sans couleurs) ---
func _configure_original_particles() -> void:
	particles.amount = particle_count
	particles.lifetime = effect_duration
	particles.one_shot = true
	particles.explosiveness = 1.0
	
	# Configurer le matériel du système original
	var material = particles.process_material as ParticleProcessMaterial
	if material:
		_configure_particle_material(material)
	
	# Appliquer la taille des cubes
	var box_mesh = particles.draw_pass_1 as BoxMesh
	if box_mesh:
		box_mesh.size = Vector3(cube_size, cube_size, cube_size)
		box_mesh.material = null

# --- Création de systèmes de particules avec couleurs ---
func _apply_all_colors() -> void:
	# Désactiver le système original
	particles.emitting = false
	
	# Créer un système de particules pour chaque couleur
	for i in range(impact_colors.size()):
		var color_particles = _create_colored_particle_system(impact_colors[i], impact_colors.size())
		add_child(color_particles)
		created_particle_systems.append(color_particles)

# --- Création d'un système de particules avec une couleur spécifique ---
func _create_colored_particle_system(color: Color, total_colors: int) -> GPUParticles3D:
	var color_particles = GPUParticles3D.new()
	
	# Configuration de base des particules
	color_particles.amount = int(float(particle_count) / float(total_colors))
	color_particles.lifetime = effect_duration
	color_particles.one_shot = true
	color_particles.explosiveness = 1.0
	color_particles.emitting = true
	
	# Créer et configurer le matériel
	var material = ParticleProcessMaterial.new()
	_configure_particle_material(material)
	material.scale_min = 0.5
	material.scale_max = 1.5
	material.color = color
	color_particles.process_material = material
	
	# Créer le mesh avec la couleur
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(cube_size, cube_size, cube_size)
	var mesh_material = StandardMaterial3D.new()
	mesh_material.albedo_color = color
	box_mesh.material = mesh_material
	color_particles.draw_pass_1 = box_mesh
	
	return color_particles

# --- Configuration du matériel de particules (fonction helper) ---
func _configure_particle_material(material: ParticleProcessMaterial) -> void:
	material.emission_shape = ParticleProcessMaterial.EmissionShape.EMISSION_SHAPE_POINT
	material.direction = Vector3(0, 0, 0)  # Direction neutre
	material.spread = 360.0  # Spread dans toutes les directions
	material.initial_velocity_min = explosion_force_min
	material.initial_velocity_max = explosion_force_max
	material.gravity = Vector3(0, 0, 0)  # Pas de gravité

# --- Attendre la fin de tous les systèmes de particules ---
func _wait_for_all_particles_finished() -> void:
	# Attendre que tous les systèmes de particules se terminent
	for particle_system in created_particle_systems:
		if is_instance_valid(particle_system):
			await particle_system.finished
