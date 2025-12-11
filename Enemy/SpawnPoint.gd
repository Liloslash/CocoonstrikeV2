extends Node3D
class_name SpawnPoint

@export_range(1, 4)
var zone_id: int = 1

@export var spawn_radius: float = 3.0:
	set(value):
		spawn_radius = max(value, 0.1)
		_update_gizmo()

@export var editor_color: Color = Color(0.4, 0.8, 1.0, 0.35):
	set(value):
		editor_color = Color(value.r, value.g, value.b, 0.35)
		_update_gizmo()

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_update_gizmo()

	if Engine.is_editor_hint():
		return

	_hide_editor_gizmo()

	_rng.randomize()
	if not is_in_group("spawn_points"):
		add_to_group("spawn_points")

func _update_gizmo() -> void:
	var mesh_instance := _get_radius_mesh()
	if mesh_instance == null:
		return

	mesh_instance.scale = Vector3(spawn_radius, 0.1, spawn_radius)

	var material := mesh_instance.get_surface_override_material(0)
	if material == null:
		material = StandardMaterial3D.new()
		mesh_instance.set_surface_override_material(0, material)

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = editor_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true

func _get_radius_mesh() -> MeshInstance3D:
	var editor_only := get_node_or_null("EditorOnly")
	if editor_only == null:
		return null
	return editor_only.get_node_or_null("RadiusMesh")

func get_spawn_position() -> Vector3:
	var angle := _rng.randf_range(0.0, TAU)
	var distance := sqrt(_rng.randf()) * spawn_radius
	var offset := Vector3(cos(angle), 0.0, sin(angle)) * distance
	return global_transform.origin + offset

func _hide_editor_gizmo() -> void:
	var editor_only := get_node_or_null("EditorOnly")
	if editor_only:
		editor_only.visible = false
