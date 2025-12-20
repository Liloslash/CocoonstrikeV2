extends Node3D

# === SYSTÈME DE VAGUES ===
# Gère les cycles de 5 vagues avec progression et système de paquets d'ennemis

# --- Références ---
@onready var spawn_point_zone_1: SpawnPoint = $SpawnPointZone1
@onready var spawn_point_zone_2: SpawnPoint = $SpawnPointZone2
@onready var spawn_point_zone_3: SpawnPoint = $SpawnPointZone3
@onready var spawn_point_zone_4: SpawnPoint = $SpawnPointZone4
@onready var player: Player = $Player

# --- Scènes d'ennemis ---
const BIG_MONSTER_V_1 = preload("uid://d0g5y8d0slojv")
const BIG_MONSTER_V_2 = preload("uid://bm2v2scene456")
const PAPILLON_V_1 = preload("uid://ku4i8q6cljds")
const PAPILLON_V_2 = preload("uid://c4lqud6bnoswo")

# --- Paramètres exportés ---
@export_group("Configuration Vagues")
@export var base_enemy_count: int = 5 # Nombre de base d'ennemis (n)
@export var base_timer: float = 30.0 # Timer de base en secondes
@export var packet_size: int = 5 # Nombre d'ennemis par paquet
@export var spawn_interval: float = 0.5 # Intervalle entre chaque spawn dans un paquet

# --- État interne ---
var current_wave_number: int = 0
var enemies_total: int = 0 # Nombre total d'ennemis dans la vague
var enemies_remaining: int = 0 # Ennemis restants à éliminer
var enemies_spawned: int = 0 # Nombre d'ennemis déjà spawnés
var enemies_alive: Array[EnemyBase] = [] # Liste des ennemis actifs
var max_simultaneous: int = 0 # Nombre max d'ennemis simultanés
var wave_timer: Timer = null
var timer_update_timer: Timer = null # Timer pour mettre à jour l'affichage du timer
var is_wave_active: bool = false
var current_timer_duration: float = 0.0

# --- Scènes d'ennemis mappées ---
var enemy_scenes: Dictionary = {
	"PapillonV1": PAPILLON_V_1,
	"PapillonV2": PAPILLON_V_2,
	"BigMonsterV1": BIG_MONSTER_V_1,
	"BigMonsterV2": BIG_MONSTER_V_2
}

# --- Scales des ennemis (selon world.tscn) ---
var enemy_scales: Dictionary = {
	"PapillonV1": 1.0,
	"PapillonV2": 1.0,
	"BigMonsterV1": 1.8,
	"BigMonsterV2": 1.8
}

# --- SpawnPoints disponibles ---
var spawn_points: Array[SpawnPoint] = []

func _ready() -> void:
	# Collecter les spawn points
	spawn_points = [spawn_point_zone_1, spawn_point_zone_2, spawn_point_zone_3, spawn_point_zone_4]

	# Trouver l'interrupteur et se connecter au signal
	var interrupteurs = get_tree().get_nodes_in_group("interrupteurs")
	for interrupteur in interrupteurs:
		if interrupteur.has_signal("wave_started"):
			interrupteur.wave_started.connect(_on_wave_started)

	# Initialiser le timer à 0
	_update_timer_display(0)


func _on_wave_started() -> void:
	if is_wave_active:
		return # Une vague est déjà en cours

	current_wave_number += 1
	_start_wave(current_wave_number)

func _start_wave(wave_number: int) -> void:
	is_wave_active = true

	# Calculer les paramètres de la vague
	var params = _calculate_wave_params(wave_number)
	enemies_total = params.total_enemies
	enemies_remaining = enemies_total
	enemies_spawned = 0
	max_simultaneous = params.max_simultaneous

	# Mettre à jour le HUD
	_update_hud()

	# Spawn le premier paquet
	_spawn_packet()

	# Démarrer le timer de vague
	current_timer_duration = params.timer_duration
	_update_timer_display(int(params.timer_duration)) # Afficher le timer initial
	_start_wave_timer(params.timer_duration)
	_start_timer_update()

