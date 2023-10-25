
/datum/storyteller/sleeper
	name = "The Sleeper"
	desc = "The Sleeper will create less impactful events, especially ones involving combat or destruction. The chill experience."
	point_gains_multipliers = list(
		EVENT_TRACK_MUNDANE = 1,
		EVENT_TRACK_MODERATE = 0.7,
		EVENT_TRACK_MAJOR = 0.7,
		EVENT_TRACK_ROLESET = 0.7,
		EVENT_TRACK_OBJECTIVES = 1
		)
	guarantees_roundstart_roleset = FALSE
	tag_multipliers = list(TAG_COMBAT = 0.6, TAG_DESTRUCTIVE = 0.7)
