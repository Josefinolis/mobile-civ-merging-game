extends Node

# Señales
signal upgrade_purchased(upgrade_id: String, new_level: int)
signal upgrade_failed(upgrade_id: String, reason: String)

# Tipos de mejoras disponibles
enum UpgradeType {
	COIN_MULTIPLIER,      # Multiplicador de generación de monedas
	ENERGY_CAPACITY,      # Aumentar máximo de energía
	ENERGY_REGEN,         # Reducir tiempo de regeneración
	SPAWN_LEVEL_CHANCE,   # Chance de spawnear edificio de nivel 2+
	OFFLINE_EARNINGS,     # Mejorar eficiencia de ganancias offline
	CRITICAL_MERGE        # Chance de saltar un nivel al hacer merge
}

# Datos de las mejoras
var upgrades_data: Dictionary = {
	"coin_multiplier": {
		"name": "Coin Boost",
		"description": "Increase coin generation",
		"icon": "💰",
		"max_level": 20,
		"base_cost": 100,
		"cost_multiplier": 1.8,
		"base_value": 1.0,
		"value_per_level": 0.15,  # +15% por nivel
		"type": UpgradeType.COIN_MULTIPLIER
	},
	"energy_capacity": {
		"name": "Energy Tank",
		"description": "Increase max energy",
		"icon": "🔋",
		"max_level": 10,
		"base_cost": 200,
		"cost_multiplier": 2.2,
		"base_value": 10,
		"value_per_level": 2,  # +2 energía máxima por nivel
		"type": UpgradeType.ENERGY_CAPACITY
	},
	"energy_regen": {
		"name": "Fast Charge",
		"description": "Faster energy regeneration",
		"icon": "⚡",
		"max_level": 15,
		"base_cost": 150,
		"cost_multiplier": 2.0,
		"base_value": 30.0,
		"value_per_level": -1.5,  # -1.5 segundos por nivel (mínimo 8 seg)
		"min_value": 8.0,
		"type": UpgradeType.ENERGY_REGEN
	},
	"spawn_level_chance": {
		"name": "Lucky Spawn",
		"description": "Chance to spawn higher level",
		"icon": "🎲",
		"max_level": 10,
		"base_cost": 500,
		"cost_multiplier": 2.5,
		"base_value": 0.0,
		"value_per_level": 0.05,  # +5% chance por nivel
		"type": UpgradeType.SPAWN_LEVEL_CHANCE
	},
	"offline_earnings": {
		"name": "Idle Income",
		"description": "Better offline earnings",
		"icon": "😴",
		"max_level": 10,
		"base_cost": 300,
		"cost_multiplier": 2.0,
		"base_value": 0.5,
		"value_per_level": 0.05,  # +5% eficiencia offline por nivel (max 100%)
		"max_value": 1.0,
		"type": UpgradeType.OFFLINE_EARNINGS
	},
	"critical_merge": {
		"name": "Super Merge",
		"description": "Chance to skip a level on merge",
		"icon": "✨",
		"max_level": 8,
		"base_cost": 1000,
		"cost_multiplier": 3.0,
		"base_value": 0.0,
		"value_per_level": 0.03,  # +3% chance por nivel
		"type": UpgradeType.CRITICAL_MERGE
	}
}

# Niveles actuales de cada mejora
var upgrade_levels: Dictionary = {}

func _ready() -> void:
	# Inicializar todos los niveles a 0
	for upgrade_id in upgrades_data.keys():
		upgrade_levels[upgrade_id] = 0

# Obtener el costo de la siguiente mejora
func get_upgrade_cost(upgrade_id: String) -> int:
	if not upgrades_data.has(upgrade_id):
		return -1

	var data: Dictionary = upgrades_data[upgrade_id]
	var current_level: int = upgrade_levels.get(upgrade_id, 0)

	if current_level >= data["max_level"]:
		return -1  # Ya está al máximo

	return int(data["base_cost"] * pow(data["cost_multiplier"], current_level))

# Obtener el valor actual de una mejora
func get_upgrade_value(upgrade_id: String) -> float:
	if not upgrades_data.has(upgrade_id):
		return 0.0

	var data: Dictionary = upgrades_data[upgrade_id]
	var current_level: int = upgrade_levels.get(upgrade_id, 0)
	var value: float = data["base_value"] + (data["value_per_level"] * current_level)

	# Aplicar límites si existen
	if data.has("min_value"):
		value = max(value, data["min_value"])
	if data.has("max_value"):
		value = min(value, data["max_value"])

	return value