func _calculate_wave_params(wave_number: int) -> Dictionary:
	var cycle = (wave_number - 1) / 5
	var wave_in_cycle = ((wave_number - 1) % 5) + 1

	# Progression inter-cycles
	var n = base_enemy_count + cycle
	var timer_duration = max(5.0, base_timer - cycle) # Minimum 5 secondes

	# Calcul selon la vague dans le cycle
	var total_enemies: int
	var max_simultaneous: int
	var stat_boost: bool = false
	var all_varieties: bool = false

	match wave_in_cycle:
		1: # Vague 1 : Base
			total_enemies = n
			max_simultaneous = n
		2: # Vague 2 : Plus d'ennemis
			total_enemies = n + 2
			max_simultaneous = n + 2
		3: # Vague 3 : Augmentation simultanée
			total_enemies = n + 2
			max_simultaneous = n + 4
		4: # Vague 4 : Variété maximale
			total_enemies = n + 4
			max_simultaneous = n + 4
			all_varieties = true
		5: # Vague 5 : Spéciale
			total_enemies = n + 2
			max_simultaneous = n + 2
			stat_boost = true
			timer_duration *= 0.8 # Timer restreint

	return {
		"total_enemies": total_enemies,
		"max_simultaneous": max_simultaneous,
		"timer_duration": timer_duration,
		"stat_boost": stat_boost,
		"all_varieties": all_varieties
	}

func _spawn_packet() -> void:
	# Calculer combien d'ennemis spawner dans ce paquet
	var remaining_to_spawn = enemies_total - enemies_spawned
	var available_slots = max_simultaneous - enemies_alive.size()
	var to_spawn = min(packet_size, remaining_to_spawn, available_slots)

	if to_spawn <= 0:
		return

	# Spawn les ennemis avec intervalle
	var params = _calculate_wave_params(current_wave_number)
	var stat_boost = params.get("stat_boost", false)

	for i in range(to_spawn):
		var enemy_scene = _select_enemy_scene()
		if enemy_scene:
			await get_tree().create_timer(spawn_interval * i).timeout
			_spawn_enemy(enemy_scene, stat_boost)

func _get_enemy_name_from_scene(scene: PackedScene) -> String:
	# Retourner le nom de l'ennemi correspondant à la scène
	for enemy_name in enemy_scenes.keys():
		if enemy_scenes[enemy_name] == scene:
			return enemy_name
	return ""

func _select_enemy_scene() -> PackedScene:
	# Sélection complètement aléatoire
	var keys = enemy_scenes.keys()
	if keys.is_empty():
		return null
	return enemy_scenes[keys[randi() % keys.size()]]

func _spawn_enemy(enemy_scene: PackedScene, stat_boost: bool = false) -> void:
	if enemy_scene == null:
		return

	# Sélectionner un spawn point aléatoire
	if spawn_points.is_empty():
		push_warning("World: Aucun SpawnPoint disponible")
		return

	var spawn_point = spawn_points[randi() % spawn_points.size()]
	if spawn_point == null or not spawn_point.is_inside_tree():
		return

	# Obtenir une position aléatoire dans la zone
	var spawn_position = spawn_point.get_spawn_position()

	# Instancier l'ennemi
	var enemy = enemy_scene.instantiate()
	if enemy == null:
		push_warning("World: Impossible d'instancier l'ennemi")
		return

	if not enemy is EnemyBase:
		push_warning("World: L'ennemi instancié n'est pas un EnemyBase")
		enemy.queue_free()
		return

	# Appliquer les boosts de stats si nécessaire
	if stat_boost:
		enemy.apply_stat_boost(1.25, 1.25) # +25% PV et dégâts

	# Positionner l'ennemi
	enemy.global_position = spawn_position

	# Ajouter à la scène
	add_child(enemy)

	# Appliquer le scale selon le type d'ennemi (après ajout à la scène)
	var enemy_name = _get_enemy_name_from_scene(enemy_scene)
	if enemy_name != "":
		var scale = enemy_scales.get(enemy_name, 1.0)
		enemy.scale = Vector3.ONE * scale

	enemies_alive.append(enemy)
	enemies_spawned += 1

	# Connecter le signal de mort
	enemy.enemy_died.connect(_on_enemy_died)

	# Mettre à jour le HUD après chaque spawn
	_update_hud()

