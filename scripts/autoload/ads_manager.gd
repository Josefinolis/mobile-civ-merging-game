extends Node
## AdsManager - Handles advertisements with AdMob (Poing Studios Plugin)
##
## AD MODE (automatic detection):
## - Editor/Desktop: Always SIMULATED (no real ads)
## - Android without plugin: SIMULATED
## - Android with plugin: REAL ads (AdMob)
##
## To force simulation mode even on Android, set FORCE_SIMULATE = true

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

# AdMob App ID (configured in AndroidManifest.xml)
const ADMOB_APP_ID_ANDROID: String = "ca-app-pub-9924441769526161~3498220200"

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

# Plugin state
var is_ads_supported: bool = false
var is_initialized: bool = false

# Ad objects - dynamically loaded to avoid parse errors
var banner_ad = null
var current_interstitial = null
var current_rewarded = null

# Addon classes - loaded dynamically
var _AdView = null
var _AdSize = null
var _AdPosition = null
var _AdRequest = null
var _MobileAds = null
var _InterstitialAdLoader = null
var _InterstitialAdLoadCallback = null
var _RewardedAdLoader = null
var _RewardedAdLoadCallback = null
var _OnInitializationCompleteListener = null
var _OnUserEarnedRewardListener = null

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

func _load_addon_classes() -> bool:
	"""Load AdMob addon classes dynamically. Returns true if successful."""
	var base_path = "res://addons/admob/src/"

	_AdView = load(base_path + "api/AdView.gd")
	_AdSize = load(base_path + "api/core/AdSize.gd")
	_AdPosition = load(base_path + "api/core/AdPosition.gd")
	_AdRequest = load(base_path + "api/core/AdRequest.gd")
	_MobileAds = load(base_path + "api/MobileAds.gd")
	_InterstitialAdLoader = load(base_path + "api/InterstitialAdLoader.gd")
	_InterstitialAdLoadCallback = load(base_path + "api/listeners/InterstitialAdLoadCallback.gd")
	_RewardedAdLoader = load(base_path + "api/RewardedAdLoader.gd")
	_RewardedAdLoadCallback = load(base_path + "api/listeners/RewardedAdLoadCallback.gd")
	_OnInitializationCompleteListener = load(base_path + "api/listeners/OnInitializationCompleteListener.gd")
	_OnUserEarnedRewardListener = load(base_path + "api/listeners/OnUserEarnedRewardListener.gd")

	return _AdView != null and _MobileAds != null

func _initialize_ads() -> void:
	current_ad_mode = _determine_ad_mode()

	if current_ad_mode == AdMode.REAL:
		# Check if Poing Studios AdMob plugin is available
		if Engine.has_singleton("PoingGodotAdMob"):
			if _load_addon_classes():
				is_ads_supported = true
				_setup_admob()
				print("[ADS] Poing AdMob initialized - REAL ads enabled")
			else:
				current_ad_mode = AdMode.SIMULATED
				is_ads_supported = false
				print("[ADS] WARNING: Could not load AdMob addon classes, falling back to SIMULATED")
		else:
			# Fallback to simulated
			current_ad_mode = AdMode.SIMULATED
			is_ads_supported = false
			print("[ADS] WARNING: PoingGodotAdMob singleton not found, falling back to SIMULATED")
			print("[ADS] Make sure 'AdMob' plugin is enabled in Android export settings")
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
	# Initialize MobileAds using the addon classes
	var init_listener = _OnInitializationCompleteListener.new()
	init_listener.on_initialization_complete = _on_admob_initialized
	_MobileAds.initialize(init_listener)

func _on_admob_initialized(_status) -> void:
	is_initialized = true
	print("[ADS] AdMob SDK initialized")
	# Preload ads
	load_banner()
	load_interstitial()
	load_rewarded()

# ============= BANNER ADS =============

func load_banner() -> void:
	if ads_removed:
		return

	if current_ad_mode == AdMode.SIMULATED:
		is_banner_loaded = true
		banner_loaded.emit()
		print("[ADS] SIMULATED: Banner loaded")
		return

	if not is_ads_supported:
		return

	# Create banner ad using addon classes
	var ad_size = _AdSize.get_current_orientation_anchored_adaptive_banner_ad_size(_AdSize.FULL_WIDTH)
	if ad_size.width == 0:
		ad_size = _AdSize.BANNER

	banner_ad = _AdView.new(BANNER_AD_UNIT_ID, ad_size, _AdPosition.Values.TOP)

	# Set up callbacks
	banner_ad.ad_listener.on_ad_loaded = _on_banner_loaded
	banner_ad.ad_listener.on_ad_failed_to_load = _on_banner_failed

	# Load the ad
	var ad_request = _AdRequest.new()
	banner_ad.load_ad(ad_request)

