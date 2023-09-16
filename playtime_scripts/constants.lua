local mod = GuppysPlaytime

mod.RNG = RNG()

mod.ChallengeID = Isaac.GetChallengeIdByName("Guppy's Playtime")
mod.GuppyItem   = Isaac.GetItemIdByName("Playtime Guppy")



--[[ New entity enums ]]--
mod.Entities = {
	-- Familiars
	GuppyFamiliar = Isaac.GetEntityVariantByName("Guppy Familiar"),

	-- NPCs
	Type = 200,
	SatanShadow  = Isaac.GetEntityVariantByName("Satan's Shadow"),
	ShakingChest = Isaac.GetEntityVariantByName("Shaking Chest"),

	-- Effects
	ClosetDarkness = Isaac.GetEntityVariantByName("Closet Darkness"),
	ClosetMist     = Isaac.GetEntityVariantByName("Closet Mist"),
}