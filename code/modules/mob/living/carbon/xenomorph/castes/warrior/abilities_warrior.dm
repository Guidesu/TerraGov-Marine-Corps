// ***************************************
// *********** Agility
// ***************************************
/datum/action/xeno_action/toggle_agility
	name = "Toggle Agility"
	action_icon_state = "agility_on"
	mechanics_text = "Move an all fours for greater speed. Cannot use abilities while in this mode."
	ability_name = "toggle agility"
	cooldown_timer = 0.5 SECONDS
	use_state_flags = XACT_USE_AGILITY
	keybind_signal = COMSIG_XENOABILITY_TOGGLE_AGILITY
	var/last_agility_bonus = 0

/datum/action/xeno_action/toggle_agility/on_xeno_upgrade()
	var/mob/living/carbon/xenomorph/X = owner
	if(X.agility)
		var/armor_change = X.xeno_caste.agility_speed_armor
		X.soft_armor = X.soft_armor.modifyAllRatings(armor_change)
		last_agility_bonus = armor_change
		X.add_movespeed_modifier(MOVESPEED_ID_WARRIOR_AGILITY , TRUE, 0, NONE, TRUE, X.xeno_caste.agility_speed_increase)

/datum/action/xeno_action/toggle_agility/on_cooldown_finish()
	var/mob/living/carbon/xenomorph/X = owner
	to_chat(X, "<span class='notice'>We can [X.agility ? "raise ourselves back up" : "lower ourselves back down"] again.</span>")
	return ..()

/datum/action/xeno_action/toggle_agility/action_activate()
	var/mob/living/carbon/xenomorph/X = owner

	X.agility = !X.agility

	GLOB.round_statistics.warrior_agility_toggles++
	SSblackbox.record_feedback("tally", "round_statistics", 1, "warrior_agility_toggles")
	if(X.agility)
		to_chat(X, "<span class='xenowarning'>We lower ourselves to all fours and loosen our armored scales to ease our movement.</span>")
		X.add_movespeed_modifier(MOVESPEED_ID_WARRIOR_AGILITY , TRUE, 0, NONE, TRUE, X.xeno_caste.agility_speed_increase)
		var/armor_change = X.xeno_caste.agility_speed_armor
		X.soft_armor = X.soft_armor.modifyAllRatings(armor_change)
		last_agility_bonus = armor_change
	else
		to_chat(X, "<span class='xenowarning'>We raise ourselves to stand on two feet, hard scales setting back into place.</span>")
		X.remove_movespeed_modifier(MOVESPEED_ID_WARRIOR_AGILITY)
		X.soft_armor = X.soft_armor.modifyAllRatings(-last_agility_bonus)
		last_agility_bonus = 0
	X.update_icons()
	add_cooldown()
	return succeed_activate()

// ***************************************
// *********** Lunge
// ***************************************
/datum/action/xeno_action/activable/lunge
	name = "Lunge"
	action_icon_state = "lunge"
	mechanics_text = "Pounce up to 5 tiles and grab a target, knocking them down and putting them in your grasp."
	ability_name = "lunge"
	plasma_cost = 25
	cooldown_timer = 20 SECONDS
	keybind_signal = COMSIG_XENOABILITY_LUNGE
	target_flags = XABB_MOB_TARGET

/datum/action/xeno_action/activable/lunge/proc/neck_grab(mob/living/owner, mob/living/L)
	SIGNAL_HANDLER
	if(!can_use_ability(L, FALSE, XACT_IGNORE_DEAD_TARGET))
		return COMSIG_WARRIOR_CANT_NECKGRAB


/datum/action/xeno_action/activable/lunge/give_action(mob/living/L)
	. = ..()
	RegisterSignal(owner, COMSIG_WARRIOR_USED_GRAB, .proc/add_cooldown)
	RegisterSignal(owner, COMSIG_WARRIOR_NECKGRAB, .proc/neck_grab)


/datum/action/xeno_action/activable/lunge/remove_action(mob/living/L)
	UnregisterSignal(owner, COMSIG_WARRIOR_USED_GRAB)
	UnregisterSignal(owner, COMSIG_WARRIOR_NECKGRAB)
	return ..()


