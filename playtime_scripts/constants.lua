local mod = GuppysPlaytime

mod.RNG = RNG()

mod.ChallengeID = Isaac.GetChallengeIdByName("Guppy's Playtime")
mod.GuppyItem   = Isaac.GetItemIdByName("Playtime Guppy")



--[[ New entity enums ]]--
mod.Entities = {
	-- Familiars
	GuppyFamiliar = Isaac.GetEntityVariantByName("Guppy Familiar"),

	-- Enemies
	Type = 200,
	SadSatan = Isaac.GetEntityVariantByName("Sad Satan"),

	-- Effects
	ClosetDarkness = Isaac.GetEntityVariantByName("Closet Darkness"),
	ClosetMist     = Isaac.GetEntityVariantByName("Closet Mist"),
}