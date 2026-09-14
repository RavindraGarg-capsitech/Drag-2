extends Node

## GameConfig
## Central configuration for shared scene/data paths and save keys.

# --- Scenes: gameplay / big scenes ---
const GAMEPLAY_SCENE: String = "res://Scenes/gameplay/GamePlay.tscn"
const MENU_CANVAS_SCENE: String = "res://Scenes/home/MenuCanvas.tscn"

# --- Scenes: small on-demand UI panels ---
const PAUSE_PANEL_SCENE: String = "res://Scenes/gameplay/Pause_panel.tscn"
const WIN_PANEL_SCENE: String = "res://Scenes/gameplay/Win_panel.tscn"
const SETTINGS_PANEL_SCENE: String = "res://Scenes/home/setting_panel.tscn"
const LEVEL_SELECT_SCENE: String = "res://Scenes/home/level_select_menu.tscn"
const LEVEL_BUTTON_SCENE: String = "res://Scenes/UI/button/LevelBtn.tscn"

# --- Level data ---
const LEVELS_PATH: String = "res://Resources/Levels/"
const LEVEL_FILE_FORMAT: String = "res://Resources/Levels/Level%s.res"

# --- Save keys ---
const SAVE_KEY_SOUND_ENABLED: String = "sound_enabled"
const SAVE_KEY_MUSIC_ENABLED: String = "music_enabled"
const SAVE_KEY_LAST_LEVEL: String = "last_level"
