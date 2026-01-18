extends Node
## IAPManager - Handles in-app purchases with Google Play Billing
##
## BILLING MODE (automatic detection):
## - Editor/Desktop: Always SIMULATED (fake purchases)
## - Android without plugin: SIMULATED
## - Android with plugin: REAL purchases (Google Play)
##
## To force simulation mode even on Android, set FORCE_SIMULATE = true
##
## SETUP INSTRUCTIONS:
## 1. Run ./setup_billing.sh to download the official plugin
##    (or manually from https://github.com/godot-sdk-integrations/godot-google-play-billing)
## 2. Plugin extracts to: android/plugins/GodotGooglePlayBilling/
## 3. Enable in Project Settings > Plugins > Godot Google Play Billing
## 4. Configure products in Google Play Console (see GOOGLE_PLAY_SETUP.md)

signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, reason: String)
signal products_loaded()
signal billing_connected()
signal billing_disconnected()

# Product types
enum ProductType {
	COINS,          # Consumable - Coin packs
	ENERGY,         # Consumable - Energy refills
	GEMS,           # Consumable - Premium currency (for future use)
	STARTER_PACK,   # Non-consumable - One-time starter bundle
	NO_ADS,         # Non-consumable - Remove ads (future use)
	VIP,            # Subscription - VIP benefits
}

# Google Play Billing types
enum BillingType {
	INAPP,       # One-time purchases (consumable & non-consumable)
	SUBS         # Subscriptions
}

# ============= BILLING MODE CONFIGURATION =============
# Set to true to ALWAYS use simulated purchases (even on Android with plugin)
# Useful for testing. Set to false for production builds.
const FORCE_SIMULATE: bool = false

# Billing mode (determined automatically at runtime)
enum BillingMode {
	SIMULATED,    # Fake purchases (editor, desktop, or forced)
	REAL          # Real Google Play purchases
}
var current_billing_mode: BillingMode = BillingMode.SIMULATED

# Google Play Billing client (official plugin)
# Uses BillingClient.gd from android/plugins/GodotGooglePlayBilling/
var billing_client: Node = null
var is_billing_supported: bool = false
var is_connected: bool = false

