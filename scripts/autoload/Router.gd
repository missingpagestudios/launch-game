extends Node
## Owns screen transitions. Scenes don't change_scene directly — they call
## Router so the flow rules live in one place.

const TITLE := "res://scenes/title.tscn"
const PLANNING := "res://scenes/planning.tscn"
const SHOW := "res://scenes/show.tscn"
const NEWSPAPER := "res://scenes/newspaper.tscn"
const DONATION := "res://scenes/donation.tscn"
const ENDING := "res://scenes/ending.tscn"
const FIREWORKS_DEMO := "res://scenes/fireworks_demo.tscn"


func go_title() -> void:
	get_tree().change_scene_to_file(TITLE)


func go_fireworks_demo() -> void:
	get_tree().change_scene_to_file(FIREWORKS_DEMO)


func start_new_run() -> void:
	GameState.start_new_run()
	get_tree().change_scene_to_file(PLANNING)


# Called from PlanningScreen after the player confirms decisions.
# We stash the result on GameState and head to ShowScreen.
func commit_night(result: Dictionary) -> void:
	GameState.pending_newspaper = NewspaperContent.build_article(result)
	get_tree().change_scene_to_file(SHOW)


# Called from ShowScreen after the player clicks Continue.
func after_show() -> void:
	get_tree().change_scene_to_file(NEWSPAPER)


# Called from NewspaperScreen "Continue to Planning" — handles all the
# branching between normal planning, donation interrupt, and ending.
func after_newspaper() -> void:
	var gp := BalanceConfig.game_params()
	var total_nights := int(gp.get("total_nights", 100))

	# Night counter already advanced inside GameEngine.resolve_night.
	# If the just-resolved night was the final one, GameState.night is now
	# total_nights + 1 → end of run.
	if GameState.night > total_nights:
		_resolve_ending()
		return

	if GameState.donation_phase_available and not GameState.donation_phase_decided:
		get_tree().change_scene_to_file(DONATION)
		return

	get_tree().change_scene_to_file(PLANNING)


func donation_chosen(cause_id: String) -> void:
	var gp := BalanceConfig.game_params()
	if cause_id != "":
		GameState.money -= float(gp.get("donation_cost", 2_500_000_000))
		GameState.donation_choice = cause_id
	else:
		GameState.donation_choice = ""
	GameState.donation_phase_decided = true
	GameState.donation_phase_available = false
	get_tree().change_scene_to_file(PLANNING)


func _resolve_ending() -> void:
	GameState.ending_type = GameEngine.determine_ending()
	var end_unlocks := GameEngine.check_end_of_run_unlocks(GameState.ending_type)
	MetaState.record_run_end(
		GameState.ending_type,
		GameState.current_zone,
		GameState.total_money_earned,
		GameState.total_fireworks_fired_this_run,
		GameState.repeat_fans,
		int(GameState.fireworks_fired_by_type.get("Firecracker", 0)),
	)
	# Pass along unlocks via pending_newspaper scratch for ending to show.
	GameState.pending_newspaper = {"ending_unlocks": end_unlocks}
	get_tree().change_scene_to_file(ENDING)


func return_to_title_from_ending() -> void:
	get_tree().change_scene_to_file(TITLE)
