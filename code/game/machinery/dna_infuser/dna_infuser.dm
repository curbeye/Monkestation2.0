/// how long it takes to infuse
#define INFUSING_TIME 4 SECONDS
/// we throw in a scream along the way.
#define SCREAM_TIME 3 SECONDS

/obj/machinery/dna_infuser
	name = "\improper DNA infuser"
	desc = "A defunct genetics machine for merging foreign DNA with a subject's own."
	icon = 'icons/obj/machines/cloning.dmi'
	icon_state = "infuser"
	base_icon_state = "infuser"
	density = TRUE
	obj_flags = BLOCKS_CONSTRUCTION // Becomes undense when the door is open
	circuit = /obj/item/circuitboard/machine/dna_infuser
	/// maximum tier this will infuse
	var/max_tier_allowed = DNA_MUTANT_TIER_ONE
	///currently infusing a vict- subject
	var/infusing = FALSE
	///what we're infusing with
	var/atom/movable/infusing_from
	///what we're turning into
	// var/datum/infuser_entry/infusing_into

	//current XP, amounts of organs infused
	var/progression = 0
	//current XP Goal
	var/progression_goal = DNA_INFUSER_PROG_ONE

	///a message for relaying that the machine is locked if someone tries to leave while it's active
	COOLDOWN_DECLARE(message_cooldown)

/obj/machinery/dna_infuser/Initialize(mapload)
	. = ..()
	occupant_typecache = typecacheof(/mob/living/carbon/human)

/obj/machinery/dna_infuser/Destroy()
	. = ..()
	//dump_inventory_contents called by parent, emptying infusing_from
	infusing_from = null

/obj/machinery/dna_infuser/examine(mob/user)
	. = ..()
	if(!occupant)
		. += span_notice("Requires [span_bold("a subject")].")
	else
		. += span_notice("\"[span_bold(occupant.name)]\" is inside the infusion chamber.")
	if(!infusing_from)
		. += span_notice("Missing [span_bold("an infusion source")].")
	else
		. += span_notice("[span_bold(infusing_from.name)] is in the infusion slot.")
	. += span_notice("To operate: Obtain dead creature. Depending on size, drag or drop into the infuser slot.")
	. += span_notice("Subject enters the chamber, someone activates the machine. Voila! One of your organs has... changed!")
	. += span_notice("Alt-click to eject the infusion source, if one is inside.")
	if(max_tier_allowed < DNA_INFUSER_MAX_TIER)
		. += span_boldnotice("Right now, the DNA Infuser can only infuse Tier [max_tier_allowed] entries. Progression: [progression]/[progression_goal]")
	else
		. += span_boldnotice("Maximum tier unlocked. All DNA entries are possible. Progression: [progression]")
	. += span_notice("Examine further for more information.")

/obj/machinery/dna_infuser/examine_more(mob/user)
	. = ..()
	. += span_notice("If you infuse enough Tier [max_tier_allowed] entries, it will upgrade the maximum tier and allow more complicated infusions.")
	. += span_notice("The maximum level it can reach is Tier [DNA_INFUSER_MAX_TIER].")

/obj/machinery/dna_infuser/interact(mob/user)
	if(user == occupant)
		toggle_open(user)
		return
	if(infusing)
		balloon_alert(user, "not while it's on!")
		return
	if(occupant && infusing_from)
		// Abort infusion if the occupant is invalid.
		if(!is_valid_occupant(occupant, user))
			playsound(src, 'sound/machines/scanbuzz.ogg', 35, vary = TRUE)
			return
		balloon_alert(user, "starting DNA infusion...")
		start_infuse()
		return
	toggle_open(user)