# Product definitions with Google Play product IDs
# IMPORTANT: These IDs must match exactly in Google Play Console
var products: Dictionary = {
	# Coin packs (consumable)
	"coins_tiny": {
		"name": "Coin Pouch",
		"description": "+300 coins",
		"icon": "💰",
		"type": ProductType.COINS,
		"billing_type": BillingType.INAPP,
		"consumable": true,
		"amount": 300,
		"price": "$0.49",
		"price_value": 0.49
	},
	"coins_small": {
		"name": "Coin Bag",
		"description": "+800 coins",
		"icon": "💰",
		"type": ProductType.COINS,
		"billing_type": BillingType.INAPP,
		"consumable": true,
		"amount": 800,
		"price": "$0.49",
		"price_value": 0.49,
		"bonus": "+33% value"
	},
	"coins_medium": {
		"name": "Coin Chest",
		"description": "+2,500 coins",
		"icon": "💰💰",
		"type": ProductType.COINS,
		"billing_type": BillingType.INAPP,
		"consumable": true,
		"amount": 2500,
		"price": "$0.99",
		"price_value": 0.99,
		"bonus": "+65% value",
		"popular": true
	},
	"coins_large": {
		"name": "Coin Vault",
		"description": "+6,000 coins",
		"icon": "💰💰💰",
		"type": ProductType.COINS,
		"billing_type": BillingType.INAPP,
		"consumable": true,
		"amount": 6000,
		"price": "$2.49",
		"price_value": 2.49,
		"bonus": "+100% value"
	},
	"coins_mega": {
		"name": "Coin Treasury",
		"description": "+15,000 coins",
		"icon": "🏦",
		"type": ProductType.COINS,
		"billing_type": BillingType.INAPP,
		"consumable": true,
		"amount": 15000,
		"price": "$4.99",
		"price_value": 4.99,
		"bonus": "+150% value",
		"best_value": true
	},
	# Energy packs (consumable)
	"energy_small": {
		"name": "Energy Drink",
		"description": "+15 energy",
		"icon": "⚡",
		"type": ProductType.ENERGY,
		"billing_type": BillingType.INAPP,
		"consumable": true,
		"amount": 15,
		"price": "$0.49",
		"price_value": 0.49
	},
	"energy_medium": {
		"name": "Energy Pack",
		"description": "+40 energy",
		"icon": "⚡⚡",
		"type": ProductType.ENERGY,
		"billing_type": BillingType.INAPP,
		"consumable": true,
		"amount": 40,
		"price": "$0.49",
		"price_value": 0.49,
		"bonus": "+33% value"
	},
	"energy_full": {
		"name": "Full Recharge",
		"description": "Max energy + 10 extra",
		"icon": "🔋",
		"type": ProductType.ENERGY,
		"billing_type": BillingType.INAPP,
		"consumable": true,
		"amount": -1,  # Special: fills to max + 10
		"price": "$0.49",
		"price_value": 0.49,
		"popular": true
	},
	# Special packs (non-consumable, one-time purchase)
	"starter_pack": {
		"name": "Starter Bundle",
		"description": "2,000 coins + 30 energy + x2 coins 30min",
		"icon": "🎁",
		"type": ProductType.STARTER_PACK,
		"billing_type": BillingType.INAPP,
		"consumable": false,
		"one_time": true,
		"coins": 2000,
		"energy": 30,
		"coin_boost_minutes": 30,
		"price": "$0.49",
		"price_value": 0.49,
		"best_value": true
	},
	"pro_pack": {
		"name": "Pro Bundle",
		"description": "5,000 coins + 50 energy + x2 coins 1hr",
		"icon": "🎁🎁",
		"type": ProductType.STARTER_PACK,
		"billing_type": BillingType.INAPP,
		"consumable": false,
		"one_time": true,
		"coins": 5000,
		"energy": 50,
		"coin_boost_minutes": 60,
		"price": "$1.49",
		"price_value": 1.49
	},
	# Remove ads (non-consumable, one-time purchase)
	"no_ads": {
		"name": "Remove Ads",
		"description": "Remove all banner and interstitial ads forever",
		"icon": "🚫",
		"type": ProductType.NO_ADS,
		"billing_type": BillingType.INAPP,
		"consumable": false,
		"one_time": true,
		"price": "$0.49",
		"price_value": 0.49,
		"popular": true
	},
	# VIP subscriptions
	"vip_week": {
		"name": "VIP Week",
		"description": "x1.5 coins + -30% regen, 7 days",
		"icon": "👑",
		"type": ProductType.VIP,
		"billing_type": BillingType.SUBS,
		"consumable": false,
		"duration_days": 7,
		"coin_multiplier": 1.5,
		"regen_reduction": 0.7,
		"price": "$0.99",
		"price_value": 0.99
	},
	"vip_month": {
		"name": "VIP Month",
		"description": "x2 coins + -50% regen, 30 days",
		"icon": "👑👑",
		"type": ProductType.VIP,
		"billing_type": BillingType.SUBS,
		"consumable": false,
		"duration_days": 30,
		"coin_multiplier": 2.0,
		"regen_reduction": 0.5,
		"price": "$2.49",
		"price_value": 2.49,
		"best_value": true
	},
}

# Track purchased one-time items (persisted)
var purchased_one_time: Array = []

# VIP status (persisted)
var vip_expiry: int = 0  # Unix timestamp
var vip_coin_multiplier: float = 1.0
var vip_regen_multiplier: float = 1.0

# Pending purchases (for recovery)
var pending_purchases: Dictionary = {}

func _ready() -> void:
	_initialize_billing()

func _initialize_billing() -> void:
	# Determine billing mode based on environment
	current_billing_mode = _determine_billing_mode()

	if current_billing_mode == BillingMode.REAL:
		# Real billing on Android with official plugin
		# The BillingClient class is provided by the plugin
		var BillingClientClass = load("res://android/plugins/GodotGooglePlayBilling/BillingClient.gd")
		if BillingClientClass:
			billing_client = BillingClientClass.new()
			add_child(billing_client)
			is_billing_supported = true
			_connect_billing_signals()
			billing_client.start_connection()
			print("[IAP] Google Play Billing initialized - REAL payments enabled")
		else:
			# Fallback to simulated if plugin script not found
			current_billing_mode = BillingMode.SIMULATED
			is_billing_supported = false
			print("[IAP] WARNING: BillingClient.gd not found, falling back to SIMULATED")
	else:
		# Simulated billing
		is_billing_supported = false
		print("[IAP] Running in SIMULATED mode - purchases are free/fake")
		print("[IAP] Reason: %s" % _get_simulation_reason())

