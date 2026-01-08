extends Node

# Señales
signal reward_available()
signal reward_claimed(day: int, rewards: Dictionary)
signal streak_reset()

# Constantes
const SECONDS_IN_DAY: int = 86400  # 24 * 60 * 60
const MAX_STREAK_DAYS: int = 7     # Ciclo de 7 días que se repite
const STREAK_GRACE_HOURS: int = 48  # Horas de gracia antes de resetear streak

# Estado
var current_streak: int = 0
var last_claim_timestamp: float = 0.0
var can_claim_today: bool = false

# Definición de recompensas por día (ciclo de 7 días)
var daily_rewards: Array = [
	# Día 1
	{
		"coins": 50,
		"energy": 2,
		"description": "Welcome back!"
	},
	# Día 2
	{
		"coins": 100,
		"energy": 3,
		"description": "Day 2 bonus!"
	},
	# Día 3
	{
		"coins": 150,
		"energy": 3,
		"description": "Keep it up!"
	},
	# Día 4
	{
		"coins": 250,
		"energy": 4,
		"description": "Halfway there!"
	},
	# Día 5
	{
		"coins": 400,
		"energy": 5,
		"description": "Almost there!"
	},
	# Día 6
	{
		"coins": 600,
		"energy": 6,
		"description": "One more day!"
	},
	# Día 7 (Gran premio)
	{
		"coins": 1000,
		"energy": 10,
		"bonus_multiplier": 2.0,  # 2x monedas durante 5 minutos
		"bonus_duration": 300,
		"description": "JACKPOT! Full week!"
	}
]

func _ready() -> void:
	# La verificación de disponibilidad se hace después de cargar el save
	pass

# Llamar después de cargar el save
func check_reward_availability() -> void:
	var current_time: float = Time.get_unix_time_from_system()

	if last_claim_timestamp == 0.0:
		# Primera vez jugando - puede reclamar
		can_claim_today = true
		current_streak = 0
		reward_available.emit()
		return

	var time_since_claim: float = current_time - last_claim_timestamp
	var days_since_claim: int = int(time_since_claim / SECONDS_IN_DAY)

	if days_since_claim == 0:
		# Ya reclamó hoy
		can_claim_today = false
	elif days_since_claim == 1:
		# Exactamente un día después - mantiene streak
		can_claim_today = true
		reward_available.emit()
	elif days_since_claim <= (STREAK_GRACE_HOURS / 24.0):
		# Dentro del periodo de gracia - mantiene streak
		can_claim_today = true
		reward_available.emit()
	else:
		# Demasiado tiempo - resetear streak
		current_streak = 0
		can_claim_today = true
		streak_reset.emit()
		reward_available.emit()

# Obtener el día actual del streak (0-6)
func get_current_day() -> int:
	return current_streak % MAX_STREAK_DAYS

# Obtener las recompensas del día actual
func get_today_rewards() -> Dictionary:
	return daily_rewards[get_current_day()].duplicate()

# Obtener las recompensas de un día específico
func get_day_rewards(day: int) -> Dictionary:
	if day >= 0 and day < daily_rewards.size():
		return daily_rewards[day].duplicate()
	return {}

# Reclamar la recompensa diaria
func claim_reward() -> Dictionary:
	if not can_claim_today:
		return {}

	var day: int = get_current_day()
	var rewards: Dictionary = get_today_rewards()

	# Aplicar recompensas
	if rewards.has("coins"):
		GameManager.coins += rewards["coins"]

	if rewards.has("energy"):
		GameManager.energy = min(GameManager.energy + rewards["energy"], GameManager.max_energy)

	# Bonus especial del día 7
	if rewards.has("bonus_multiplier"):
		_activate_coin_bonus(rewards["bonus_multiplier"], rewards["bonus_duration"])

	# Actualizar estado
	current_streak += 1
	last_claim_timestamp = Time.get_unix_time_from_system()
	can_claim_today = false

	# Reproducir sonido
	AudioManager.play_quest_complete()

	reward_claimed.emit(day, rewards)

	return rewards

# Variables para el bonus temporal de monedas
var _coin_bonus_active: bool = false
var _coin_bonus_multiplier: float = 1.0
var _coin_bonus_timer: float = 0.0

func _process(delta: float) -> void:
	if _coin_bonus_active:
		_coin_bonus_timer -= delta
		if _coin_bonus_timer <= 0:
			_coin_bonus_active = false
			_coin_bonus_multiplier = 1.0

func _activate_coin_bonus(multiplier: float, duration: float) -> void:
	_coin_bonus_active = true
	_coin_bonus_multiplier = multiplier
	_coin_bonus_timer = duration

# Public version for external use (like IAP)
func activate_coin_bonus(duration: float, multiplier: float = 2.0) -> void:
	_activate_coin_bonus(multiplier, duration)

func get_active_coin_bonus() -> float:
	if _coin_bonus_active:
		return _coin_bonus_multiplier
	return 1.0

func is_bonus_active() -> bool:
	return _coin_bonus_active

func get_bonus_time_remaining() -> float:
	return _coin_bonus_timer if _coin_bonus_active else 0.0

# Obtener tiempo restante hasta la próxima recompensa (en segundos)
func get_time_until_next_reward() -> float:
	if can_claim_today:
		return 0.0

	var current_time: float = Time.get_unix_time_from_system()
	var time_since_claim: float = current_time - last_claim_timestamp
	var time_remaining: float = SECONDS_IN_DAY - time_since_claim

	return max(0.0, time_remaining)

# Formatear tiempo restante como string
func get_time_until_next_reward_string() -> String:
	var seconds: float = get_time_until_next_reward()
	if seconds <= 0:
		return "Ready!"

	var hours: int = int(seconds / 3600)
	var minutes: int = int((seconds - hours * 3600) / 60)

	if hours > 0:
		return "%dh %dm" % [hours, minutes]
	else:
		return "%dm" % [minutes]

# Serializar para guardado
func serialize() -> Dictionary:
	return {
		"current_streak": current_streak,
		"last_claim_timestamp": last_claim_timestamp,
		"coin_bonus_active": _coin_bonus_active,
		"coin_bonus_multiplier": _coin_bonus_multiplier,
		"coin_bonus_timer": _coin_bonus_timer
	}

# Deserializar desde guardado
func deserialize(data: Dictionary) -> void:
	if data.has("current_streak"):
		current_streak = data["current_streak"]
	if data.has("last_claim_timestamp"):
		last_claim_timestamp = data["last_claim_timestamp"]
	if data.has("coin_bonus_active"):
		_coin_bonus_active = data["coin_bonus_active"]
	if data.has("coin_bonus_multiplier"):
		_coin_bonus_multiplier = data["coin_bonus_multiplier"]
	if data.has("coin_bonus_timer"):
		_coin_bonus_timer = data["coin_bonus_timer"]

	# Verificar disponibilidad después de cargar
	check_reward_availability()

# Obtener el número total de días reclamados
func get_total_days_claimed() -> int:
	return current_streak

# Verificar si hay recompensa disponible
func is_reward_available() -> bool:
	return can_claim_today
