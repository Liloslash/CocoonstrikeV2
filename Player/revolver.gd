extends AnimatedSprite2D

@onready var animation_player = $AnimationPlayer
var base_position: Vector2

func _ready():
	base_position = position # Mémorise la position d'origine
	play("Idle")
	animation_player.play("Sway_Idle")
	connect("animation_finished", Callable(self, "_on_animation_finished"))

func play_shot_animation():
	animation_player.stop() # Stoppe le balancement
	position = base_position # Remet la position d'origine
	play("GunShotAnim")

func _on_animation_finished():
	if animation == "GunShotAnim":
		play("Idle")
		animation_player.play("Sway_Idle")