func _determine_billing_mode() -> BillingMode:
	# Priority 1: Force simulate if configured
	if FORCE_SIMULATE:
		return BillingMode.SIMULATED

	# Priority 2: Always simulate in editor
	if OS.has_feature("editor"):
		return BillingMode.SIMULATED

	# Priority 3: Always simulate on desktop platforms
	if OS.has_feature("pc") or OS.has_feature("web"):
		return BillingMode.SIMULATED

	# Priority 4: On Android, check if billing plugin is available
	if OS.has_feature("android"):
		if Engine.has_singleton("GodotGooglePlayBilling"):
			return BillingMode.REAL
		else:
			return BillingMode.SIMULATED

	# Default: simulate on unknown platforms
	return BillingMode.SIMULATED

func _get_simulation_reason() -> String:
	if FORCE_SIMULATE:
		return "FORCE_SIMULATE is enabled"
	if OS.has_feature("editor"):
		return "Running in Godot Editor"
	if OS.has_feature("pc"):
		return "Running on Desktop (PC/Mac/Linux)"
	if OS.has_feature("web"):
		return "Running on Web"
	if OS.has_feature("android") and not Engine.has_singleton("GodotGooglePlayBilling"):
		return "Android without billing plugin"
	return "Unknown platform"

func is_using_real_payments() -> bool:
	"""Returns true if real Google Play payments are active"""
	return current_billing_mode == BillingMode.REAL

func get_billing_mode_string() -> String:
	"""Returns human-readable billing mode for UI/debugging"""
	if current_billing_mode == BillingMode.REAL:
		return "Real Payments (Google Play)"
	return "Simulated (Free)"

func _connect_billing_signals() -> void:
	if billing_client == null:
		return

	# Connection signals
	billing_client.connected.connect(_on_billing_connected)
	billing_client.disconnected.connect(_on_billing_disconnected)
	billing_client.connect_error.connect(_on_billing_connect_error)

	# Query signals (official plugin API)
	billing_client.query_product_details_response.connect(_on_product_details_response)
	billing_client.query_purchases_response.connect(_on_purchases_response)

	# Purchase signals
	billing_client.on_purchase_updated.connect(_on_purchase_updated)

	# Consume/Acknowledge signals
	billing_client.consume_purchase_response.connect(_on_consume_response)
	billing_client.acknowledge_purchase_response.connect(_on_acknowledge_response)

# ============= BILLING CONNECTION =============

func _on_billing_connected() -> void:
	is_connected = true
	print("[IAP] Connected to Google Play Billing")
	billing_connected.emit()
	# Query product details
	_query_product_details()
	# Check for pending purchases (recovery)
	_check_pending_purchases()

func _on_billing_disconnected() -> void:
	is_connected = false
	print("[IAP] Disconnected from Google Play Billing")
	billing_disconnected.emit()

func _on_billing_connect_error(error_code: int, error_message: String) -> void:
	is_connected = false
	print("[IAP] Billing connection error: %s (code: %d)" % [error_message, error_code])

# ============= PRODUCT QUERIES =============

func _query_product_details() -> void:
	if not is_connected or billing_client == null:
		return

	# Separate products by type
	var inapp_ids: PackedStringArray = []
	var subs_ids: PackedStringArray = []

	for product_id in products:
		var product = products[product_id]
		if product.billing_type == BillingType.SUBS:
			subs_ids.append(product_id)
		else:
			inapp_ids.append(product_id)

	# Query both types using official plugin API
	# ProductType enum: INAPP = 0, SUBS = 1
	if inapp_ids.size() > 0:
		billing_client.query_product_details(inapp_ids, 0)  # INAPP
	if subs_ids.size() > 0:
		billing_client.query_product_details(subs_ids, 1)  # SUBS

