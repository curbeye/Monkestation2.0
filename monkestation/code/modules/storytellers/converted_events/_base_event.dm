/datum/round_event_control
	///do we check against the antag cap before attempting a spawn?
	var/checks_antag_cap = FALSE
	/// List of enemy roles, will check if x amount of these exist exist
	var/list/enemy_roles
	///required number of enemies in roles to exist
	var/required_enemies = 0

/datum/round_event_control/proc/return_failure_string(players_amt)
	var/string
	if(roundstart && (world.time-SSticker.round_start_time >= 2 MINUTES))
		string += "Roundstart"
	if(occurrences >= max_occurrences)
		if(string)
			string += ","
		string += "Cap Reached"
	if(earliest_start >= world.time-SSticker.round_start_time)
		if(string)
			string += ","
		string +="Too Soon"
	if(players_amt < min_players)
		if(string)
			string += ","
		string += "Lack of players"
	if(holidayID && !check_holidays(holidayID))
		if(string)
			string += ","
		string += "Holiday Event"
	if(EMERGENCY_ESCAPED_OR_ENDGAMED)
		if(string)
			string += ","
		string += "Round End"
	if(checks_antag_cap)
		if(!roundstart && !SSgamemode.can_inject_antags())
			if(string)
				string += ","
			string += "Too Many Antags"
	return string

/datum/round_event_control/antagonist/return_failure_string(players_amt)
	. =..()
	if(!check_enemies())
		if(.)
			. += ", "
		. += "No Enemies"
	if(!check_required())
		if(.)
			. += ", "
		. += "No Required"
	return .

/datum/round_event_control/antagonist/solo/return_failure_string(players_amt)
	. =..()

	var/antag_amt = get_antag_amount()
	var/list/candidates = get_candidates()
	if(candidates.len < antag_amt)
		if(.)
			. += ", "
		. += "Not Enough Candidates!"

	return .

/datum/round_event_control/antagonist
	checks_antag_cap = TRUE
	track = EVENT_TRACK_ROLESET
	///list of required roles, needed for this to form
	var/list/exclusive_roles
	/// Protected roles from the antag roll. People will not get those roles if a config is enabled
	var/list/protected_roles
	/// Restricted roles from the antag roll
	var/list/restricted_roles

/datum/round_event_control/antagonist/proc/check_required()
	if(!length(exclusive_roles))
		return TRUE
	for (var/mob/M in GLOB.alive_player_list)
		if (M.stat == DEAD)
			continue // Dead players cannot count as passing requirements
		if(M.mind && (M.mind.assigned_role.title in exclusive_roles))
			return TRUE

/datum/round_event_control/antagonist/proc/trim_candidates(list/candidates)
	return candidates

/datum/round_event_control/proc/check_enemies()
	if(!length(enemy_roles))
		return TRUE
	var/job_check = 0
	for (var/mob/M in GLOB.alive_player_list)
		if (M.stat == DEAD)
			continue // Dead players cannot count as opponents
		if (M.mind && (M.mind.assigned_role.title in enemy_roles))
			job_check++ // Checking for "enemies" (such as sec officers). To be counters, they must either not be candidates to that rule, or have a job that restricts them from it

	if(job_check >= required_enemies)
		return TRUE
	return FALSE

/datum/round_event_control/antagonist/New()
	. = ..()
	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		restricted_roles |= protected_roles

/datum/round_event_control/antagonist/can_spawn_event(players_amt, allow_magic = FALSE, fake_check = FALSE)
	. = ..()
	if(!check_required())
		return FALSE

	if(!.)
		return

/datum/round_event_control/antagonist/solo
	typepath = /datum/round_event/antagonist/solo
	/// How many baseline antags do we spawn
	var/base_antags = 1
	/// How many maximum antags can we spawn
	var/maximum_antags = 3
	/// For this many players we'll add 1 up to the maximum antag amount
	var/denominator = 20
	/// The antag flag to be used
	var/antag_flag
	/// The antag datum to be applied
	var/antag_datum
	/// Prompt players for consent to turn them into antags before doing so. Dont allow this for roundstart.
	var/prompted_picking = FALSE

/datum/round_event_control/antagonist/solo/from_ghosts/get_candidates()
	var/round_started = SSticker.HasRoundStarted()
	var/midround_antag_pref_arg = round_started ? FALSE : TRUE

	var/list/candidates = SSgamemode.get_candidates(antag_flag, antag_flag, observers = TRUE, midround_antag_pref = midround_antag_pref_arg, restricted_roles = restricted_roles)
	candidates = trim_candidates(candidates)
	return candidates

