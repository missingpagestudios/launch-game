extends Node
## Cross-run progression. Stage 2: session-only (no disk persistence).
## Stage 3+ can add save_to_disk()/load_from_disk().

var unlocked_fireworks: Array[String] = []

var total_runs_completed: int = 0
var total_fireworks_fired_all_runs: int = 0
var total_firecrackers_fired_all_runs: int = 0
var total_fans_accumulated_all_runs: int = 0

var true_endings_achieved: int = 0
var wrong_endings_achieved: int = 0
var skipped_endings: int = 0
var zone_finale_counts: Dictionary = {}  # zone -> count

var pending_unlock_notifications: Array[String] = []


func is_firework_unlocked(fw: Dictionary) -> bool:
	if not fw.get("unlockable", false):
		return true
	return unlocked_fireworks.has(String(fw.name))


func unlock_firework(fw_name: String) -> void:
	if fw_name == "":
		return
	if not unlocked_fireworks.has(fw_name):
		unlocked_fireworks.append(fw_name)
		pending_unlock_notifications.append(fw_name)


func record_run_end(ending: String, final_zone: int, total_earned: float,
		fireworks_fired: int, fans_at_end: int, firecrackers_fired: int) -> void:
	total_runs_completed += 1
	total_fireworks_fired_all_runs += fireworks_fired
	total_firecrackers_fired_all_runs += firecrackers_fired
	total_fans_accumulated_all_runs += fans_at_end
	match ending:
		"true_ending":
			true_endings_achieved += 1
		"wrong_cause":
			wrong_endings_achieved += 1
		"skipped":
			skipped_endings += 1
		_:
			zone_finale_counts[final_zone] = int(zone_finale_counts.get(final_zone, 0)) + 1
