extends Node

## GameService
## PDF §2 Project Architecture: THE core connection point for all game
## logic. Sub-managers are instantiated directly here in _ready() and
## exposed as properties. Controllers never get_node() a manager directly —
## they read it off GameService (dependency injection, PDF §6), e.g.:
##
##     GameService.sound.play_sfx(my_stream)
##     GameService.ui.push_packed(GameConfig.PAUSE_PANEL_SCENE)
##
## Only GameService and BackendService are registered as autoloads in
## Project Settings. Everything below is a plain Node owned by this one.


const AudioManagerScript := preload("res://Scripts/Managers/AudioManager.gd")
const HapticsManagerScript := preload("res://Scripts/Managers/HapticsManager.gd")
const SaveManagerScript := preload("res://Scripts/Managers/SaveManager.gd")
const SceneManagerScript := preload("res://Scripts/Managers/SceneManager.gd")
const UIManagerScript := preload("res://Scripts/Managers/UIManager.gd")
const PlatformUtilsScript := preload("res://Scripts/utils( reusable)/PlatformUtils.gd")

var sound: Node        # AudioManager
var haptics: Node      # HapticsManager
var save: Node         # SaveManager
var scenes: Node       # SceneManager
var ui: CanvasLayer    # UIManager (also a Node, but drawn as a layer)
var platform: Node     # PlatformUtils


func _ready() -> void:
	push_error("GameService", "Booting sub-managers")

	sound = _instantiate(AudioManagerScript, "AudioManager")
	haptics = _instantiate(HapticsManagerScript, "HapticsManager")
	save = _instantiate(SaveManagerScript, "SaveManager")
	scenes = _instantiate(SceneManagerScript, "SceneManager")
	platform = _instantiate(PlatformUtilsScript, "PlatformUtils")

	ui = UIManagerScript.new()
	ui.name = "UIManager"
	ui.layer = 100  # always render above gameplay/menu canvases
	add_child(ui)

	_apply_saved_settings()
	push_error("GameService", "Ready")


func _instantiate(script: Script, node_name: String) -> Node:
	var node: Node = Node.new()
	node.set_script(script)
	node.name = node_name
	add_child(node)
	return node


func _apply_saved_settings() -> void:
	var sound_enabled: bool = save.get_value(GameConfig.SAVE_KEY_SOUND_ENABLED, true)
	var music_enabled: bool = save.get_value(GameConfig.SAVE_KEY_MUSIC_ENABLED, true)
	sound.set_sound_enabled(sound_enabled)
	sound.set_music_enabled(music_enabled)