func _on_product_details_response(response: Dictionary) -> void:
	# Response format: { "status": int, "product_detail_list": Array }
	var status = response.get("status", -1)
	if status != 0:  # 0 = BillingResponseCode.OK
		print("[IAP] Product details query failed with status: %d" % status)
		return

	var product_list = response.get("product_detail_list", [])
	print("[IAP] Product details received: %d products" % product_list.size())

	# Update local product info with real prices from Google Play
	for product_detail in product_list:
		var product_id = product_detail.get("product_id", "")
		if products.has(product_id):
			# Get price from one_time_purchase_offer_details or subscription_offer_details
			var one_time = product_detail.get("one_time_purchase_offer_details", {})
			var subs_offers = product_detail.get("subscription_offer_details", [])

			if not one_time.is_empty():
				products[product_id].price = one_time.get("formatted_price", products[product_id].price)
			elif subs_offers.size() > 0:
				var pricing = subs_offers[0].get("pricing_phases", {}).get("pricing_phase_list", [])
				if pricing.size() > 0:
					products[product_id].price = pricing[0].get("formatted_price", products[product_id].price)

	products_loaded.emit()

# ============= PURCHASE FLOW =============

func purchase(product_id: String) -> bool:
	if not is_product_available(product_id):
		purchase_failed.emit(product_id, "Product not available")
		return false

	var product = products[product_id]

	# SIMULATED MODE: Free instant purchase (editor, desktop, or forced)
	if current_billing_mode == BillingMode.SIMULATED:
		print("[IAP] SIMULATED: Free purchase of %s" % product_id)
		# Simulate a short delay for UX consistency
		await get_tree().create_timer(0.3).timeout
		_grant_product_rewards(product_id, product)
		if product.get("one_time", false):
			purchased_one_time.append(product_id)
		purchase_completed.emit(product_id)
		return true

	# REAL MODE: Google Play purchase (Android with plugin)
	if not is_connected or billing_client == null:
		purchase_failed.emit(product_id, "Not connected to billing service")
		return false

	# Store as pending
	pending_purchases[product_id] = {
		"timestamp": Time.get_unix_time_from_system(),
		"product": product
	}

	# Launch purchase flow using official plugin API
	var result: Dictionary
	if product.billing_type == BillingType.SUBS:
		# For subscriptions, need base_plan_id (use product_id as default)
		result = billing_client.purchase_subscription(product_id, product_id)
	else:
		result = billing_client.purchase(product_id)

	# Check immediate result (purchase flow launched or error)
	if result.get("status", -1) != 0:
		var error_msg = "Purchase failed to launch"
		print("[IAP] %s: %s" % [error_msg, result])
		purchase_failed.emit(product_id, error_msg)
		pending_purchases.erase(product_id)
		return false

	return true

# Called when a purchase is updated (official plugin API)
func _on_purchase_updated(response: Dictionary) -> void:
	var status = response.get("status", -1)

	# Handle purchase errors
	if status != 0:  # Not OK
		var error_msg = _get_billing_error_message(status)
		print("[IAP] Purchase error: %s (code: %d)" % [error_msg, status])
		purchase_failed.emit("", error_msg)
		return

	# Process successful purchases
	var purchases = response.get("purchases", [])
	for purchase_data in purchases:
		var product_ids = purchase_data.get("products", [])
		var purchase_token = purchase_data.get("purchase_token", "")
		var purchase_state = purchase_data.get("purchase_state", 0)

		if product_ids.is_empty():
			continue

		var product_id = product_ids[0]
		print("[IAP] Purchase updated: %s (state: %d)" % [product_id, purchase_state])

		# PurchaseState: 0 = UNSPECIFIED, 1 = PURCHASED, 2 = PENDING
		if purchase_state == 1:  # PURCHASED
			_handle_successful_purchase(product_id, purchase_token)
		elif purchase_state == 2:  # PENDING
			print("[IAP] Purchase pending for: %s" % product_id)

func _handle_successful_purchase(product_id: String, purchase_token: String) -> void:
	if not products.has(product_id):
		print("[IAP] Unknown product: %s" % product_id)
		return

	var product = products[product_id]

	# Store token for this purchase (for consume/acknowledge callbacks)
	pending_purchases[product_id] = {
		"token": purchase_token,
		"product": product
	}

	# For consumable products: consume it so it can be purchased again
	if product.get("consumable", false):
		print("[IAP] Consuming product: %s" % product_id)
		billing_client.consume_purchase(purchase_token)
	else:
		# For non-consumable and subscriptions: acknowledge it
		print("[IAP] Acknowledging product: %s" % product_id)
		billing_client.acknowledge_purchase(purchase_token)

