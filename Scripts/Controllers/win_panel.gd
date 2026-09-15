extends UIController

var level_index: int = 1
var stars: int = 0


@export_group("Star Animation")
@export var star_start_offset: float = 300.0
@export var star_duration: float = 0.35
@export var star_delay: float = 0.12


func setup(p_level_index: int, p_stars: int) -> void:
	level_index = p_level_index
	stars = clampi(p_stars, 0, 3)

	_update_ui()
	_play_star_animation()


func _update_ui() -> void:
	# Star UI later.
	pass


func _play_star_animation() -> void:
	var all_stars: Array[Control] = [
		$BlurBg/WinPopUp/Stars/Leftstar,
		$BlurBg/WinPopUp/Stars/CenterStar,
		$BlurBg/WinPopUp/Stars/Rightstar
	]

	# --------------------------------------------------------
	# Hide/reset all stars first
	# --------------------------------------------------------

	for star in all_stars:
		star.modulate.a = 0.0
		star.scale = Vector2(0.7, 0.7)


	# --------------------------------------------------------
	# Animate only earned stars
	#
	# 3 stars = 3rd → 2nd → 1st
	# 2 stars = 2nd → 1st
	# 1 star  = 1st
	# --------------------------------------------------------

	for star_index in range(stars - 1, -1, -1):
		var star: Control = all_stars[star_index]

		var final_position := star.position

		# Start from left.
		star.position.x = final_position.x - star_start_offset

		var tween := create_tween()
		tween.set_parallel(true)

		# Move into position.
		tween.tween_property(
			star,
			"position",
			final_position,
			star_duration
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		# Fade in.
		tween.tween_property(
			star,
			"modulate:a",
			1.0,
			star_duration * 0.6
		)

		# Small pop.
		tween.tween_property(
			star,
			"scale",
			Vector2.ONE,
			star_duration
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		# Wait before next star.
		await get_tree().create_timer(star_delay).timeout


# ============================================================
# BUTTONS
# ============================================================

func _on_restart_btn_pressed() -> void:
	GameService.haptics.light()

	GameService.ui.pop_instance(self)

	GameBus.level_restarted.emit(level_index)


func _on_next_btn_pressed() -> void:
	GameService.haptics.light()

	GameService.ui.pop_instance(self)

	GameBus.level_requested.emit(level_index + 1)


func _on_home_btn_pressed() -> void:
	GameService.haptics.light()

	GameService.ui.pop_instance(self)

	GameBus.home_requested.emit()


func _on_back_btn_pressed() -> void:
	GameService.haptics.light()

	GameService.ui.pop_instance(self)

	GameBus.home_requested.emit()
