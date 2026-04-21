extends Node2D
## LAUNCH — entry point.
##
## Stage 2 placeholder. The desktop Claude agent will build out:
##   - Title / new run
##   - Newspaper interstitial (narrative + meteor sub-column)
##   - Three-panel planning screen (fireworks / marketing+enhancements / upgrades)
##   - Show summary screen
##   - Donation decision screen (single-shot when Z6 cleared)
##   - Ending screens
##
## All economy values come from data/balance_config.json (the validated sim
## config). See docs/BALANCE_FINAL.md and docs/STAGE2_BRIEF.md.

func _ready() -> void:
	print("LAUNCH stage 2 — world.gd loaded.")
	print("Read docs/STAGE2_BRIEF.md for the build spec.")
