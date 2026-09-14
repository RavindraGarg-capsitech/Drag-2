

extends Node

## GameBus
##
## Central event-driven communication bridge.
##
## PDF §2:
## GameService and BackendService remain separated.
## GameBus is used when systems need to communicate without
## direct node references.
##
## Controllers/managers emit signals here instead of reaching
## into another system with get_node().

# ============================================================
# FLOW / NAVIGATION
# ============================================================

signal home_requested
signal play_requested
signal level_requested(level_index: int)
signal gameplay_started(level_data: Resource)


# ============================================================
# GAMEPLAY OUTCOMES
# ============================================================

signal level_completed(level_index: int, stars: int)
signal level_failed(level_index: int)
signal level_restarted(level_index: int)


# ============================================================
# PAUSE / RESUME
# ============================================================

signal game_paused
signal game_resumed


# ============================================================
# SETTINGS
# ============================================================

signal sound_toggled(enabled: bool)
signal music_toggled(enabled: bool)
signal privacy_requested


# ============================================================
# BACKEND / ADS
# ============================================================

signal interstitial_ad_ready
signal rewarded_ad_completed(reward_id: String)