# Called when consume completes (official plugin API)
func _on_consume_response(response: Dictionary) -> void:
	var status = response.get("status", -1)
	var purchase_token = response.get("purchase_token", "")
	var product_id = _find_product_by_token(purchase_token)

	if status != 0:  # Not OK
		print("[IAP] Consume error for %s: status %d" % [product_id, status])
		purchase_failed.emit(product_id, "Failed to consume purchase")
		return

	if product_id.is_empty():
		print("[IAP] Consumed unknown purchase token")
		return

	print("[IAP] Purchase consumed: %s" % product_id)
	var product = products[product_id]

	# Grant the rewards
	_grant_product_rewards(product_id, product)

	# Clean up
	pending_purchases.erase(product_id)

	# Emit success
	purchase_completed.emit(product_id)

# Called when acknowledge completes (official plugin API)
func _on_acknowledge_response(response: Dictionary) -> void:
	var status = response.get("status", -1)
	var purchase_token = response.get("purchase_token", "")
	var product_id = _find_product_by_token(purchase_token)

	if status != 0:  # Not OK
		print("[IAP] Acknowledge error for %s: status %d" % [product_id, status])
		purchase_failed.emit(product_id, "Failed to acknowledge purchase")
		return

	if product_id.is_empty():
		print("[IAP] Acknowledged unknown purchase token")
		return

	print("[IAP] Purchase acknowledged: %s" % product_id)
	var product = products[product_id]

	# Grant the rewards
	_grant_product_rewards(product_id, product)

	# Mark as purchased (for one-time items)
	if product.get("one_time", false):
		if product_id not in purchased_one_time:
			purchased_one_time.append(product_id)

	# Clean up
	pending_purchases.erase(product_id)

	# Emit success
	purchase_completed.emit(product_id)

# Called when querying existing purchases (for recovery)
func _on_purchases_response(response: Dictionary) -> void:
	var status = response.get("status", -1)
	if status != 0:
		print("[IAP] Query purchases failed with status: %d" % status)
		return

	var purchases = response.get("purchases", [])
	print("[IAP] Found %d existing purchases to restore" % purchases.size())

	for purchase_data in purchases:
		var product_ids = purchase_data.get("products", [])
		var purchase_token = purchase_data.get("purchase_token", "")
		var purchase_state = purchase_data.get("purchase_state", 0)
		var is_acknowledged = purchase_data.get("is_acknowledged", false)

		if product_ids.is_empty():
			continue

		var product_id = product_ids[0]

		# Only process purchased (not pending) and not yet acknowledged
		if purchase_state == 1 and not is_acknowledged:
			print("[IAP] Restoring unacknowledged purchase: %s" % product_id)
			_handle_successful_purchase(product_id, purchase_token)

func _get_billing_error_message(error_code: int) -> String:
	match error_code:
		1: return "Purchase cancelled"
		2: return "Service unavailable"
		3: return "Billing unavailable"
		4: return "Item unavailable"
		5: return "Developer error"
		6: return "Error"
		7: return "Already owned"
		8: return "Item not owned"
		12: return "Network error"
		_: return "Unknown error"

func _find_product_by_token(token: String) -> String:
	for product_id in pending_purchases:
		if pending_purchases[product_id].get("token", "") == token:
			return product_id
	return ""

# ============= PENDING PURCHASE RECOVERY =============

func _check_pending_purchases() -> void:
	if not is_connected or billing_client == null:
		return

	# Query existing purchases (for recovery after app restart)
	# ProductType enum: INAPP = 0, SUBS = 1
	billing_client.query_purchases(0)  # INAPP
	billing_client.query_purchases(1)  # SUBS

# ============= REWARD GRANTING =============

