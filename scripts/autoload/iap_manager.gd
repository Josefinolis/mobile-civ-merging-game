extends Node
## IAPManager - Handles in-app purchases (micropayments)

signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, reason: String)

# Product types
enum ProductType {
	COINS,          # Coin packs
	ENERGY,         # Energy refills
	GEMS,           # Premium currency (for future use)
	STARTER_PACK,   # One-time starter bundle
	NO_ADS,         # Remove ads (future use)
	VIP,            # VIP subscription benefits
}

# Product definitions - Balanced for player value
var products: Dictionary = {
	# Coin packs - Progressive value
	"coins_tiny": {
		"name": "Coin Pouch",
		"description": "+300 coins",
		"icon": "💰",
		"type": ProductType.COINS,
		"amount": 300,
		"price": "$0.99",
		"price_value": 0.99
	},
	"coins_small": {
		"name": "Coin Bag",
		"description": "+800 coins",
		"icon": "💰",
		"type": ProductType.COINS,
		"amount": 800,
		"price": "$1.99",
		"price_value": 1.99,
		"bonus": "+33% value"
	},
	"coins_medium": {
		"name": "Coin Chest",
		"description": "+2,500 coins",
		"icon": "💰💰",
		"type": ProductType.COINS,
		"amount": 2500,
		"price": "$4.99",
		"price_value": 4.99,
		"bonus": "+65% value",
		"popular": true
	},
	"coins_large": {
		"name": "Coin Vault",
		"description": "+6,000 coins",
		"icon": "💰💰💰",
		"type": ProductType.COINS,
		"amount": 6000,
		"price": "$9.99",
		"price_value": 9.99,
		"bonus": "+100% value"
	},
	"coins_mega": {
		"name": "Coin Treasury",
		"description": "+15,000 coins",
		"icon": "🏦",
		"type": ProductType.COINS,
		"amount": 15000,
		"price": "$19.99",
		"price_value": 19.99,
		"bonus": "+150% value",
		"best_value": true
	},
	# Energy packs
	"energy_small": {
		"name": "Energy Drink",
		"description": "+15 energy",
		"icon": "⚡",
		"type": ProductType.ENERGY,
		"amount": 15,
		"price": "$0.99",
		"price_value": 0.99
	},
	"energy_medium": {
		"name": "Energy Pack",
		"description": "+40 energy",
		"icon": "⚡⚡",
		"type": ProductType.ENERGY,
		"amount": 40,
		"price": "$1.99",
		"price_value": 1.99,
		"bonus": "+33% value"
	},
	"energy_full": {
		"name": "Full Recharge",
		"description": "Max energy + 10 extra",
		"icon": "🔋",
		"type": ProductType.ENERGY,
		"amount": -1,  # Special: fills to max + 10
		"price": "$2.99",
		"price_value": 2.99,
		"popular": true
	},
	# Special packs
	"starter_pack": {
		"name": "Starter Bundle",
		"description": "2,000 coins + 30 energy + x2 coins 30min",
		"icon": "🎁",
		"type": ProductType.STARTER_PACK,
		"coins": 2000,
		"energy": 30,
		"coin_boost_minutes": 30,
		"price": "$2.99",
		"price_value": 2.99,
		"one_time": true,
		"best_value": true
	},
	"pro_pack": {
		"name": "Pro Bundle",
		"description": "5,000 coins + 50 energy + x2 coins 1hr",
		"icon": "🎁🎁",
		"type": ProductType.STARTER_PACK,
		"coins": 5000,
		"energy": 50,
		"coin_boost_minutes": 60,
		"price": "$6.99",
		"price_value": 6.99,
		"one_time": true
	},
	"vip_week": {
		"name": "VIP Week",
		"description": "x1.5 coins + -30% regen, 7 days",
		"icon": "👑",
		"type": ProductType.VIP,
		"duration_days": 7,
		"coin_multiplier": 1.5,
		"regen_reduction": 0.7,
		"price": "$3.99",
		"price_value": 3.99
	},
	"vip_month": {
		"name": "VIP Month",
		"description": "x2 coins + -50% regen, 30 days",
		"icon": "👑👑",
		"type": ProductType.VIP,
		"duration_days": 30,
		"coin_multiplier": 2.0,
		"regen_reduction": 0.5,
		"price": "$9.99",
		"price_value": 9.99,
		"best_value": true
	},
}

# Track purchased one-time items
var purchased_one_time: Array = []

# VIP status
var vip_expiry: int = 0  # Unix timestamp
var vip_coin_multiplier: float = 1.0
var vip_regen_multiplier: float = 1.0

func _ready() -> void:
	pass

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

# Simulate purchase (in a real app, this would connect to Google Play / App Store)
func purchase(product_id: String) -> bool:
	if not is_product_available(product_id):
		purchase_failed.emit(product_id, "Product not available")
		return false

	var product = products[product_id]

	# In a real implementation, this would:
	# 1. Connect to Google Play Billing / App Store
	# 2. Wait for user confirmation
	# 3. Verify the purchase on a server
	# 4. Then grant the rewards

	# For now, we'll simulate successful purchase and grant rewards immediately
	_grant_product_rewards(product_id, product)

	# Mark one-time purchases
	if product.get("one_time", false):
		purchased_one_time.append(product_id)

	purchase_completed.emit(product_id)
	return true

func _grant_product_rewards(product_id: String, product: Dictionary) -> void:
	match product.type:
		ProductType.COINS:
			GameManager.coins += product.amount

		ProductType.ENERGY:
			if product.amount == -1:
				# Full recharge + 10 extra
				GameManager.energy = GameManager.max_energy + 10
			else:
				GameManager.energy = min(GameManager.energy + product.amount, GameManager.max_energy + product.amount)

		ProductType.STARTER_PACK:
			GameManager.coins += product.coins
			GameManager.energy = min(GameManager.energy + product.energy, GameManager.max_energy + product.energy)
			# Activate coin boost
			if DailyRewardManager:
				DailyRewardManager.activate_coin_bonus(product.coin_boost_minutes * 60)

		ProductType.VIP:
			_activate_vip(product.duration_days, product.coin_multiplier, product.regen_reduction)

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

# Serialization for save/load
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