# Obtener el nivel actual de una mejora
func get_upgrade_level(upgrade_id: String) -> int:
	return upgrade_levels.get(upgrade_id, 0)

# Obtener el nivel máximo de una mejora
func get_max_level(upgrade_id: String) -> int:
	if not upgrades_data.has(upgrade_id):
		return 0
	return upgrades_data[upgrade_id]["max_level"]

# Verificar si se puede comprar una mejora
func can_purchase(upgrade_id: String) -> bool:
	var cost: int = get_upgrade_cost(upgrade_id)
	if cost < 0:
		return false  # Ya está al máximo o no existe
	return GameManager.coins >= cost

# Comprar una mejora
func purchase_upgrade(upgrade_id: String) -> bool:
	if not can_purchase(upgrade_id):
		var reason: String = "Not enough coins"
		if get_upgrade_cost(upgrade_id) < 0:
			reason = "Already at max level"
		upgrade_failed.emit(upgrade_id, reason)
		return false

	var cost: int = get_upgrade_cost(upgrade_id)
	GameManager.coins -= cost
	upgrade_levels[upgrade_id] += 1

	# Aplicar efectos inmediatos si es necesario
	_apply_upgrade_effect(upgrade_id)

	upgrade_purchased.emit(upgrade_id, upgrade_levels[upgrade_id])
	AudioManager.play_level_up()

	return true

# Aplicar efectos de mejoras que afectan valores de GameManager
func _apply_upgrade_effect(upgrade_id: String) -> void:
	match upgrade_id:
		"energy_capacity":
			GameManager.max_energy = int(get_upgrade_value(upgrade_id))
			# Si la energía actual es menor que el nuevo máximo, no la cambiamos
			# pero permitimos que se regenere hasta el nuevo máximo
		"energy_regen":
			GameManager.energy_regen_time = get_upgrade_value(upgrade_id)

# Aplicar todas las mejoras al iniciar (después de cargar)
func apply_all_upgrades() -> void:
	for upgrade_id in upgrade_levels.keys():
		if upgrade_levels[upgrade_id] > 0:
			_apply_upgrade_effect(upgrade_id)

# Getters convenientes para usar en otros scripts
func get_coin_multiplier() -> float:
	return get_upgrade_value("coin_multiplier")

func get_max_energy() -> int:
	return int(get_upgrade_value("energy_capacity"))

func get_energy_regen_time() -> float:
	return get_upgrade_value("energy_regen")

func get_spawn_level_chance() -> float:
	return get_upgrade_value("spawn_level_chance")

func get_offline_earnings_multiplier() -> float:
	return get_upgrade_value("offline_earnings")

func get_critical_merge_chance() -> float:
	return get_upgrade_value("critical_merge")

# Obtener el nivel de spawn basado en la probabilidad
func roll_spawn_level() -> int:
	var chance: float = get_spawn_level_chance()
	if chance > 0 and randf() < chance:
		# 70% nivel 2, 25% nivel 3, 5% nivel 4
		var roll: float = randf()
		if roll < 0.70:
			return 2
		elif roll < 0.95:
			return 3
		else:
			return min(4, GameManager.highest_unlocked_level)
	return 1

# Verificar si ocurre un critical merge
func roll_critical_merge() -> bool:
	return randf() < get_critical_merge_chance()

# Serializar para guardado
func serialize() -> Dictionary:
	return {
		"upgrade_levels": upgrade_levels.duplicate()
	}

# Deserializar desde guardado
func deserialize(data: Dictionary) -> void:
	if data.has("upgrade_levels"):
		for upgrade_id in data["upgrade_levels"]:
			if upgrades_data.has(upgrade_id):
				upgrade_levels[upgrade_id] = data["upgrade_levels"][upgrade_id]

	# Aplicar todos los efectos después de cargar
	apply_all_upgrades()

# Obtener lista de IDs de mejoras para iterar
func get_all_upgrade_ids() -> Array:
	return upgrades_data.keys()

# Obtener datos de una mejora específica
func get_upgrade_data(upgrade_id: String) -> Dictionary:
	return upgrades_data.get(upgrade_id, {})