/obj/machinery/dna_infuser/proc/start_infuse()
	var/mob/living/carbon/human/human_occupant = occupant
	infusing = TRUE
	visible_message(span_notice("[src] hums to life, beginning the infusion process!"))
	var/fail_title = ""
	var/fail_reason = ""

	var/datum/infuser_entry/entry = get_entry_from_organ(infusing_from)
	if(!entry)
		infusing = FALSE
		return

	playsound(src, 'sound/machines/blender.ogg', 50, vary = TRUE)
	to_chat(human_occupant, span_danger("Little needles repeatedly prick you!"))
	human_occupant.take_overall_damage(10)
	human_occupant.add_mob_memory(/datum/memory/dna_infusion, protagonist = human_occupant, deuteragonist = infusing_from, mutantlike = entry.infusion_desc)
	Shake(duration = INFUSING_TIME)
	addtimer(CALLBACK(human_occupant, TYPE_PROC_REF(/mob, emote), "scream"), INFUSING_TIME - 1 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(end_infuse), fail_reason, fail_title, entry), INFUSING_TIME)
	update_appearance()

/obj/machinery/dna_infuser/proc/end_infuse(fail_reason, fail_title, datum/infuser_entry/entry)
	if(infuse_organ(occupant))
		to_chat(occupant, span_danger("You feel yourself becoming more... [entry.infusion_desc]?"))
	infusing = FALSE
	infusing_from = null
	QDEL_NULL(infusing_from)
	playsound(src, 'sound/machines/microwave/microwave-end.ogg', 100, vary = FALSE)
	if(fail_reason)
		playsound(src, 'sound/machines/printer.ogg', 100, TRUE)
		visible_message(span_notice("[src] prints an error report."))
		var/obj/item/paper/printed_paper = new /obj/item/paper(loc)
		printed_paper.name = "error report - '[fail_title]'"
		printed_paper.add_raw_text(fail_reason)
		printed_paper.update_appearance()
	toggle_open()
	update_appearance()

/// Attempt to replace/add-to the occupant's organs with "mutated" equivalents.
/// Returns TRUE on success, FALSE on failure.
/// Requires the target mob to have an existing organic organ to "mutate".
// TODO: In the future, this should have more logic:
// - Replace non-mutant organs before mutant ones.
/obj/machinery/dna_infuser/proc/infuse_organ(mob/living/carbon/human/target)
	if(!ishuman(target))
		return FALSE
	// var/obj/item/organ/new_organ = pick_organ(target)
	if(!infusing_from)
		return FALSE
	// Valid organ successfully picked.
	var/obj/item/organ/new_organ = infusing_from
	new_organ.replace_into(target)

/// Picks a random mutated organ from the infuser entry which is also compatible with the target mob.
/// Tries to return a typepath of a valid mutant organ if all of the following criteria are true:
/// 1. Target must have a pre-existing organ in the same organ slot as the new organ;
///   - or the new organ must be external.
/// 2. Target's pre-existing organ must be organic / not robotic.
/// 3. Target must not have the same/identical organ.
// /obj/machinery/dna_infuser/proc/pick_organ(mob/living/carbon/human/target)
// 	if(!infusing_into)
// 		return FALSE
// 	var/list/obj/item/organ/potential_new_organs = infusing_into.output_organs.Copy()
// 	// Remove organ typepaths from the list if they're incompatible with target.
// 	for(var/obj/item/organ/new_organ as anything in infusing_into.output_organs)
// 		var/obj/item/organ/old_organ = target.get_organ_slot(initial(new_organ.slot))
// 		if(old_organ)
// 			if((old_organ.type != new_organ) && (old_organ.status != ORGAN_ROBOTIC))
// 				continue // Old organ can be mutated!
// 		else if(ispath(new_organ, /obj/item/organ/external))
// 			continue // External organ can be grown!
// 		// Internal organ is either missing, or is non-organic.
// 		potential_new_organs -= new_organ
// 	// Pick a random organ from the filtered list.
// 	if(length(potential_new_organs))
// 		return pick(potential_new_organs)
// 	return FALSE

/// checks to see if the machine should progress a new tier.
/obj/machinery/dna_infuser/proc/update_tier_experience(var/datum/infuser_entry/entry)
	progression += entry.tier

	if(max_tier_allowed != DNA_INFUSER_MAX_TIER \
		&& progression >= progression_goal)
		max_tier_allowed++
		switch(max_tier_allowed)
			if(1)
				progression_goal = DNA_INFUSER_PROG_ONE
			if(2)
				progression_goal = DNA_INFUSER_PROG_TWO
			if(3)
				progression_goal = DNA_INFUSER_PROG_THREE
		playsound(loc, 'sound/machines/ding.ogg', 50, TRUE)
		visible_message(span_notice("[src] dings as it records the cumulative results of past infusions."))
		progression = 0

