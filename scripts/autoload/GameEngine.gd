extends Node
## Economy engine. Ported from ~/projects/fireworks-sim/engine.py.
## Calculation rules sourced from docs/BALANCE_FINAL.md + docs/STAGE2_BRIEF.md.
## All numeric parameters come from BalanceConfig — never hardcode here.

# decisions dictionary shape:
#   {
#     "fireworks": {name: quantity, ...},
#     "marketing": {name: quantity, ...},
#     "enhancements": [{"category": "snacks", "name": "Vending Machines"}, ...],
#     "upgrades_to_buy": [name, ...]
#   }
func resolve_night(decisions: Dictionary) -> Dictionary:
	var zone := BalanceConfig.get_zone(GameState.current_zone)
	var gp := BalanceConfig.game_params()

	var fireworks_decisions: Dictionary = decisions.get("fireworks", {})
	var marketing_decisions: Dictionary = decisions.get("marketing", {})
	var enhancement_picks: Array = decisions.get("enhancements", [])
	var upgrade_buys: Array = decisions.get("upgrades_to_buy", [])

	# 1. Spend
	var fireworks_spend := 0.0
	for fw_name in fireworks_decisions.keys():
		var count := int(fireworks_decisions[fw_name])
		if count <= 0:
			continue
		fireworks_spend += float(BalanceConfig.get_firework(fw_name).get("cost", 0)) * count
	var marketing_spend := 0.0
	for mk_name in marketing_decisions.keys():
		var count := int(marketing_decisions[mk_name])
		if count <= 0:
			continue
		marketing_spend += float(BalanceConfig.get_marketing(mk_name).get("cost", 0)) * count
	var enhancement_spend := 0.0
	for pick in enhancement_picks:
		var eh := BalanceConfig.get_enhancement(pick.category, pick.name)
		enhancement_spend += float(eh.get("cost", 0))
	var upgrade_spend := 0.0
	for up_name in upgrade_buys:
		upgrade_spend += float(BalanceConfig.get_upgrade(up_name).get("cost", 0))

	var total_spend := fireworks_spend + marketing_spend + enhancement_spend + upgrade_spend
	GameState.money -= total_spend
	for up_name in upgrade_buys:
		if not GameState.owned_upgrades.has(String(up_name)):
			GameState.owned_upgrades.append(String(up_name))

	# 2. Attendees
	var walkup_base: int = randi_range(int(zone.walkup_min), int(zone.walkup_max))
	var walkup_factor: float = randf_range(
			float(gp.get("walkup_random_factor_min", 0.8)),
			float(gp.get("walkup_random_factor_max", 1.2)))
	var walkup: int = int(float(walkup_base) * walkup_factor)

	var marketing_attendees := 0
	for mk_name in marketing_decisions.keys():
		var count := int(marketing_decisions[mk_name])
		if count <= 0:
			continue
		var mk := BalanceConfig.get_marketing(mk_name)
		marketing_attendees += int(mk.get("attendees", 0)) * count

	var permanent_attendees := 0
	for up_name in GameState.owned_upgrades:
		var up := BalanceConfig.get_upgrade(up_name)
		var effect: Dictionary = up.get("effect", {})
		permanent_attendees += int(effect.get("attendees_permanent", 0))

	var walkup_total := walkup + marketing_attendees + permanent_attendees
	var repeat_attendees := GameState.repeat_fans
	var cap := int(zone.get("attendee_cap", 1_000_000_000))
	var total_attendees := walkup_total + repeat_attendees
	if total_attendees > cap:
		var headroom: int = maxi(cap - repeat_attendees, 0)
		if walkup_total > headroom:
			walkup_total = headroom
		total_attendees = walkup_total + repeat_attendees

	# 3. Engagement
	var base_engagement := 0.0
	var firework_types_this_night := 0
	var tier_quantity := {1: 0, 2: 0, 3: 0, 4: 0}
	for fw_name in fireworks_decisions.keys():
		var count := int(fireworks_decisions[fw_name])
		if count <= 0:
			continue
		firework_types_this_night += 1
		var fw := BalanceConfig.get_firework(fw_name)
		base_engagement += float(fw.get("engagement", 0)) * count
		var t := int(fw.get("tier", 1))
		tier_quantity[t] = int(tier_quantity.get(t, 0)) + count

	var eng_mult_from_enhancements := 0.0
	var tip_mult_from_snacks := 0.0
	for pick in enhancement_picks:
		var eh := BalanceConfig.get_enhancement(pick.category, pick.name)
		eng_mult_from_enhancements += float(eh.get("eng_mult", 0.0))
		tip_mult_from_snacks += float(eh.get("tip_mult", 0.0))

	var eng_mult_permanent := 0.0
	var tip_mult_permanent := 0.0
	var show_quality_mult_permanent := 0.0
	for up_name in GameState.owned_upgrades:
		var effect: Dictionary = BalanceConfig.get_upgrade(up_name).get("effect", {})
		eng_mult_permanent += float(effect.get("eng_mult_permanent", 0.0))
		tip_mult_permanent += float(effect.get("tip_mult_permanent", 0.0))
		show_quality_mult_permanent += float(effect.get("show_quality_mult", 0.0))

	var synergies_hit := _check_synergies(fireworks_decisions, tier_quantity)
	var synergy_bonus := 0.0
	for syn in synergies_hit:
		synergy_bonus += float(syn.get("bonus", 0.0))

	var engagement := base_engagement
	engagement *= 1.0 + eng_mult_from_enhancements
	engagement *= 1.0 + eng_mult_permanent
	engagement *= 1.0 + synergy_bonus
	engagement *= 1.0 + show_quality_mult_permanent
	if GameState.night == int(gp.get("total_nights", 100)):
		engagement *= 1.0 + float(gp.get("finale_engagement_bonus", 0.0))
	var engagement_int := int(floor(engagement))

	# 4. Conversion (locked iter-1 formula from BALANCE_FINAL)
	var eng_per_attendee := 0.0
	if total_attendees > 0:
		eng_per_attendee = engagement / float(total_attendees)
	var quality_mult: float = 0.3 + minf(
			eng_per_attendee / float(zone.get("quality_target", 1.0)), 2.0)
	var effective_rate: float = minf(
			float(zone.base_conversion) * quality_mult,
			float(zone.max_conversion))
	var new_fans_f: float = float(total_attendees) * effective_rate
	var new_fans: int = int(floor(new_fans_f))
	var frac: float = new_fans_f - floor(new_fans_f)
	if randf() < frac:
		new_fans += 1

	# 5. Retention loss
	var fans_lost := int(floor(GameState.repeat_fans * float(gp.get("retention_loss_rate", 0.02))))

	# 6. Revenue
	var revenue := float(repeat_attendees) * float(zone.revenue_per_repeat) \
			+ float(walkup_total) * float(zone.revenue_per_attendee)
	revenue *= 1.0 + tip_mult_from_snacks + tip_mult_permanent
	var revenue_int := int(floor(revenue))

	# 7. Apply state updates
	GameState.repeat_fans = maxi(GameState.repeat_fans + new_fans - fans_lost, 0)
	GameState.money += float(revenue_int)
	GameState.total_money_earned += float(revenue_int)

	for fw_name in fireworks_decisions.keys():
		var count := int(fireworks_decisions[fw_name])
		if count <= 0:
			continue
		GameState.fireworks_fired_by_type[fw_name] = int(GameState.fireworks_fired_by_type.get(fw_name, 0)) + count
		GameState.total_fireworks_fired_this_run += count

	for t in [4, 3, 2, 1]:
		if int(tier_quantity.get(t, 0)) > 0 and t > GameState.highest_tier_fired_this_run:
			GameState.highest_tier_fired_this_run = t
	if firework_types_this_night > GameState.max_firework_types_in_any_night:
		GameState.max_firework_types_in_any_night = firework_types_this_night

	# 8. Zone advancement — keep advancing until threshold no longer met.
	var zone_advanced := false
	while GameState.current_zone < 6:
		var next_zone := BalanceConfig.get_zone(GameState.current_zone + 1)
		if next_zone.is_empty():
			break
		if GameState.repeat_fans >= int(next_zone.threshold_repeat_fans):
			GameState.current_zone += 1
			zone_advanced = true
		else:
			break

	# 9. Zone 6 clear → donation phase trigger
	var zone_6_clear_triggered := false
	if GameState.current_zone == 6:
		GameState.zone_6_revenue_earned += float(revenue_int)
		var threshold := float(gp.get("zone_6_clear_threshold", 6_000_000_000))
		if GameState.zone_6_revenue_earned >= threshold \
				and not GameState.donation_phase_decided \
				and GameState.night < int(gp.get("total_nights", 100)):
			GameState.donation_phase_available = true
			if not GameState.donation_phase_previously_available:
				zone_6_clear_triggered = true
				GameState.donation_phase_previously_available = true

	# 10. Immediate unlock checks
	var unlocks_earned: Array[String] = []
	if firework_types_this_night >= 10:
		_try_unlock_by_id("variety_show", unlocks_earned)
	if GameState.current_zone >= 3 and GameState.night <= 20:
		_try_unlock_by_id("early_zone_3", unlocks_earned)

	# 11. Advance the calendar
	GameState.night += 1

	var result := {
		"walkup": walkup_total,
		"repeat_attendees": repeat_attendees,
		"total_attendees": total_attendees,
		"engagement": engagement_int,
		"quality_mult": quality_mult,
		"quality_stars": _quality_stars(quality_mult),
		"effective_rate": effective_rate,
		"new_fans": new_fans,
		"fans_lost": fans_lost,
		"revenue": revenue_int,
		"money_spent": int(floor(total_spend)),
		"night_profit": revenue_int - int(floor(total_spend)),
		"zone_advanced": zone_advanced,
		"zone_6_clear_triggered": zone_6_clear_triggered,
		"synergies_triggered": synergies_hit.map(func(s: Dictionary) -> String: return String(s.name)),
		"unlocks_earned": unlocks_earned,
		"firework_types_this_night": firework_types_this_night,
		"resolved_at_night": GameState.night - 1,  # the night that just concluded
		"resolved_at_zone": GameState.current_zone,
	}
	GameState.last_night_results = result
	return result


