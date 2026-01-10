extends Node
## AdsManager - Handles advertisements with AdMob
##
## AD MODE (automatic detection):
## - Editor/Desktop: Always SIMULATED (no real ads)
## - Android without plugin: SIMULATED
## - Android with plugin: REAL ads (AdMob)
##
## To force simulation mode even on Android, set FORCE_SIMULATE = true
##
## SETUP INSTRUCTIONS:
## 1. Run ./setup_ads.sh to download the official AdMob plugin
## 2. Plugin extracts to: android/plugins/GodotAdMob/
## 3. Enable in Project Settings > Plugins > Godot AdMob
## 4. Configure ad units in AdMob Console (see ADMOB_SETUP.md)

signal banner_loaded()
signal banner_failed(error: String)
signal interstitial_loaded()
signal interstitial_failed(error: String)
signal interstitial_closed()
signal rewarded_loaded()
signal rewarded_failed(error: String)
signal rewarded_earned(reward_type: String, reward_amount: int)
signal rewarded_closed()

# ============= CONFIGURATION =============
# Set to true to ALWAYS use simulated ads (even on Android with plugin)
const FORCE_SIMULATE: bool = false

# AdMob App ID (production)
const ADMOB_APP_ID_ANDROID: String = "ca-app-pub-9924441769526161~3498220200"
const ADMOB_APP_ID_IOS: String = "ca-app-pub-3940256099942544~1458002511"  # Test ID (no iOS yet)

# Ad Unit IDs (production)
const BANNER_AD_UNIT_ID: String = "ca-app-pub-9924441769526161/4001439626"
const INTERSTITIAL_AD_UNIT_ID: String = "ca-app-pub-9924441769526161/6601868023"
const REWARDED_AD_UNIT_ID: String = "ca-app-pub-9924441769526161/6823221699"

# Reward configuration
const REWARDED_ENERGY_AMOUNT: int = 10  # Energy given for watching a rewarded ad

# Ad mode
enum AdMode {
	SIMULATED,    # Fake ads (editor, desktop, or forced)
	REAL          # Real AdMob ads
}
var current_ad_mode: AdMode = AdMode.SIMULATED

# AdMob plugin reference
var admob_plugin = null
var is_ads_supported: bool = false

# Ad states
var is_banner_loaded: bool = false
var is_banner_visible: bool = false
var is_interstitial_loaded: bool = false
var is_rewarded_loaded: bool = false

# No ads purchased (synced with IAPManager)
var ads_removed: bool = false

# Cooldowns and limits
var interstitial_cooldown: float = 0.0
const INTERSTITIAL_COOLDOWN_SECONDS: float = 60.0  # Min time between interstitials
var games_since_last_interstitial: int = 0
const GAMES_BETWEEN_INTERSTITIALS: int = 3  # Show interstitial every N games/actions

func _ready() -> void:
	_initialize_ads()
	# Check if ads were removed via IAP
	_check_ads_removed_status()

func _process(delta: float) -> void:
	if interstitial_cooldown > 0:
		interstitial_cooldown -= delta

func _initialize_ads() -> void:
	current_ad_mode = _determine_ad_mode()

	if current_ad_mode == AdMode.REAL:
		# Try to load AdMob plugin
		if Engine.has_singleton("AdMob"):
			admob_plugin = Engine.get_singleton("AdMob")
			is_ads_supported = true
			_setup_admob()
			print("[ADS] AdMob initialized - REAL ads enabled")
		else:
			# Fallback to simulated
			current_ad_mode = AdMode.SIMULATED
			is_ads_supported = false
			print("[ADS] WARNING: AdMob singleton not found, falling back to SIMULATED")
	else:
		is_ads_supported = false
		print("[ADS] Running in SIMULATED mode - no real ads")
		print("[ADS] Reason: %s" % _get_simulation_reason())

func _determine_ad_mode() -> AdMode:
	if FORCE_SIMULATE:
		return AdMode.SIMULATED
	if OS.has_feature("editor"):
		return AdMode.SIMULATED
	if OS.has_feature("pc") or OS.has_feature("web"):
		return AdMode.SIMULATED
	if OS.has_feature("android") or OS.has_feature("ios"):
		return AdMode.REAL
	return AdMode.SIMULATED

func _get_simulation_reason() -> String:
	if FORCE_SIMULATE:
		return "FORCE_SIMULATE is enabled"
	if OS.has_feature("editor"):
		return "Running in Godot Editor"
	if OS.has_feature("pc"):
		return "Running on Desktop"
	if OS.has_feature("web"):
		return "Running on Web"
	return "Unknown platform"