/obj/machinery/dna_infuser/update_icon_state()
	//out of order
	if(machine_stat & (NOPOWER | BROKEN))
		icon_state = base_icon_state
		return ..()
	//maintenance
	if((machine_stat & MAINT) || panel_open)
		icon_state = "[base_icon_state]_panel"
		return ..()
	//actively running
	if(infusing)
		icon_state = "[base_icon_state]_on"
		return ..()
	//open or not
	icon_state = "[base_icon_state][state_open ? "_open" : null]"
	return ..()

/obj/machinery/dna_infuser/proc/toggle_open(mob/user)
	if(panel_open)
		if(user)
			balloon_alert(user, "close panel first!")
		return
	if(state_open)
		close_machine()
		return
	else if(infusing)
		if(user)
			balloon_alert(user, "not while it's on!")
		return
	open_machine(drop = FALSE)
	//we set drop to false to manually call it with an allowlist
	dump_inventory_contents(list(occupant))

/obj/machinery/dna_infuser/attackby(obj/item/used, mob/user, params)
	if(infusing)
		return
	if(!occupant && default_deconstruction_screwdriver(user, icon_state, icon_state, used))//sent icon_state is irrelevant...
		update_appearance()//..since we're updating the icon here, since the scanner can be unpowered when opened/closed
		return
	if(default_pry_open(used))
		return
	if(default_deconstruction_crowbar(used))
		return
	if(ismovable(used))
		add_infusion_item(used, user)
	return ..()

/obj/machinery/dna_infuser/relaymove(mob/living/user, direction)
	if(user.stat)
		if(COOLDOWN_FINISHED(src, message_cooldown))
			COOLDOWN_START(src, message_cooldown, 4 SECONDS)
			to_chat(user, span_warning("[src]'s door won't budge!"))
		return
	if(infusing)
		if(COOLDOWN_FINISHED(src, message_cooldown))
			COOLDOWN_START(src, message_cooldown, 4 SECONDS)
			to_chat(user, span_danger("[src]'s door won't budge while all the needles are infusing you!"))
		return
	open_machine(drop = FALSE)
	//we set drop to false to manually call it with an allowlist
	dump_inventory_contents(list(occupant))

/obj/machinery/dna_infuser/proc/get_entry(target)
	for(var/datum/infuser_entry/entry as anything in GLOB.infuser_entries)
		if(entry.tier == DNA_MUTANT_UNOBTAINABLE)
			continue
		if(is_type_in_list(target, entry.input_obj_or_mob))
			if(entry.tier > max_tier_allowed)
				visible_message(span_notice("DNA too complicated to infuse. The machine needs to infuse simpler DNA first."))
				return
			return entry

/obj/machinery/dna_infuser/proc/get_entry_from_organ(target)
	for(var/datum/infuser_entry/entry as anything in GLOB.infuser_entries)
		if(entry.tier == DNA_MUTANT_UNOBTAINABLE)
			continue
		if(is_type_in_list(target, entry.output_organs))
			if(entry.tier > max_tier_allowed)
				visible_message(span_notice("DNA too complicated to infuse. The machine needs to infuse simpler DNA first."))
				return
			return entry

/obj/machinery/dna_infuser/proc/get_organ(mob/user, target)
	// Get the entry from the target
	var/datum/infuser_entry/entry = get_entry(target)

	if(!entry)
		return

	// Get an organ from the entry
	var/list/obj/item/organ/possible_organs = entry.output_organs
	if(!length(possible_organs))
		to_chat(user, span_warning("No possible organs could be found!"))
		return


	var/list/choices = possible_organs.Copy()
	choices += "Random Organ (free)"

	var/chosen_organ = tgui_input_list(user, "Spend progression to choose an organ. Progression: [progression]. Cost: [entry.tier].", "Select an Organ", choices)

	if(chosen_organ == "Random Organ (free)")
		chosen_organ = pick(possible_organs)
		update_tier_experience(entry)
	else if(isnull(chosen_organ))
		return FALSE
	else
		if(progression < entry.tier)
			// to_chat(user, span_notice("Insufficient Progression. Cancelling insertion."))
			balloon_alert(user, span_notice("Insufficient Progression."))
			return FALSE

		progression -= entry.tier

	// turn the item into an organ
	playsound(src, 'sound/machines/blender.ogg', 25, vary = TRUE)
	to_chat(user, span_notice("[src] analyzes [target]!"))
	QDEL_NULL(target)

	var/obj/item/organ = new chosen_organ(loc)
	user.put_in_hands(organ)

