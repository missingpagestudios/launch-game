extends Node
## Auto-generates newspaper content based on the last night's result and the
## current meta/run state. Pure strings — no state mutation.

const ZONE_PAPERS := {
	1: "BACKYARD WEEKLY",
	2: "THE NEIGHBORHOOD TIMES",
	3: "TOWN CRIER",
	4: "THE CITY HERALD",
	5: "REGIONAL POST",
	6: "WORLD TRIBUNE",
}

const GOOD_HEADLINES := [
	"LAST NIGHT'S SHOW DAZZLES CROWD",
	"COMMUNITY RAVES ABOUT DISPLAY",
	"'BEST SHOW YET' SAYS LOCAL",
	"SKIES ALIGHT, CROWDS ROAR",
]
const AVERAGE_HEADLINES := [
	"FIREWORKS NIGHT A MODEST SUCCESS",
	"CROWDS GATHER FOR DISPLAY",
	"STEADY ENTERTAINMENT LAST NIGHT",
]
const WEAK_HEADLINES := [
	"DISPLAY LEAVES SOME WANTING MORE",
	"FIREWORKS NIGHT UNDERWHELMS",
	"SMALL TURNOUT AT LAST NIGHT'S SHOW",
]
const ADVANCED_HEADLINES := [
	"PYROTECHNIC CAREER EXPANDS TO %s",
	"BREAKTHROUGH PERFORMANCE OPENS NEW MARKETS",
	"TO %s! CROWDS ARRIVE FROM WIDER AFIELD",
]

# Four-phase Dr. Chen escalation.
const METEOR_30_50 := [
	"ASTRONOMER DR. ELEANOR CHEN NOTES UNUSUAL CELESTIAL ACTIVITY",
	"OBSERVATORY REPORTS 'OBJECT OF INTEREST' IN SKIES",
	"SCIENTISTS DISCUSS NEED FOR BETTER TRACKING EQUIPMENT",
]
const METEOR_51_75 := [
	"DR. CHEN SEEKS FUNDING FOR RESEARCH PROGRAM",
	"CELESTIAL OBJECT 'REQUIRES URGENT STUDY' SAY ASTRONOMERS",
	"TRACKING STATION LACKS RESOURCES FOR FULL INVESTIGATION",
]
const METEOR_76_95 := [
	"ASTRONOMER WARNS OF POTENTIAL IMPACT RISK",
	"DR. CHEN: 'WE NEED TO ACT BEFORE IT'S TOO LATE'",
	"OBSERVATORY DATA SUGGESTS DANGEROUS TRAJECTORY",
]
const METEOR_96_100 := [
	"ASTEROID RESEARCH PROGRAM SEEKING EMERGENCY FUNDING",
	"DR. CHEN WARNS OF IMPENDING CATASTROPHE",
	"SCIENTIFIC COMMUNITY: INTERCEPT WINDOW CLOSING",
]

const CAUSE_BLURBS := {
	"library": "Library Fundraiser Needs Support",
	"music": "Local Music Education Program Rallies Donors",
	"hospital": "Children's Hospital Seeking Donors for New Wing",
	"wildlife": "Wildlife Conservation Group Calls for Champions",
	"veterans": "Veterans Support Services Holds Town Hall",
	"mental_health": "Mental Health Services Push for Visibility",
	"small_business": "Small Business Recovery Fund Underway",
}


func build_article(result: Dictionary) -> Dictionary:
	var zone_id := int(result.get("resolved_at_zone", GameState.current_zone))
	var night := int(result.get("resolved_at_night", max(GameState.night - 1, 1)))
	var paper_name: String = ZONE_PAPERS.get(zone_id, "THE DAILY LEDGER")
	var zone_name: String = String(BalanceConfig.get_zone(zone_id).get("name", "Unknown"))

	var headline := _pick_headline(result)
	var body := _build_body(result, zone_name)
	var meteor := _pick_meteor_line(night)
	var cause_mention := _maybe_cause_mention(night)
	var synergy_callout := _synergy_line(result)

	return {
		"paper_name": paper_name,
		"date_line": "NIGHT %d — %s" % [night, zone_name.to_upper()],
		"headline": headline,
		"body": body,
		"meteor_column": meteor,
		"cause_mention": cause_mention,
		"synergy_callout": synergy_callout,
	}


func _pick_headline(result: Dictionary) -> String:
	if bool(result.get("zone_advanced", false)):
		var zone_name := String(BalanceConfig.get_zone(int(result.get("resolved_at_zone", 1))).get("name", ""))
		var tmpl: String = ADVANCED_HEADLINES.pick_random()
		if tmpl.contains("%s"):
			return tmpl % zone_name.to_upper()
		return tmpl
	var stars := int(result.get("quality_stars", 3))
	if stars >= 4:
		return GOOD_HEADLINES.pick_random()
	if stars <= 2:
		return WEAK_HEADLINES.pick_random()
	return AVERAGE_HEADLINES.pick_random()


func _build_body(result: Dictionary, zone_name: String) -> String:
	var attendees := int(result.get("total_attendees", 0))
	var revenue := int(result.get("revenue", 0))
	var new_fans := int(result.get("new_fans", 0))
	var engagement := int(result.get("engagement", 0))
	var quality := int(result.get("quality_stars", 3))

	var mood := "thrilled" if quality >= 4 else ("satisfied" if quality == 3 else "quiet")
	var crowd_line := "%s gathered in %s and left %s." % [_fmt_num(attendees), zone_name, mood]
	var money_line := "Organizers cleared %s in ticketing and adjacencies." % _fmt_dollars(revenue)
	var fans_line := "Some %d attendees signed on as regulars for the next show." % new_fans
	if new_fans <= 0:
		fans_line = "The crowd dispersed with polite applause; few stayed committed to return."
	var eng_line := "Total engagement clocked at %s." % _fmt_num(engagement)
	return "%s %s %s %s" % [crowd_line, money_line, fans_line, eng_line]


func _pick_meteor_line(night: int) -> String:
	if night < 30:
		return ""
	if night <= 50:
		return METEOR_30_50.pick_random()
	if night <= 75:
		return METEOR_51_75.pick_random()
	if night <= 95:
		return METEOR_76_95.pick_random()
	return METEOR_96_100.pick_random()


func _maybe_cause_mention(night: int) -> String:
	if night % 10 != 0:
		return ""
	var keys := CAUSE_BLURBS.keys()
	var key: String = keys[night % keys.size()]
	return CAUSE_BLURBS[key]


func _synergy_line(result: Dictionary) -> String:
	var syns: Array = result.get("synergies_triggered", [])
	if syns.is_empty():
		return ""
	return "Crowd reaction singled out: %s." % ", ".join(syns)


func _fmt_num(n: int) -> String:
	if n >= 1_000_000_000:
		return "%.1fB" % (n / 1_000_000_000.0)
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	if n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)


func _fmt_dollars(n: int) -> String:
	return "$" + _fmt_num(n)