func _grant_product_rewards(product_id: String, product: Dictionary) -> void:
	print("[IAP] Granting rewards for: %s" % product_id)

	match product.type:
		ProductType.COINS:
			GameManager.coins += product.amount
			print("[IAP] Added %d coins" % product.amount)

		ProductType.ENERGY:
			if product.amount == -1:
				# Full recharge + 10 extra
				GameManager.energy = GameManager.max_energy + 10
			else:
				GameManager.energy = min(GameManager.energy + product.amount, GameManager.max_energy + product.amount)
			print("[IAP] Added energy")

		ProductType.STARTER_PACK:
			GameManager.coins += product.coins
			GameManager.energy = min(GameManager.energy + product.energy, GameManager.max_energy + product.energy)
			# Activate coin boost
			if DailyRewardManager:
				DailyRewardManager.activate_coin_bonus(product.coin_boost_minutes * 60)
			print("[IAP] Starter pack applied")

		ProductType.VIP:
			_activate_vip(product.duration_days, product.coin_multiplier, product.regen_reduction)
			print("[IAP] VIP activated for %d days" % product.duration_days)

		ProductType.NO_ADS:
			# Remove all ads
			if AdsManager:
				AdsManager.remove_ads()
			print("[IAP] Ads removed permanently")

	# Save game state
	if SaveManager:
		SaveManager.save_game()

# ============= VIP MANAGEMENT =============

func _activate_vip(days: int, coin_mult: float, regen_mult: float) -> void:
	var current_time = Time.get_unix_time_from_system()
	# Extend VIP if already active, otherwise start fresh
	if vip_expiry > current_time:
		vip_expiry += days * 24 * 60 * 60
	else:
		vip_expiry = int(current_time) + days * 24 * 60 * 60

	vip_coin_multiplier = coin_mult
	vip_regen_multiplier = regen_mult

func is_vip_active() -> bool:
	return Time.get_unix_time_from_system() < vip_expiry

func get_vip_coin_multiplier() -> float:
	if is_vip_active():
		return vip_coin_multiplier
	return 1.0

func get_vip_regen_multiplier() -> float:
	if is_vip_active():
		return vip_regen_multiplier
	return 1.0

func get_vip_remaining_time() -> String:
	if not is_vip_active():
		return ""
	var remaining = vip_expiry - int(Time.get_unix_time_from_system())
	var days = remaining / (24 * 60 * 60)
	var hours = (remaining % (24 * 60 * 60)) / (60 * 60)
	if days > 0:
		return "%dd %dh" % [days, hours]
	return "%dh" % hours

# ============= PUBLIC API =============

func get_all_products() -> Dictionary:
	return products

func get_product(product_id: String) -> Dictionary:
	return products.get(product_id, {})

func is_one_time_purchased(product_id: String) -> bool:
	return product_id in purchased_one_time

func is_product_available(product_id: String) -> bool:
	if not products.has(product_id):
		return false
	var product = products[product_id]
	if product.get("one_time", false) and product_id in purchased_one_time:
		return false
	return true

func is_billing_available() -> bool:
	return is_billing_supported and is_connected

func reconnect_billing() -> void:
	if billing_client != null and not is_connected:
		billing_client.start_connection()

# ============= RESTORE PURCHASES =============

func restore_purchases() -> void:
	"""Call this to restore previous purchases (required for iOS, good practice for Android)"""
	if current_billing_mode == BillingMode.REAL and is_connected and billing_client != null:
		# ProductType enum: INAPP = 0, SUBS = 1
		billing_client.query_purchases(0)  # INAPP
		billing_client.query_purchases(1)  # SUBS
		print("[IAP] Restoring purchases from Google Play...")
	else:
		print("[IAP] SIMULATED: Restore purchases (no-op in simulation mode)")

# ============= SERIALIZATION =============

func serialize() -> Dictionary:
	return {
		"purchased_one_time": purchased_one_time,
		"vip_expiry": vip_expiry,
		"vip_coin_multiplier": vip_coin_multiplier,
		"vip_regen_multiplier": vip_regen_multiplier
	}

func deserialize(data: Dictionary) -> void:
	if data.has("purchased_one_time"):
		purchased_one_time = data.purchased_one_time
	if data.has("vip_expiry"):
		vip_expiry = data.vip_expiry
	if data.has("vip_coin_multiplier"):
		vip_coin_multiplier = data.vip_coin_multiplier
	if data.has("vip_regen_multiplier"):
		vip_regen_multiplier = data.vip_regen_multiplier