func _on_enemy_died() -> void:
	# Retirer les ennemis morts de la liste
	for i in range(enemies_alive.size() - 1, -1, -1):
		var enemy = enemies_alive[i]
		if enemy == null or not is_instance_valid(enemy) or enemy.is_dead():
			enemies_alive.remove_at(i)

	# Décrémenter le compteur
	enemies_remaining = max(0, enemies_remaining - 1)

	# Mettre à jour le HUD
	_update_hud()

	# Vérifier si on doit relancer un paquet (15% restants)
	_check_packet_respawn()

	# Vérifier si la vague est terminée
	if enemies_remaining <= 0:
		_end_wave()

func _check_packet_respawn() -> void:
	if not is_wave_active:
		return

	# Calculer le seuil de 15% du nombre total
	var threshold = max(1, int(enemies_total * 0.15))

	# Si on est en dessous du seuil (15% restants) et qu'il reste des ennemis à spawner
	if enemies_remaining <= threshold:
		var remaining_to_spawn = enemies_total - enemies_spawned

		# Si on a encore des ennemis à spawner et qu'on n'a pas atteint le max simultané
		if remaining_to_spawn > 0 and enemies_alive.size() < max_simultaneous:
			_spawn_packet()

func _start_wave_timer(duration: float) -> void:
	if wave_timer != null:
		wave_timer.queue_free()

	wave_timer = Timer.new()
	wave_timer.wait_time = duration
	wave_timer.one_shot = true
	add_child(wave_timer)
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	wave_timer.start()

func _start_timer_update() -> void:
	if timer_update_timer != null:
		timer_update_timer.queue_free()

	timer_update_timer = Timer.new()
	timer_update_timer.wait_time = 1.0 # Mise à jour chaque seconde
	timer_update_timer.one_shot = false
	add_child(timer_update_timer)
	timer_update_timer.timeout.connect(_update_timer_display_continuous)
	timer_update_timer.start()

func _update_timer_display_continuous() -> void:
	if not is_wave_active or wave_timer == null:
		return

	var remaining_time = max(0, int(wave_timer.time_left))
	_update_timer_display(remaining_time)

func _update_timer_display(time_value: int) -> void:
	if player == null:
		return
	player.update_timer_counter(time_value)

func _on_wave_timer_timeout() -> void:
	# Le temps est écoulé, terminer la vague (échec)
	_end_wave()

func _end_wave() -> void:
	is_wave_active = false

	# Arrêter les timers
	if wave_timer != null:
		wave_timer.stop()
		wave_timer.queue_free()
		wave_timer = null

	if timer_update_timer != null:
		timer_update_timer.stop()
		timer_update_timer.queue_free()
		timer_update_timer = null

	# Mettre le timer à 0 pendant l'inter-vague
	_update_timer_display(0)

	# Réinitialiser l'interrupteur
	var interrupteurs = get_tree().get_nodes_in_group("interrupteurs")
	for interrupteur in interrupteurs:
		if interrupteur.has_method("toggle_state") and interrupteur.is_in_wave:
			interrupteur.toggle_state()

func _update_hud() -> void:
	if player == null:
		return

	player.update_wave_counter(current_wave_number)
	# Afficher le nombre d'ennemis actuellement vivants, pas ceux restants à éliminer
	player.update_enemies_counter(enemies_alive.size(), enemies_total)
