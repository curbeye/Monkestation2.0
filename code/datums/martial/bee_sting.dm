/// Beegent :), sting people when you punch em
/datum/martial_art/bee_sting
	name = "Stinger"
	id = MARTIALART_BEE_STING
	var/datum/reagent/beegent

/datum/martial_art/bee_sting/harm_act(mob/living/attacker, mob/living/defender)
	if(!beegent)
		return MARTIAL_ATTACK_INVALID
	if(ishuman(defender) && ishuman(attacker))
		var/mob/living/carbon/human/human_attacker = attacker
		var/mob/living/carbon/human/human_defender = defender
		var/amount = 1

		// Use up their blood. 4:1 blood:toxin seems good to me for now. you'll use up blood pretty fast if you keep punching so it kinda balances out.
		attacker.blood_volume -= 4

		human_defender.reagents.add_reagent(beegent, amount)
		to_chat(defender, span_warning("You feel a tiny prick!"))
		to_chat(attacker, span_warning("You prick [defender] with your stingers!"))
	//this is so it attacks as usual
	return MARTIAL_ATTACK_INVALID