func _setup_admob() -> void:
	if admob_plugin == null:
		return

	# Initialize AdMob
	var app_id = ADMOB_APP_ID_ANDROID
	if OS.has_feature("ios"):
		app_id = ADMOB_APP_ID_IOS

	# Configure and initialize
	admob_plugin.initialize()

	# Connect signals
	_connect_admob_signals()

	# Preload ads
	load_banner()
	load_interstitial()
	load_rewarded()

func _connect_admob_signals() -> void:
	if admob_plugin == null:
		return

	# Banner signals
	if admob_plugin.has_signal("banner_loaded"):
		admob_plugin.banner_loaded.connect(_on_banner_loaded)
	if admob_plugin.has_signal("banner_failed_to_load"):
		admob_plugin.banner_failed_to_load.connect(_on_banner_failed)

	# Interstitial signals
	if admob_plugin.has_signal("interstitial_loaded"):
		admob_plugin.interstitial_loaded.connect(_on_interstitial_loaded)
	if admob_plugin.has_signal("interstitial_failed_to_load"):
		admob_plugin.interstitial_failed_to_load.connect(_on_interstitial_failed)
	if admob_plugin.has_signal("interstitial_closed"):
		admob_plugin.interstitial_closed.connect(_on_interstitial_closed)

	# Rewarded signals
	if admob_plugin.has_signal("rewarded_ad_loaded"):
		admob_plugin.rewarded_ad_loaded.connect(_on_rewarded_loaded)
	if admob_plugin.has_signal("rewarded_ad_failed_to_load"):
		admob_plugin.rewarded_ad_failed_to_load.connect(_on_rewarded_failed)
	if admob_plugin.has_signal("rewarded_ad_closed"):
		admob_plugin.rewarded_ad_closed.connect(_on_rewarded_closed)
	if admob_plugin.has_signal("user_earned_reward"):
		admob_plugin.user_earned_reward.connect(_on_user_earned_reward)

# ============= BANNER ADS =============

func load_banner() -> void:
	if ads_removed:
		return

	if current_ad_mode == AdMode.SIMULATED:
		is_banner_loaded = true
		banner_loaded.emit()
		print("[ADS] SIMULATED: Banner loaded")
		return

	if admob_plugin:
		admob_plugin.load_banner(BANNER_AD_UNIT_ID, "BOTTOM", "ADAPTIVE_BANNER")

func show_banner() -> void:
	if ads_removed:
		return

	if current_ad_mode == AdMode.SIMULATED:
		is_banner_visible = true
		print("[ADS] SIMULATED: Banner shown")
		return

	if admob_plugin and is_banner_loaded:
		admob_plugin.show_banner()
		is_banner_visible = true

func hide_banner() -> void:
	if current_ad_mode == AdMode.SIMULATED:
		is_banner_visible = false
		print("[ADS] SIMULATED: Banner hidden")
		return

	if admob_plugin:
		admob_plugin.hide_banner()
		is_banner_visible = false

func _on_banner_loaded() -> void:
	is_banner_loaded = true
	banner_loaded.emit()
	print("[ADS] Banner loaded")

func _on_banner_failed(error_code: int) -> void:
	is_banner_loaded = false
	banner_failed.emit("Error code: %d" % error_code)
	print("[ADS] Banner failed to load: %d" % error_code)

# ============= INTERSTITIAL ADS =============

func load_interstitial() -> void:
	if ads_removed:
		return

	if current_ad_mode == AdMode.SIMULATED:
		is_interstitial_loaded = true
		interstitial_loaded.emit()
		print("[ADS] SIMULATED: Interstitial loaded")
		return

	if admob_plugin:
		admob_plugin.load_interstitial(INTERSTITIAL_AD_UNIT_ID)

func show_interstitial() -> bool:
	"""Shows interstitial ad. Returns true if shown, false if not ready or on cooldown."""
	if ads_removed:
		return false

	# Check cooldown
	if interstitial_cooldown > 0:
		print("[ADS] Interstitial on cooldown: %.1f seconds remaining" % interstitial_cooldown)
		return false

	if current_ad_mode == AdMode.SIMULATED:
		print("[ADS] SIMULATED: Interstitial shown")
		interstitial_cooldown = INTERSTITIAL_COOLDOWN_SECONDS
		# Simulate close after a short delay (non-blocking)
		_simulate_interstitial_close()
		return true

	if admob_plugin and is_interstitial_loaded:
		admob_plugin.show_interstitial()
		interstitial_cooldown = INTERSTITIAL_COOLDOWN_SECONDS
		return true

	return false

func _simulate_interstitial_close() -> void:
	"""Helper to simulate interstitial close without blocking."""
	await get_tree().create_timer(0.5).timeout
	interstitial_closed.emit()
	is_interstitial_loaded = false
	load_interstitial()  # Preload next

