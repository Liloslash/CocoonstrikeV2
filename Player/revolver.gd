extends AnimatedSprite2D

@export var tween_duration := 0.12  # Durée réglable dans l'inspecteur
@onready var animation_player = $AnimationPlayer
var base_position: Vector2

func _ready():
	base_position = position
	play("Idle")
	animation_player.play("Sway_Idle")
	connect("animation_finished", Callable(self, "_on_animation_finished"))

func play_shot_animation():
	animation_player.stop()
	var tween = create_tween()
	tween.tween_property(self, "position", base_position, tween_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	play("GunShotAnim")

func _on_animation_finished():
	if animation == "GunShotAnim":
		play("Idle")
		animation_player.play("Sway_Idle")