func _check_synergies(firework_decisions: Dictionary, tier_quantity: Dictionary) -> Array:
	var hit: Array = []
	var fired := _fired_firework_list(firework_decisions)
	for syn in BalanceConfig.synergies():
		if syn.has("requires_all_tiers") and bool(syn.requires_all_tiers):
			if int(tier_quantity.get(1, 0)) > 0 and int(tier_quantity.get(2, 0)) > 0 \
					and int(tier_quantity.get(3, 0)) > 0 and int(tier_quantity.get(4, 0)) > 0:
				hit.append(syn)
			continue
		if syn.has("requires_tier"):
			var t := int(syn.requires_tier)
			if int(tier_quantity.get(t, 0)) >= int(syn.get("min_count", 1)):
				hit.append(syn)
			continue
		if syn.has("requires_tags"):
			var tag_groups: Array = syn.requires_tags
			var all_groups_present := true
			var total_quantity := 0
			for group in tag_groups:
				var group_quantity := 0
				for entry in fired:
					var fw: Dictionary = entry.fw
					if _firework_matches_tag_group(fw, group):
						group_quantity += int(entry.count)
				if group_quantity <= 0:
					all_groups_present = false
					break
				total_quantity += group_quantity
			if all_groups_present and total_quantity >= int(syn.get("min_count", 1)):
				hit.append(syn)
	return hit


