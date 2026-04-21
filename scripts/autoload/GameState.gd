extends Node
## Per-run state. Reset via GameState.start_new_run() at the top of each run.

var night: int = 1
var current_zone: int = 1
var money: float = 0.0
var repeat_fans: int = 0
var owned_upgrades: Array[String] = []

var donation_phase_available: bool = false
var donation_phase_decided: bool = false
var donation_choice: String = ""  # "" = no choice / skipped
var donation_phase_previously_available: bool = false

var zone_6_revenue_earned: float = 0.0
var total_money_earned: float = 0.0

var total_fireworks_fired_this_run: int = 0
var fireworks_fired_by_type: Dictionary = {}  # name -> count
var max_firework_types_in_any_night: int = 0
var highest_tier_fired_this_run: int = 0

var last_night_results: Dictionary = {}
var ending_type: String = ""  # "true_ending" | "wrong_cause" | "skipped" | "zone_N_finale"

# Newspaper presented on the next interstitial — set after night resolution.
var pending_newspaper: Dictionary = {}

var run_id: String = ""


func start_new_run() -> void:
	var gp := BalanceConfig.game_params()
	night = 1
	current_zone = 1
	money = float(gp.get("starting_money", 10))
	repeat_fans = 0
	owned_upgrades = []

	donation_phase_available = false
	donation_phase_decided = false
	donation_choice = ""
	donation_phase_previously_available = false

	zone_6_revenue_earned = 0.0
	total_money_earned = 0.0

	total_fireworks_fired_this_run = 0
	fireworks_fired_by_type = {}
	max_firework_types_in_any_night = 0
	highest_tier_fired_this_run = 0

	last_night_results = {}
	ending_type = ""
	pending_newspaper = {}

	run_id = "%d-%d" % [Time.get_unix_time_from_system(), randi()]


func is_final_night() -> bool:
	return night >= int(BalanceConfig.game_params().get("total_nights", 100))
