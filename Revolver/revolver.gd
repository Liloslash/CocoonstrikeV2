extends AnimatedSprite2D

# Signal émis au moment exact du tir
signal shot_fired

@export var tween_duration := 0.12  # Durée réglable dans l'inspecteur
@onready var animation_player = $AnimationPlayer
var base_position: Vector2

func _ready():
	base_position = position
	play("Idle")
	animation_player.play("Sway_Idle")
	connect("animation_finished", Callable(self, "_on_animation_finished"))
	
	# Connexion du signal frame_changed pour détecter le moment du tir
	connect("frame_changed", Callable(self, "_on_frame_changed"))

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

# Détection du moment du tir dans l'animation
func _on_frame_changed():
	if animation == "GunShotAnim":
		# Émission du signal au moment du tir (ajustez le frame selon votre animation)
		# Par exemple, si le tir a lieu à la frame 2 ou 3 de votre animation
		if frame == 2:  # Changez cette valeur selon votre animation
			shot_fired.emit()
