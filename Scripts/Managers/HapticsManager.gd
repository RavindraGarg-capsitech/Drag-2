extends Node

## HapticsManager
## PDF §4 CPU: this manager is idle by construction — it never overrides
## _process/_physics_process, so there is zero per-frame cost. It only does
## work when a controller explicitly calls one of the methods below.

func light() -> void:
	if _supports_haptics():
		Input.vibrate_handheld(20)


func medium() -> void:
	if _supports_haptics():
		Input.vibrate_handheld(40)


func heavy() -> void:
	if _supports_haptics():
		Input.vibrate_handheld(80)


func _supports_haptics() -> bool:
	return OS.get_name() in ["Android", "iOS"]