func try_show_interstitial_after_game() -> void:
	"""Call this after completing a game/merge/action to potentially show interstitial."""
	if ads_removed:
		return

	games_since_last_interstitial += 1
	if games_since_last_interstitial >= GAMES_BETWEEN_INTERSTITIALS:
		if show_interstitial():
			games_since_last_interstitial = 0

func _on_interstitial_loaded() -> void:
	is_interstitial_loaded = true
	interstitial_loaded.emit()
	print("[ADS] Interstitial loaded")

func _on_interstitial_failed(error_code: int) -> void:
	is_interstitial_loaded = false
	interstitial_failed.emit("Error code: %d" % error_code)
	print("[ADS] Interstitial failed to load: %d" % error_code)

func _on_interstitial_closed() -> void:
	interstitial_closed.emit()
	is_interstitial_loaded = false
	print("[ADS] Interstitial closed")
	# Preload next interstitial
	load_interstitial()

# ============= REWARDED ADS =============

func load_rewarded() -> void:
	if current_ad_mode == AdMode.SIMULATED:
		is_rewarded_loaded = true
		rewarded_loaded.emit()
		print("[ADS] SIMULATED: Rewarded ad loaded")
		return

	if admob_plugin:
		admob_plugin.load_rewarded_ad(REWARDED_AD_UNIT_ID)

func is_rewarded_ad_ready() -> bool:
	return is_rewarded_loaded

func show_rewarded_ad() -> bool:
	"""Shows rewarded ad. Returns true if shown, false if not ready."""
	if current_ad_mode == AdMode.SIMULATED:
		print("[ADS] SIMULATED: Rewarded ad shown")
		# Simulate watching the full ad (non-blocking)
		_simulate_rewarded_complete()
		return true

	if admob_plugin and is_rewarded_loaded:
		admob_plugin.show_rewarded_ad()
		return true

	print("[ADS] Rewarded ad not ready")
	return false

func _simulate_rewarded_complete() -> void:
	"""Helper to simulate rewarded ad completion without blocking."""
	await get_tree().create_timer(1.0).timeout
	_grant_reward("energy", REWARDED_ENERGY_AMOUNT)
	rewarded_earned.emit("energy", REWARDED_ENERGY_AMOUNT)
	rewarded_closed.emit()
	is_rewarded_loaded = false
	load_rewarded()  # Preload next

func _on_rewarded_loaded() -> void:
	is_rewarded_loaded = true
	rewarded_loaded.emit()
	print("[ADS] Rewarded ad loaded")

func _on_rewarded_failed(error_code: int) -> void:
	is_rewarded_loaded = false
	rewarded_failed.emit("Error code: %d" % error_code)
	print("[ADS] Rewarded ad failed to load: %d" % error_code)

func _on_rewarded_closed() -> void:
	rewarded_closed.emit()
	is_rewarded_loaded = false
	print("[ADS] Rewarded ad closed")
	# Preload next rewarded ad
	load_rewarded()

func _on_user_earned_reward(reward_type: String, reward_amount: int) -> void:
	print("[ADS] User earned reward: %s x%d" % [reward_type, reward_amount])
	_grant_reward("energy", REWARDED_ENERGY_AMOUNT)
	rewarded_earned.emit("energy", REWARDED_ENERGY_AMOUNT)

func _grant_reward(_reward_type: String, amount: int) -> void:
	# Grant energy reward
	if GameManager:
		GameManager.energy = min(GameManager.energy + amount, GameManager.max_energy + amount)
		print("[ADS] Granted %d energy" % amount)
	if SaveManager:
		SaveManager.save_game()

# ============= NO ADS PURCHASE =============

func _check_ads_removed_status() -> void:
	# Check if user purchased "no_ads" via IAPManager
	if IAPManager and IAPManager.is_one_time_purchased("no_ads"):
		remove_ads()

func remove_ads() -> void:
	"""Called when user purchases 'no_ads' product."""
	ads_removed = true
	hide_banner()
	print("[ADS] Ads have been removed")

func are_ads_removed() -> bool:
	return ads_removed

# ============= PUBLIC API =============

func is_using_real_ads() -> bool:
	return current_ad_mode == AdMode.REAL

func get_ad_mode_string() -> String:
	if current_ad_mode == AdMode.REAL:
		return "Real Ads (AdMob)"
	return "Simulated (No Ads)"

func get_rewarded_energy_amount() -> int:
	return REWARDED_ENERGY_AMOUNT

# ============= SERIALIZATION =============

func serialize() -> Dictionary:
	return {
		"ads_removed": ads_removed
	}

func deserialize(data: Dictionary) -> void:
	if data.has("ads_removed"):
		ads_removed = data.ads_removed
		if ads_removed:
			hide_banner()
