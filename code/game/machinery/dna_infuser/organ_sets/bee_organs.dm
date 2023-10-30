#define BEE_ORGAN_COLOR "#daf205"
#define BEE_SCLERA_COLOR "#010000"
#define BEE_PUPIL_COLOR "#daf205"
#define BEE_COLORS BEE_ORGAN_COLOR + BEE_SCLERA_COLOR + BEE_PUPIL_COLOR

///set bonus:
/datum/status_effect/organ_set_bonus/bee
	id = "organ_set_bonus_bee"
	organs_needed = 3
	bonus_activate_text = span_notice("...")
	bonus_deactivate_text = span_notice("...")
	bonus_traits = list(TRAIT_RESISTHEAT, TRAIT_RESISTCOLD, TRAIT_NOBREATH, TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTHIGHPRESSURE)

// Inject people you hit with your blood that is also filled with a random chem
/obj/item/organ/internal/heart/bee
	name = "mutated bee-heart"
	desc = "Bee DNA infused into what was once a normal heart."

	icon = 'icons/obj/medical/organs/infuser_organs.dmi'
	icon_state = "heart"
	greyscale_config = /datum/greyscale_config/mutant_organ
	greyscale_colors = BEE_COLORS
	organ_traits = list()

	var/datum/reagent/toxin/beegent

	var/datum/martial_art/bee_sting/bee_sting

/obj/item/organ/internal/heart/bee/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/organ_set_bonus, /datum/status_effect/organ_set_bonus/bee)
	AddElement(/datum/element/noticable_organ, "has an odd yellow pulsing through their veins.")
	// Set a beegent
	var/datum/reagent/toxin = pick(typesof(/datum/reagent/toxin))
	beegent = toxin
	name = name + " ([initial(toxin.name)])"

	bee_sting = new
	bee_sting.beegent = toxin


/obj/item/organ/internal/heart/bee/Insert(mob/living/carbon/organ_owner, special, drop_if_replaced)
	. = ..()
	bee_sting.teach(organ_owner)

/obj/item/organ/internal/heart/bee/Remove(mob/living/carbon/organ_owner, special)
	. = ..()
	bee_sting.remove(organ_owner)


///
/obj/item/organ/internal/tongue/bee
	name = "mutated bee-tongue"
	desc = "Bee DNA infused into what was once a normal tongue."
	icon = 'icons/obj/medical/organs/infuser_organs.dmi'
	icon_state = "tongue"
	greyscale_config = /datum/greyscale_config/mutant_organ
	greyscale_colors = BEE_COLORS

/obj/item/organ/internal/tongue/gondola/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/noticable_organ, "mouth is permanently affixed into a relaxed smile.", BODY_ZONE_PRECISE_MOUTH)
	AddElement(/datum/element/organ_set_bonus, /datum/status_effect/organ_set_bonus/gondola)

/obj/item/organ/internal/tongue/gondola/Insert(mob/living/carbon/tongue_owner, special, drop_if_replaced)
	. = ..()
	tongue_owner.add_mood_event("gondola_zen", /datum/mood_event/gondola_serenity)

/obj/item/organ/internal/tongue/gondola/Remove(mob/living/carbon/tongue_owner, special)
	tongue_owner.clear_mood_event("gondola_zen")
	return ..()

/// Loving arms: your hands become unable to hold much of anything but your hugs now infuse the subject with pax.
// /obj/item/organ/internal/liver/gondola
// 	name = "mutated gondola-liver"
// 	desc = "Gondola DNA infused into what was once a normal liver."
// 	icon = 'icons/obj/medical/organs/infuser_organs.dmi'
// 	icon_state = "liver"
// 	greyscale_config = /datum/greyscale_config/mutant_organ
// 	greyscale_colors = BEE_COLORS
// 	/// instance of the martial art granted on insertion
// 	var/datum/martial_art/hugs_of_the_gondola/pax_hugs

// /obj/item/organ/internal/liver/gondola/Initialize(mapload)
// 	. = ..()
// 	AddElement(/datum/element/organ_set_bonus, /datum/status_effect/organ_set_bonus/gondola)
// 	AddElement(/datum/element/noticable_organ, "left arm has small needles breaching the skin all over it.", BODY_ZONE_L_ARM)
// 	AddElement(/datum/element/noticable_organ, "right arm has small needles breaching the skin all over it.", BODY_ZONE_R_ARM)
// 	pax_hugs = new

// /obj/item/organ/internal/liver/gondola/Insert(mob/living/carbon/liver_owner, special, drop_if_replaced)
// 	. = ..()
// 	var/has_left = liver_owner.has_left_hand(check_disabled = FALSE)
// 	var/has_right = liver_owner.has_right_hand(check_disabled = FALSE)
// 	if(has_left && has_right)
// 		to_chat(liver_owner, span_warning("Your arms grow terribly weak as small, needle-like pricks grow all over them!"))
// 	else if(has_left || has_right)
// 		to_chat(liver_owner, span_warning("Your arm grows terribly weak as small, needle-like pricks grow all over it!"))
// 	else
// 		to_chat(liver_owner, span_warning("You feel like something would be happening to your arms right now... if you still had them."))
// 	to_chat(liver_owner, span_notice("Hugging a target will pacify them, but you won't be able to carry much of anything anymore."))
// 	pax_hugs.teach(liver_owner)
// 	RegisterSignal(liver_owner, COMSIG_HUMAN_EQUIPPING_ITEM, PROC_REF(on_owner_equipping_item))
// 	RegisterSignal(liver_owner, COMSIG_LIVING_TRY_PULL, PROC_REF(on_owner_try_pull))

// /obj/item/organ/internal/liver/gondola/Remove(mob/living/carbon/liver_owner, special)
// 	. = ..()
// 	pax_hugs.remove(liver_owner)
// 	UnregisterSignal(liver_owner, list(COMSIG_HUMAN_EQUIPPING_ITEM, COMSIG_LIVING_TRY_PULL))

// /// signal sent when prompting if an item can be equipped
// /obj/item/organ/internal/liver/gondola/proc/on_owner_equipping_item(mob/living/carbon/human/owner, obj/item/equip_target, slot)
// 	SIGNAL_HANDLER
// 	if(equip_target.w_class > WEIGHT_CLASS_TINY)
// 		equip_target.balloon_alert(owner, "too weak to hold this!")
// 		return COMPONENT_BLOCK_EQUIP

// /// signal sent when owner tries to pull an item
// /obj/item/organ/internal/liver/gondola/proc/on_owner_try_pull(mob/living/carbon/owner, atom/movable/target, force)
// 	SIGNAL_HANDLER
// 	if(isliving(target))
// 		var/mob/living/living_target = target
// 		if(living_target.mob_size > MOB_SIZE_TINY)
// 			living_target.balloon_alert(owner, "too weak to pull this!")
// 			return COMSIG_LIVING_CANCEL_PULL
// 	if(isitem(target))
// 		var/obj/item/item_target = target
// 		if(item_target.w_class > WEIGHT_CLASS_TINY)
// 			item_target.balloon_alert(owner, "too weak to pull this!")
// 			return COMSIG_LIVING_CANCEL_PULL

#undef BEE_ORGAN_COLOR
#undef BEE_SCLERA_COLOR
#undef BEE_PUPIL_COLOR
#undef BEE_COLORS