/datum/round_event_control/antagonist/solo/can_spawn_event(players_amt, allow_magic = FALSE, fake_check = FALSE)
	. = ..()
	if(!.)
		return
	var/antag_amt = get_antag_amount()
	var/list/candidates = get_candidates()
	if(candidates.len < antag_amt)
		return FALSE

/datum/round_event_control/antagonist/solo/proc/get_antag_amount()
	var/people = SSgamemode.get_correct_popcount()
	var/amount = base_antags + FLOOR(people / denominator, 1)
	return min(amount, maximum_antags)

/datum/round_event_control/antagonist/solo/proc/get_candidates()
	var/round_started = SSticker.HasRoundStarted()
	var/new_players_arg = round_started ? FALSE : TRUE
	var/living_players_arg = round_started ? TRUE : FALSE
	var/midround_antag_pref_arg = round_started ? FALSE : TRUE

	var/list/candidates = SSgamemode.get_candidates(antag_flag, antag_flag, ready_newplayers = new_players_arg, living_players = living_players_arg, midround_antag_pref = midround_antag_pref_arg, restricted_roles = restricted_roles)
	candidates = trim_candidates(candidates)
	return candidates

/datum/round_event
	var/excute_round_end_reports = FALSE

/datum/round_event/proc/round_end_report()
	return

/datum/round_event/setup()
	. = ..()
	if(excute_round_end_reports)
		SSgamemode.round_end_data |= src

/datum/round_event/antagonist
	fakeable = FALSE
	end_when = 60 //This is so prompted picking events have time to run //TODO: refactor events so they can be the masters of themselves, instead of relying on some weirdly timed vars

/datum/round_event/antagonist/solo
	// ALL of those variables are internal. Check the control event to change them
	/// The antag flag passed from control
	var/antag_flag
	/// The antag datum passed from control
	var/antag_datum
	/// The antag count passed from control
	var/antag_count
	/// The restricted roles (jobs) passed from control
	var/list/restricted_roles
	/// The minds we've setup in setup() and need to finalize in start()
	var/list/setup_minds = list()
	/// Whether we prompt the players before picking them.
	var/prompted_picking = FALSE //TODO: Implement this

/datum/round_event/antagonist/solo/setup()
	var/datum/round_event_control/antagonist/solo/cast_control = control
	antag_count = cast_control.get_antag_amount()
	antag_flag = cast_control.antag_flag
	antag_datum = cast_control.antag_datum
	restricted_roles = cast_control.restricted_roles
	prompted_picking = cast_control.prompted_picking
	var/list/candidates = cast_control.get_candidates()
	if(prompted_picking)
		candidates = poll_candidates("Would you like to be a [cast_control.name]", antag_flag, antag_flag, 20 SECONDS, FALSE, FALSE, candidates)

	for(var/i in 1 to antag_count)
		if(!candidates.len)
			break
		var/mob/candidate = pick_n_take(candidates)
		if(!candidate.mind)
			candidate.mind = new /datum/mind(candidate.key)

		setup_minds += candidate.mind
		candidate.mind.special_role = antag_flag
		candidate.mind.restricted_roles = restricted_roles
	setup = TRUE


/datum/round_event/antagonist/solo/ghost/setup()
	var/datum/round_event_control/antagonist/solo/cast_control = control
	antag_count = cast_control.get_antag_amount()
	antag_flag = cast_control.antag_flag
	antag_datum = cast_control.antag_datum
	restricted_roles = cast_control.restricted_roles
	prompted_picking = cast_control.prompted_picking
	var/list/candidates = cast_control.get_candidates()
	if(prompted_picking)
		candidates = poll_candidates("Would you like to be a [cast_control.name]", antag_flag, antag_flag, 20 SECONDS, FALSE, FALSE, candidates)

	for(var/i in 1 to antag_count)
		if(!candidates.len)
			break
		var/mob/candidate = pick_n_take(candidates)
		if(!candidate.mind)
			candidate.mind = new /datum/mind(candidate.key)

		setup_minds += candidate.mind
		var/mob/living/carbon/human/new_human = make_body(candidate)
		candidate.mind.set_current(new_human)
		candidate.mind.special_role = antag_flag
		candidate.mind.restricted_roles = restricted_roles
	setup = TRUE


/datum/round_event/antagonist/solo/start()
	for(var/datum/mind/antag_mind as anything in setup_minds)
		add_datum_to_mind(antag_mind, antag_mind.current)

/datum/round_event/antagonist/solo/proc/add_datum_to_mind(datum/mind/antag_mind)
	antag_mind.add_antag_datum(antag_datum)

/datum/round_event/antagonist/solo/ghost/start()
	for(var/datum/mind/antag_mind as anything in setup_minds)
		add_datum_to_mind(antag_mind)

