extends Node

class_name SpawnTestRunner

@export_node_path("SpawnPoint")
var spawn_point_path: NodePath

@export var spawn_interval: float = 8.0
@export var enemy_scenes: Array[PackedScene] = []
@export var floor_probe_height: float = 5.0
@export var floor_probe_max_drop: float = 10.0
@export var ground_offset: float = 1.2
@export var max_surface_height_above_point: float = 0.5
@export var clearance_radius: float = 1.5
@export var clearance_half_height: float = 1.0
@export_range(1, 20, 1) var max_spawn_attempts: int = 6
@export var retry_delay: float = 0.5
@export var is_active: bool = true
@export_flags("Zone 1", "Zone 2", "Zone 3", "Zone 4") var enabled_zones_mask: int = 1

var _spawn_point: SpawnPoint
var _spawn_points: Array[SpawnPoint] = []
var _next_spawn_point_index: int = 0
var _next_spawn_index: int = 0
var _timer: Timer
var _pending_spawns: Array[PackedScene] = []
var _retry_scheduled: bool = false

func _ready() -> void:
	if not is_active:
		return

	_resolve_spawn_points()
	if _spawn_points.is_empty():
		await get_tree().process_frame
		_resolve_spawn_points()

	if _spawn_points.is_empty():
		push_warning("SpawnTestRunner: Aucun SpawnPoint actif, aucun spawn ne sera lancé.")
		return

	_spawn_point = _spawn_points[0]

	if enemy_scenes.is_empty():
		push_warning("SpawnTestRunner: Aucun ennemi configuré dans 'enemy_scenes'.")
		return

	_create_timer()
	call_deferred("_spawn_enemy_deferred")

func _resolve_spawn_points() -> void:
	_spawn_points.clear()

	if enabled_zones_mask != 0:
		var candidates := get_tree().get_nodes_in_group("spawn_points")
		for node in candidates:
			var spawn_point := node as SpawnPoint
			if spawn_point == null:
				continue
			var zone_id := spawn_point.zone_id
			if zone_id <= 0:
				continue
			var zone_bit := 1 << (zone_id - 1)
			if (enabled_zones_mask & zone_bit) != 0:
				_spawn_points.append(spawn_point)

	if _spawn_points.is_empty() and not spawn_point_path.is_empty():
		var fallback := get_node_or_null(spawn_point_path)
		if fallback:
			_spawn_points.append(fallback)
		else:
			push_warning("SpawnTestRunner: Impossible de trouver le SpawnPoint à '%s'." % spawn_point_path)

	_next_spawn_point_index = 0

func _create_timer() -> void:
	_timer = Timer.new()
	_timer.wait_time = spawn_interval
	_timer.one_shot = false
	add_child(_timer)
	_timer.timeout.connect(_on_timeout)
	_timer.start()

func _on_timeout() -> void:
	call_deferred("_spawn_enemy_deferred")

func _spawn_enemy_deferred() -> void:
	var spawn_point := _select_active_spawn_point()
	if spawn_point == null:
		push_warning("SpawnTestRunner: Aucun SpawnPoint disponible pour le spawn.")
		return
	_spawn_enemy()

func _select_active_spawn_point() -> SpawnPoint:
	for i in range(_spawn_points.size() - 1, -1, -1):
		var point := _spawn_points[i]
		if point == null or not point.is_inside_tree():
			_spawn_points.remove_at(i)

	if _spawn_points.is_empty():
		_resolve_spawn_points()
		for i in range(_spawn_points.size() - 1, -1, -1):
			var refreshed := _spawn_points[i]
			if refreshed == null or not refreshed.is_inside_tree():
				_spawn_points.remove_at(i)

	if _spawn_points.is_empty():
		return null

	_next_spawn_point_index = _next_spawn_point_index % _spawn_points.size()

	var attempts := 0
	var index := _next_spawn_point_index

	while attempts < _spawn_points.size():
		var candidate: SpawnPoint = _spawn_points[index]
		index = (index + 1) % _spawn_points.size()
		attempts += 1

		if candidate != null and candidate.is_inside_tree():
			_next_spawn_point_index = index
			_spawn_point = candidate
			return candidate

	return null

