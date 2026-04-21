extends Node
## Loads data/balance_config.json once. Typed lookups for zones, fireworks,
## marketing, enhancements, upgrades, synergies, donation causes, game_params.
## The config is the canonical economy — never invent numbers.

const CONFIG_PATH := "res://data/balance_config.json"

var data: Dictionary = {}

var _zone_by_id: Dictionary = {}
var _firework_by_name: Dictionary = {}
var _marketing_by_name: Dictionary = {}
var _enhancement_by_key: Dictionary = {}
var _upgrade_by_name: Dictionary = {}
var _cause_by_id: Dictionary = {}


func _ready() -> void:
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	assert(f != null, "balance_config.json missing at %s" % CONFIG_PATH)
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	assert(parsed is Dictionary, "balance_config.json did not parse as object")
	data = parsed
	_build_indices()


func _build_indices() -> void:
	for zone in data.get("zones", []):
		_zone_by_id[int(zone.id)] = zone
	for fw in data.get("fireworks", []):
		_firework_by_name[String(fw.name)] = fw
	for mk in data.get("marketing", []):
		_marketing_by_name[String(mk.name)] = mk
	for category in data.get("enhancements", {}).keys():
		for eh in data.enhancements[category]:
			_enhancement_by_key["%s|%s" % [category, eh.name]] = eh
	for up in data.get("upgrades", []):
		_upgrade_by_name[String(up.name)] = up
	for cause in data.get("donation_causes", []):
		_cause_by_id[String(cause.id)] = cause


func get_zone(id: int) -> Dictionary:
	return _zone_by_id.get(id, {})


func zones() -> Array:
	return data.get("zones", [])


func get_firework(fw_name: String) -> Dictionary:
	return _firework_by_name.get(fw_name, {})


func fireworks() -> Array:
	return data.get("fireworks", [])


func get_marketing(mk_name: String) -> Dictionary:
	return _marketing_by_name.get(mk_name, {})


func marketing() -> Array:
	return data.get("marketing", [])


func get_enhancement(category: String, eh_name: String) -> Dictionary:
	return _enhancement_by_key.get("%s|%s" % [category, eh_name], {})


func enhancement_categories() -> Array:
	return data.get("enhancements", {}).keys()


func enhancements_in(category: String) -> Array:
	return data.get("enhancements", {}).get(category, [])


func get_upgrade(up_name: String) -> Dictionary:
	return _upgrade_by_name.get(up_name, {})


func upgrades() -> Array:
	return data.get("upgrades", [])


func synergies() -> Array:
	return data.get("synergies", [])


func donation_causes() -> Array:
	return data.get("donation_causes", [])


func get_cause(id: String) -> Dictionary:
	return _cause_by_id.get(id, {})


func game_params() -> Dictionary:
	return data.get("game_params", {})