/datum/action/xeno_action/activable/lunge/can_use_ability(atom/A, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE
	if(!A)
		return FALSE
	if(!ishuman(A))
		return FALSE
	var/flags_to_check = use_state_flags|override_flags
	var/mob/living/carbon/human/H = A
	if(!CHECK_BITFIELD(flags_to_check, XACT_IGNORE_DEAD_TARGET) && H.stat == DEAD)
		return FALSE

/datum/action/xeno_action/activable/lunge/ai_should_start_consider()
	return TRUE

/datum/action/xeno_action/activable/lunge/ai_should_use(target)
	if(!iscarbon(target))
		return ..()
	if(get_dist(target, owner) > 2)
		return ..()
	if(!can_use_ability(target, override_flags = XACT_IGNORE_SELECTED_ABILITY))
		return ..()
	return TRUE

/datum/action/xeno_action/activable/lunge/on_cooldown_finish()
	var/mob/living/carbon/xenomorph/X = owner
	to_chat(X, "<span class='notice'>We get ready to lunge again.</span>")
	return ..()

/datum/action/xeno_action/activable/lunge/use_ability(atom/A)
	var/mob/living/carbon/xenomorph/X = owner

	GLOB.round_statistics.warrior_lunges++
	SSblackbox.record_feedback("tally", "round_statistics", 1, "warrior_lunges")
	X.visible_message("<span class='xenowarning'>\The [X] lunges towards [A]!</span>", \
	"<span class='xenowarning'>We lunge at [A]!</span>")

	succeed_activate()
	X.throw_at(get_step_towards(A, X), 6, 2, X)

	if (X.Adjacent(A))
		X.swap_hand()
		X.start_pulling(A, TRUE)
		X.swap_hand()

	add_cooldown()
	return TRUE


// ***************************************
// *********** Fling
// ***************************************
/datum/action/xeno_action/activable/fling
	name = "Fling"
	action_icon_state = "fling"
	mechanics_text = "Knock a target flying up to 5 tiles."
	ability_name = "Fling"
	plasma_cost = 18
	cooldown_timer = 20 SECONDS
	keybind_signal = COMSIG_XENOABILITY_FLING
	target_flags = XABB_MOB_TARGET

/datum/action/xeno_action/activable/fling/on_cooldown_finish()
	to_chat(owner, "<span class='notice'>We gather enough strength to fling something again.</span>")
	return ..()

/datum/action/xeno_action/activable/fling/can_use_ability(atom/A, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE
	if(!A)
		return FALSE
	if(!owner.Adjacent(A))
		return FALSE
	if(!ishuman(A))
		return FALSE
	var/mob/living/carbon/human/H = A
	if(H.stat == DEAD)
		return FALSE

/datum/action/xeno_action/activable/fling/use_ability(atom/A)
	var/mob/living/carbon/xenomorph/X = owner
	var/mob/living/carbon/human/H = A
	GLOB.round_statistics.warrior_flings++
	SSblackbox.record_feedback("tally", "round_statistics", 1, "warrior_flings")

	X.visible_message("<span class='xenowarning'>\The [X] effortlessly flings [H] to the side!</span>", \
	"<span class='xenowarning'>We effortlessly fling [H] to the side!</span>")
	playsound(H,'sound/weapons/alien_claw_block.ogg', 75, 1)
	succeed_activate()
	H.apply_effects(1,1) 	// Stun
	shake_camera(H, 2, 1)

	var/facing = get_dir(X, H)
	var/fling_distance = 4
	var/turf/T = X.loc
	var/turf/temp = X.loc

	for (var/x in 1 to fling_distance)
		temp = get_step(T, facing)
		if (!temp)
			break
		T = temp
	X.do_attack_animation(H, ATTACK_EFFECT_DISARM2)
	H.throw_at(T, fling_distance, 1, X, 1)

	add_cooldown()

/datum/action/xeno_action/activable/fling/ai_should_start_consider()
	return TRUE

/datum/action/xeno_action/activable/fling/ai_should_use(target)
	if(!iscarbon(target))
		return ..()
	if(get_dist(target, owner) > 1)
		return ..()
	if(!can_use_ability(target, override_flags = XACT_IGNORE_SELECTED_ABILITY))
		return ..()
	return TRUE

// ***************************************
// *********** Punch
// ***************************************
/datum/action/xeno_action/activable/punch
	name = "Punch"
	action_icon_state = "punch"
	mechanics_text = "Strike a target up to 1 tile away with a chance to break bones."
	ability_name = "punch"
	plasma_cost = 12
	cooldown_timer = 10 SECONDS
	keybind_signal = COMSIG_XENOABILITY_PUNCH
	target_flags = XABB_MOB_TARGET

/datum/action/xeno_action/activable/punch/on_cooldown_finish()
	var/mob/living/carbon/xenomorph/X = owner
	to_chat(X, "<span class='notice'>We gather enough strength to punch again.</span>")
	return ..()

/datum/action/xeno_action/activable/punch/can_use_ability(atom/A, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE
	if(!isliving(A))
		return FALSE
	if(!owner.Adjacent(A))
		return FALSE
	var/mob/living/L = A
	if(L.stat == DEAD || isnestedhost(L)) //Can't bully the dead/nested hosts.
		return FALSE

/datum/action/xeno_action/activable/punch/use_ability(atom/A)
	var/mob/living/carbon/xenomorph/X = owner
	var/mob/living/M = A
	if(X.issamexenohive(M))
		X.changeNext_move(CLICK_CD_MELEE) // Add a delaay in to avoid spam
		return M.attack_alien(X) //harmless nibbling.

	GLOB.round_statistics.warrior_punches++
	SSblackbox.record_feedback("tally", "round_statistics", 1, "warrior_punches")

	var/S = pick('sound/weapons/punch1.ogg','sound/weapons/punch2.ogg','sound/weapons/punch3.ogg','sound/weapons/punch4.ogg')
	var/target_zone = check_zone(X.zone_selected)
	if(!target_zone)
		target_zone = "chest"
	var/damage = X.xeno_caste.melee_damage
	succeed_activate()
	playsound(M, S, 50, 1)

	M.punch_act(X, damage, target_zone)
	X.do_attack_animation(M, ATTACK_EFFECT_YELLOWPUNCH)
	shake_camera(M, 2, 1)
	step_away(M, X, 2)

	add_cooldown()


/mob/living/proc/punch_act(mob/living/carbon/xenomorph/X, damage, target_zone)
	apply_damage(damage, BRUTE, target_zone, run_armor_check(target_zone))
	UPDATEHEALTH(src)

/mob/living/carbon/human/punch_act(mob/living/carbon/xenomorph/X, damage, target_zone)
	var/datum/limb/L = get_limb(target_zone)

	if (!L || (L.limb_status & LIMB_DESTROYED))
		return

	X.visible_message("<span class='xenowarning'>\The [X] hits [src] in the [L.display_name] with a devastatingly powerful punch!</span>", \
		"<span class='xenowarning'>We hit [src] in the [L.display_name] with a devastatingly powerful punch!</span>", visible_message_flags = COMBAT_MESSAGE)

	if(L.limb_status & LIMB_SPLINTED) //If they have it splinted, the splint won't hold.
		L.remove_limb_flags(LIMB_SPLINTED)
		to_chat(src, "<span class='danger'>The splint on your [L.display_name] comes apart!</span>")

	L.take_damage_limb(damage, 0, FALSE, FALSE, run_armor_check(target_zone))

	adjust_stagger(3)
	add_slowdown(3)

	apply_damage(damage, STAMINA) //Armor penetrating stamina also applies.
	UPDATEHEALTH(src)

/datum/action/xeno_action/activable/punch/ai_should_start_consider()
	return TRUE

/datum/action/xeno_action/activable/punch/ai_should_use(target)
	if(!iscarbon(target))
		return ..()
	if(get_dist(target, owner) > 1)
		return ..()
	if(!can_use_ability(target, override_flags = XACT_IGNORE_SELECTED_ABILITY))
		return ..()
	return TRUE