// mostly good for dead mobs that turn into items like dead mice (smack to add).
/obj/machinery/dna_infuser/proc/add_infusion_item(obj/item/target, mob/user)
	// Check if they insert a valid organ.
	if(is_valid_organ(target,user))
		if(!user.transferItemToLoc(target, src))
			to_chat(user, span_warning("[target] is stuck to your hand!"))
			return
		infusing_from = target
	// if the machine already has a infusion target, or the target is not valid then no adding.
	else if(is_valid_infusion(target, user))
		get_organ(user, target)

// mostly good for dead mobs like corpses (drag to add).
/obj/machinery/dna_infuser/MouseDrop_T(atom/movable/target, mob/user)
	// if the machine is closed, already has a infusion target, or the target is not valid then no mouse drop.
	if(!is_valid_infusion(target, user))
		return

	get_organ(user, target)

/// Verify that the occupant/target is organic, and has mutable DNA.
/obj/machinery/dna_infuser/proc/is_valid_occupant(mob/living/carbon/human/human_target, mob/user)
	// Invalid: DNA is too damaged to mutate anymore / has TRAIT_BADDNA.
	if(HAS_TRAIT(human_target, TRAIT_BADDNA))
		balloon_alert(user, "dna is corrupted!")
		return FALSE
	// Invalid: Occupant isn't Human, isn't organic, lacks DNA / has TRAIT_GENELESS.
	if(!ishuman(human_target) || !human_target.can_mutate())
		balloon_alert(user, "dna is missing!")
		return FALSE
	// Valid: Occupant is an organic Human who has undamaged and mutable DNA.
	return TRUE

/// Verify that the given infusion source/mob is a dead creature.
/obj/machinery/dna_infuser/proc/is_valid_infusion(atom/movable/target, mob/user)
	if(user.stat != CONSCIOUS || HAS_TRAIT(user, TRAIT_UI_BLOCKED) || !Adjacent(user) || !user.Adjacent(target) || !ISADVANCEDTOOLUSER(user))
		return FALSE
	var/datum/component/edible/food_comp = IS_EDIBLE(target)
	if(infusing_from)
		balloon_alert(user, "empty the machine first!")
		return FALSE
	if(isliving(target))
		var/mob/living/living_target = target
		if(living_target.stat != DEAD)
			balloon_alert(user, "only dead creatures!")
			return FALSE
	else if(food_comp)
		if(!(food_comp.foodtypes & GORE))
			balloon_alert(user, "only creatures!")
			return FALSE
	else
		return FALSE
	return TRUE



/obj/machinery/dna_infuser/proc/is_valid_organ(atom/movable/target, mob/user)
	if(user.stat != CONSCIOUS || HAS_TRAIT(user, TRAIT_UI_BLOCKED) || !Adjacent(user) || !user.Adjacent(target) || !ISADVANCEDTOOLUSER(user))
		return FALSE
	if(infusing_from)
		balloon_alert(user, "empty the machine first!")
		return FALSE
	if(!is_type_in_list(target, GLOB.infuser_organs))
		return FALSE
	return TRUE

/obj/machinery/dna_infuser/AltClick(mob/user)
	. = ..()
	if(infusing)
		balloon_alert(user, "not while it's on!")
		return
	if(!infusing_from)
		balloon_alert(user, "no sample to eject!")
		return
	balloon_alert(user, "ejected sample")
	infusing_from.forceMove(get_turf(src))
	infusing_from = null

#undef INFUSING_TIME
#undef SCREAM_TIME