func _fired_firework_list(firework_decisions: Dictionary) -> Array:
	var out: Array = []
	for fw_name in firework_decisions.keys():
		var count := int(firework_decisions[fw_name])
		if count <= 0:
			continue
		out.append({"fw": BalanceConfig.get_firework(fw_name), "count": count})
	return out


func _firework_matches_tag_group(fw: Dictionary, group: Array) -> bool:
	var tags: Array = fw.get("tags", [])
	for required in group:
		if not tags.has(required):
			return false
	return true


func _quality_stars(q: float) -> int:
	if q >= 1.8: return 5
	if q >= 1.4: return 4
	if q >= 1.0: return 3
	if q >= 0.7: return 2
	return 1


func _try_unlock_by_id(unlock_id: String, earned: Array[String]) -> void:
	for fw in BalanceConfig.fireworks():
		if String(fw.get("unlock_id", "")) == unlock_id:
			var fw_name := String(fw.name)
			if not MetaState.unlocked_fireworks.has(fw_name):
				MetaState.unlock_firework(fw_name)
				earned.append(fw_name)


func determine_ending() -> String:
	if GameState.donation_phase_decided:
		if GameState.donation_choice == "asteroid":
			return "true_ending"
		elif GameState.donation_choice == "":
			return "skipped"
		else:
			return "wrong_cause"
	return "zone_%d_finale" % GameState.current_zone


