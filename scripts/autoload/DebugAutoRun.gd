extends Node
## Smoke-test harness: drives the engine through full 100-night runs with
## simple scripted strategies. Prints outcomes to stdout so we can sanity-
## check that the port doesn't crash and produces plausible endings.
## Not a balance validator — Python sim owns that.

# strategy_name: "Mogul" | "Spectacle" | "Rush" | "Completionist" | "Cheapskate"
# cause: "asteroid" for true ending; "" to skip; other cause_id for wrong
func run_batch(strategy_name: String, count: int, cause: String = "asteroid") -> void:
	var results: Array[Dictionary] = []
	for i in count:
		var r := _run_once(strategy_name, cause)
		results.append(r)
	_print_summary(strategy_name, results)


func _run_once(strategy: String, cause: String) -> Dictionary:
	GameState.start_new_run()
	var total_nights := int(BalanceConfig.game_params().get("total_nights", 100))
	while GameState.night <= total_nights:
		if GameState.donation_phase_available and not GameState.donation_phase_decided:
			var gp := BalanceConfig.game_params()
			if cause == "":
				GameState.donation_phase_decided = true
				GameState.donation_choice = ""
				GameState.donation_phase_available = false
			elif GameState.money >= float(gp.get("donation_cost", 2_500_000_000)):
				GameState.money -= float(gp.get("donation_cost", 2_500_000_000))
				GameState.donation_choice = cause
				GameState.donation_phase_decided = true
				GameState.donation_phase_available = false
		var decisions := _script_night(strategy)
		GameEngine.resolve_night(decisions)

	var ending := GameEngine.determine_ending()
	return {
		"ending": ending,
		"final_zone": GameState.current_zone,
		"money_earned": GameState.total_money_earned,
		"repeat_fans": GameState.repeat_fans,
		"fireworks_fired": GameState.total_fireworks_fired_this_run,
	}


func _script_night(strategy: String) -> Dictionary:
	var fireworks: Dictionary = {}
	var marketing: Dictionary = {}
	var enhancements: Array = []
	var upgrades_to_buy: Array = []

	# Always hold back a small reserve so we never hit zero after a bad show.
	var reserve_ratio: float = 0.15 if strategy != "Cheapskate" else 0.05
	var budget: float = maxf(GameState.money * (1.0 - reserve_ratio), 0.0)

	# Budget split defaults
	var fireworks_budget: float = budget * 0.60
	var marketing_budget: float = budget * 0.25
	var enhancement_budget: float = budget * 0.10
	var upgrade_budget: float = budget * 0.05

	match strategy:
		"Mogul":
			fireworks_budget = budget * 0.45
			marketing_budget = budget * 0.35
			upgrade_budget = budget * 0.15
			enhancement_budget = budget * 0.05
		"Rush":
			fireworks_budget = budget * 0.35
			marketing_budget = budget * 0.50
			upgrade_budget = budget * 0.10
			enhancement_budget = budget * 0.05
		"Spectacle":
			fireworks_budget = budget * 0.70
			marketing_budget = budget * 0.10
			upgrade_budget = budget * 0.10
			enhancement_budget = budget * 0.10
		"Completionist":
			# keep the defaults
			pass
		"Cheapskate":
			fireworks_budget = budget * 0.90
			marketing_budget = 0.0
			enhancement_budget = 0.0
			upgrade_budget = 0.0

	# 1. Fireworks — pick best engagement/cost-efficiency given budget
	var fw_candidates := GameEngine.available_fireworks().duplicate()
	var zone_id := GameState.current_zone
	var prefer_tier := _preferred_tier(strategy, zone_id)
	fw_candidates = fw_candidates.filter(func(fw: Dictionary) -> bool:
		return int(fw.get("tier", 1)) <= prefer_tier)

	if not fw_candidates.is_empty():
		fw_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var ea: float = float(a.get("engagement", 1)) / maxf(float(a.get("cost", 1)), 1.0)
			var eb: float = float(b.get("engagement", 1)) / maxf(float(b.get("cost", 1)), 1.0)
			return ea > eb)
		var pick: Dictionary = fw_candidates[0]
		var pick_cost: float = float(pick.get("cost", 1))
		var qty: int = int(fireworks_budget / pick_cost)
		var cap: int = int(BalanceConfig.get_zone(zone_id).get("firework_cap", 300))
		qty = mini(qty, cap)
		qty = maxi(qty, 0)
		if qty > 0:
			fireworks[String(pick.name)] = qty

	if fireworks.is_empty():
		# Always fire at least one cheap firework so Fire Show button would be active.
		for fw in GameEngine.available_fireworks():
			var cost := float(fw.get("cost", 0))
			if cost <= GameState.money:
				fireworks[String(fw.name)] = 1
				break

	# 2. Marketing — fill cheapest first up to budget
	var mk_candidates: Array = GameEngine.available_marketing()
	for mk in mk_candidates:
		if marketing_budget <= 0:
			break
		var mk_cost: float = float(mk.get("cost", 0))
		var cap_count: int = int(mk.get("cap", 0))
		var buy: int = int(marketing_budget / maxf(mk_cost, 1.0))
		buy = mini(buy, cap_count)
		if buy > 0:
			marketing[String(mk.name)] = buy
			marketing_budget -= buy * mk_cost

	# 3. Enhancements — snap to the highest affordable tier per category
	var eh_available := GameEngine.available_enhancements()
	for category in eh_available.keys():
		var best: Dictionary = {}
		for eh in eh_available[category]:
			var c: float = float(eh.get("cost", 0))
			if c <= enhancement_budget and c <= GameState.money:
				if best.is_empty() or c > float(best.get("cost", 0)):
					best = eh
		if not best.is_empty():
			enhancements.append({"category": String(category), "name": String(best.name)})
			enhancement_budget -= float(best.get("cost", 0))

	# 4. Upgrades — buy cheapest affordable not yet owned
	for up in GameEngine.available_upgrades():
		var c: float = float(up.get("cost", 0))
		if c <= upgrade_budget and c <= GameState.money:
			upgrades_to_buy.append(String(up.name))
			upgrade_budget -= c

	return {
		"fireworks": fireworks,
		"marketing": marketing,
		"enhancements": enhancements,
		"upgrades_to_buy": upgrades_to_buy,
	}


func _preferred_tier(strategy: String, zone_id: int) -> int:
	# Spectacle chases highest tier. Rush/Mogul stay cheap. Completionist mid.
	match strategy:
		"Spectacle": return 4 if zone_id >= 5 else (3 if zone_id >= 3 else 2)
		"Rush": return 2 if zone_id >= 3 else 1
		"Mogul": return 3 if zone_id >= 4 else 2
		"Completionist": return 3 if zone_id >= 3 else 2
		"Cheapskate": return 1
	return 2


func _print_summary(strategy: String, results: Array[Dictionary]) -> void:
	var count := results.size()
	var counts := {}
	var zone_sum := 0
	var money_sum := 0.0
	for r in results:
		counts[r.ending] = int(counts.get(r.ending, 0)) + 1
		zone_sum += int(r.final_zone)
		money_sum += float(r.money_earned)
	print("=== DEBUG AUTORUN: %s ×%d ===" % [strategy, count])
	for ending in counts.keys():
		print("  %s: %d" % [ending, int(counts[ending])])
	print("  avg final zone: %.2f" % (float(zone_sum) / count))
	print("  avg total earned: $%s" % _fmt(money_sum / count))


func _fmt(n: float) -> String:
	if n >= 1_000_000_000:
		return "%.1fB" % (n / 1_000_000_000.0)
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	return "%.0f" % n