func show_banner() -> void:
	if ads_removed:
		return

	if current_ad_mode == AdMode.SIMULATED:
		is_banner_visible = true
		print("[ADS] SIMULATED: Banner shown")
		return

	if banner_ad and is_banner_loaded:
		banner_ad.show()
		is_banner_visible = true

func hide_banner() -> void:
	if current_ad_mode == AdMode.SIMULATED:
		is_banner_visible = false
		print("[ADS] SIMULATED: Banner hidden")
		return

	if banner_ad:
		banner_ad.hide()
		is_banner_visible = false

func _on_banner_loaded() -> void:
	is_banner_loaded = true
	banner_loaded.emit()
	print("[ADS] Banner loaded")

func _on_banner_failed(error) -> void:
	is_banner_loaded = false
	var error_msg = "Error code: %d" % error.code if error else "Unknown error"
	banner_failed.emit(error_msg)
	print("[ADS] Banner failed to load: %s" % error_msg)

# ============= INTERSTITIAL ADS =============

func load_interstitial() -> void:
	if ads_removed:
		return

	if current_ad_mode == AdMode.SIMULATED:
		is_interstitial_loaded = true
		interstitial_loaded.emit()
		print("[ADS] SIMULATED: Interstitial loaded")
		return

	if not is_ads_supported:
		return

	var loader = _InterstitialAdLoader.new()
	var ad_request = _AdRequest.new()

	var callback = _InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = _on_interstitial_ad_loaded
	callback.on_ad_failed_to_load = _on_interstitial_ad_failed

	loader.load(INTERSTITIAL_AD_UNIT_ID, ad_request, callback)

func _on_interstitial_ad_loaded(ad) -> void:
	current_interstitial = ad
	is_interstitial_loaded = true
	interstitial_loaded.emit()
	print("[ADS] Interstitial loaded")

	# Set up full screen callbacks
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = _on_interstitial_closed

func _on_interstitial_ad_failed(error) -> void:
	is_interstitial_loaded = false
	var error_msg = "Error code: %d" % error.code if error else "Unknown error"
	interstitial_failed.emit(error_msg)
	print("[ADS] Interstitial failed to load: %s" % error_msg)

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

	if current_interstitial and is_interstitial_loaded:
		current_interstitial.show()
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

func _on_interstitial_closed() -> void:
	interstitial_closed.emit()
	is_interstitial_loaded = false
	current_interstitial = null
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

	if not is_ads_supported:
		return

	var loader = _RewardedAdLoader.new()
	var ad_request = _AdRequest.new()

	var callback = _RewardedAdLoadCallback.new()
	callback.on_ad_loaded = _on_rewarded_ad_loaded
	callback.on_ad_failed_to_load = _on_rewarded_ad_failed

	loader.load(REWARDED_AD_UNIT_ID, ad_request, callback)

func _on_rewarded_ad_loaded(ad) -> void:
	current_rewarded = ad
	is_rewarded_loaded = true
	rewarded_loaded.emit()
	print("[ADS] Rewarded ad loaded")

	# Set up full screen callbacks
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = _on_rewarded_closed

func _on_rewarded_ad_failed(error) -> void:
	is_rewarded_loaded = false
	var error_msg = "Error code: %d" % error.code if error else "Unknown error"
	rewarded_failed.emit(error_msg)
	print("[ADS] Rewarded ad failed to load: %s" % error_msg)

func is_rewarded_ad_ready() -> bool:
	return is_rewarded_loaded

func show_rewarded_ad() -> bool:
	"""Shows rewarded ad. Returns true if shown, false if not ready."""
	if current_ad_mode == AdMode.SIMULATED:
		print("[ADS] SIMULATED: Rewarded ad shown")
		# Simulate watching the full ad (non-blocking)
		_simulate_rewarded_complete()
		return true

	if current_rewarded and is_rewarded_loaded:
		var reward_listener = _OnUserEarnedRewardListener.new()
		reward_listener.on_user_earned_reward = _on_user_earned_reward
		current_rewarded.show(reward_listener)
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

func _on_rewarded_closed() -> void:
	rewarded_closed.emit()
	is_rewarded_loaded = false
	current_rewarded = null
	print("[ADS] Rewarded ad closed")
	# Preload next rewarded ad
	load_rewarded()

func _on_user_earned_reward(reward_item) -> void:
	print("[ADS] User earned reward: %s x%d" % [reward_item.type, reward_item.amount])
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
	if banner_ad:
		banner_ad.destroy()
		banner_ad = null
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
