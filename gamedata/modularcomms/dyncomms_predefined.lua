return {
	dyntrainer_recon = {
		name = "Recon Trainer",
		chassis = "recon",
		levels = {
			{"commweapon_beamlaser", "health"},
			{"speed", "commweapon_personal_shield"},
			{"commweapon_clusterbomb", "damageBooster", "health"},
			{"speed", "health", "damageBooster"},
			{"speed", "health", "damageBooster"},
		},
		--decorations = {"skin_recon_dark", "banner_overhead"},
		--images = {overhead = "184"}
	},
	dyntrainer_support = {
		name = "Engineer Trainer",
		chassis = "support",
		levels = {
			{"commweapon_lparticlebeam", "radar"},
			{"health", "speed"},
			{"commweapon_hparticlebeam", "personalcloak", "buildpower"},
			{"damageBooster", "range", "range"},
			{"range", "buildpower", "resurrect"},
		},
		--decorations = {"skin_support_hotrod"},
	},
	dyntrainer_assault = {
		name = "Guardian Trainer",
		chassis = "assault",
		levels = {
			{"commweapon_heavymachinegun", "range"},
			{"speed", "health"},
			{"commweapon_riotcannon", "commweapon_personal_shield", "bigHealth"},
			{"damageBooster", "damageBooster", "bigHealth"},
			{"disruptor_ammo","damageBooster", "bigHealth"},
		},
		--decorations = {"banner_overhead"},
		--images = {overhead = "166"}
	},
	dynhub_recon = {
		name = "Recon Support",
		chassis = "recon",
		levels = {
			{"commweapon_shotgun", "radar"},
			{"health", "personalcloak"},
			{"commweapon_disruptorbomb", "disruptor_ammo", "speed"},
			{"speed", "speed", "range"},
			{"speed", "speed", "range"},
		},
	},
	dynhub_support = {
		name = "Engineer Support",
		chassis = "support",
		levels = {
			{"commweapon_lightninggun", "range"},
			{"resurrect", "personalcloak"},
			{"commweapon_multistunner", "buildpower", "flux_amplifier"},
			{"buildpower", "buildpower", "range"},
			{"buildpower", "buildpower", "range"},
		},
	},
	dynhub_assault = {
		name = "Guardian Support",
		chassis = "assault",
		levels = {
			{"commweapon_riotcannon", "range"},
			{"range", "napalm_warhead"},
			{"commweapon_hpartillery", "range", "damageBooster"},
			{"range", "range", "damageBooster"},
			{"range", "range", "damageBooster"},
		},
	},
}