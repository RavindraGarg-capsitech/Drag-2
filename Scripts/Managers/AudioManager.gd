
class_name AudioManager
extends Node

## AudioManager
##
## PDF §4:
## Idle SFX players have processing disabled.
##
## PDF §6:
## All audio playback is centralized here.
##
## Controllers must not create their own AudioStreamPlayers.


const SFX_POOL_SIZE: int = 8


var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer


var sound_enabled: bool = true
var music_enabled: bool = true


func _ready() -> void:
	_create_music_player()
	_create_sfx_pool()


func _create_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"

	add_child(_music_player)


func _create_sfx_pool() -> void:
	for index: int in range(SFX_POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()

		player.name = "SfxPlayer%d" % index
		player.bus = "SFX"

		player.process_mode = Node.PROCESS_MODE_DISABLED

		player.finished.connect(
			_on_sfx_finished.bind(player)
		)

		add_child(player)
		_sfx_pool.append(player)


func play_sfx(stream: AudioStream) -> void:
	if not sound_enabled:
		return

	if stream == null:
		return

	var player: AudioStreamPlayer = _get_free_sfx_player()

	if player == null:
		# Pool exhausted.
		# Dropping a non-critical SFX is preferable to allocating
		# another persistent AudioStreamPlayer.
		return

	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.stream = stream
	player.play()


func play_music(stream: AudioStream) -> void:
	if stream == null:
		return

	_music_player.stream = stream
	_music_player.playing = music_enabled


func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled

	if _music_player == null:
		return

	_music_player.playing = (
		enabled
		and _music_player.stream != null
	)


func _get_free_sfx_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _sfx_pool:
		if not player.playing:
			return player

	return null


func _on_sfx_finished(
	player: AudioStreamPlayer
) -> void:
	player.process_mode = Node.PROCESS_MODE_DISABLED