# After-run unlock checks — called once the ending is determined.
func check_end_of_run_unlocks(ending: String) -> Array[String]:
	var earned: Array[String] = []
	var final_zone := GameState.current_zone

	if final_zone <= 2:
		_try_unlock_by_id("humble_finale", earned)
	if final_zone == 2:
		_try_unlock_by_id("zone_2_finale", earned)
	if GameState.highest_tier_fired_this_run <= 2:
		_try_unlock_by_id("tier_minimalist", earned)

	# Cross-run cumulative checks
	var firecrackers := int(GameState.fireworks_fired_by_type.get("Firecracker", 0))
	if MetaState.total_firecrackers_fired_all_runs + firecrackers >= 1000:
		_try_unlock_by_id("firecracker_dedication", earned)
	if MetaState.total_fans_accumulated_all_runs + GameState.repeat_fans >= 10_000_000:
		_try_unlock_by_id("cumulative_fans", earned)

	match GameState.donation_choice:
		"library": _try_unlock_by_id("library_funded", earned)
		"hospital": _try_unlock_by_id("hospital_funded", earned)
		"wildlife": _try_unlock_by_id("wildlife_funded", earned)

	if ending == "true_ending":
		_try_unlock_by_id("true_ending_achieved", earned)
	elif ending == "wrong_cause" or ending == "skipped" or ending == "zone_6_finale":
		_try_unlock_by_id("fake_ending_seen", earned)

	return earned


# Returns purchasable fireworks: always includes non-unlockable; includes
# unlockable only if MetaState has it unlocked. Tier is not zone-gated per
# BRIEF — tiers are cost/engagement categories, available from any zone.
func available_fireworks() -> Array:
	var out: Array = []
	for fw in BalanceConfig.fireworks():
		if MetaState.is_firework_unlocked(fw):
			out.append(fw)
	return out


func available_marketing() -> Array:
	var out: Array = []
	for mk in BalanceConfig.marketing():
		if GameState.current_zone >= int(mk.get("min_zone", 1)):
			out.append(mk)
	return out


func available_enhancements() -> Dictionary:
	var out: Dictionary = {}
	for category in BalanceConfig.enhancement_categories():
		var filtered: Array = []
		for eh in BalanceConfig.enhancements_in(category):
			if GameState.current_zone >= int(eh.get("min_zone", 1)):
				filtered.append(eh)
		if not filtered.is_empty():
			out[category] = filtered
	return out


func available_upgrades() -> Array:
	var out: Array = []
	for up in BalanceConfig.upgrades():
		if GameState.owned_upgrades.has(String(up.name)):
			continue
		if GameState.current_zone < int(up.get("min_zone", 1)):
			continue
		out.append(up)
	return out