func _spawn_enemy() -> void:
	if _spawn_point == null:
		return
	if not _spawn_point.is_inside_tree():
		return

	if enemy_scenes.is_empty():
		return

	var from_pending := false
	var scene: PackedScene = null

	if not _pending_spawns.is_empty():
		scene = _pending_spawns[0]
		_pending_spawns.remove_at(0)
		from_pending = true
	else:
		if enemy_scenes.is_empty():
			return
		scene = enemy_scenes[_next_spawn_index % enemy_scenes.size()]
		if scene == null:
			push_warning("SpawnTestRunner: La scène à l'index %d est invalide." % _next_spawn_index)
			_next_spawn_index = (_next_spawn_index + 1) % enemy_scenes.size()
			return

	if scene == null:
		return

	var spawn_position: Variant = _find_valid_spawn_position()
	if spawn_position == null:
		_enqueue_pending_scene(scene)
		_schedule_retry()
		return

	var enemy := scene.instantiate()
	if enemy == null:
		push_warning("SpawnTestRunner: Impossible d'instancier la scène.")
		return

	if enemy is Node3D:
		enemy.scale = Vector3.ONE * 1.4
		enemy.position = spawn_position
	else:
		push_warning("SpawnTestRunner: L'ennemi instancié n'est pas un Node3D.")
		enemy.position = spawn_position

	_add_enemy_to_scene(enemy)

	if not from_pending:
		_next_spawn_index = (_next_spawn_index + 1) % enemy_scenes.size()

func _find_valid_spawn_position() -> Variant:
	var attempts := 0
	var last_adjusted := _spawn_point.global_transform.origin
	while attempts < max_spawn_attempts:
		var candidate := _spawn_point.get_spawn_position()
		var adjusted := _adjust_spawn_to_ground(candidate)
		last_adjusted = adjusted
		if _has_clearance(adjusted):
			return adjusted
		attempts += 1
	return last_adjusted

func _add_enemy_to_scene(enemy: Node) -> void:
	var parent := _spawn_point.get_parent()
	if parent == null:
		push_warning("SpawnTestRunner: Impossible d'ajouter l'ennemi, parent introuvable.")
		return
	parent.call_deferred("add_child", enemy)

func _adjust_spawn_to_ground(position: Vector3) -> Vector3:
	if _spawn_point == null or not _spawn_point.is_inside_tree():
		return position

	var world_3d := _spawn_point.get_world_3d()
	if world_3d == null:
		return position

	var space_state := world_3d.direct_space_state
	if space_state == null:
		return position

	var from := position + Vector3.UP * floor_probe_height
	var to := position - Vector3.UP * floor_probe_max_drop
	var excluded: Array = []
	var attempts := 0
	while attempts < 8:
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		query.exclude = excluded

		var result := space_state.intersect_ray(query)
		if result.is_empty():
			break

		var hit_position: Vector3 = result.position

		if hit_position.y <= position.y + max_surface_height_above_point:
			hit_position.y += ground_offset
			return hit_position

		if result.has("rid"):
			excluded.append(result.rid)
		from = result.position - Vector3.UP * 0.01
		attempts += 1

	return position

func _has_clearance(position: Vector3) -> bool:
	if _spawn_point == null or not _spawn_point.is_inside_tree():
		return false

	var world_3d := _spawn_point.get_world_3d()
	if world_3d == null:
		return false

	var space_state := world_3d.direct_space_state
	if space_state == null:
		return false

	var top := position + Vector3.UP * clearance_half_height
	var bottom := position - Vector3.UP * clearance_half_height
	var shape := CapsuleShape3D.new()
	shape.radius = clearance_radius
	shape.height = clearance_half_height * 2.0

	var params := PhysicsShapeQueryParameters3D.new()
	params.set_shape(shape)
	params.transform = Transform3D(Basis.IDENTITY, (top + bottom) * 0.5)
	params.collide_with_areas = false
	params.collide_with_bodies = true

	var results := space_state.intersect_shape(params, 16)
	if results.is_empty():
		return true

	var floor_tolerance := 0.05

	for result in results:
		if result == null:
			continue
		if result.has("position"):
			var hit_position: Vector3 = result.position
			if hit_position.y <= bottom.y + floor_tolerance:
				continue
		return false

	return true

func _enqueue_pending_scene(scene: PackedScene) -> void:
	if scene == null:
		return
	_pending_spawns.append(scene)

func _schedule_retry() -> void:
	if _retry_scheduled or _pending_spawns.is_empty():
		return

	_retry_scheduled = true

	if retry_delay <= 0.0:
		call_deferred("_retry_pending_spawns")
	else:
		var retry_timer := get_tree().create_timer(retry_delay)
		retry_timer.timeout.connect(_retry_pending_spawns)

func _retry_pending_spawns() -> void:
	_retry_scheduled = false
	if _pending_spawns.is_empty():
		return
	_spawn_enemy()
