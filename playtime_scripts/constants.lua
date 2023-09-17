local mod = GuppysPlaytime

mod.RNG = RNG()

mod.ChallengeID = Isaac.GetChallengeIdByName("Guppy's Playtime")
mod.GuppyItem = Isaac.GetItemIdByName("Playtime Guppy")
mod.StitchedEyesCostume = Isaac.GetCostumeIdByPath("gfx/characters/stitched eyes.anm2")



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
	DeadGuppy      = Isaac.GetEntityVariantByName("Dead Guppy"),
}



--[[ New sound enums ]]--
mod.Sounds = {
	-- Guppy
	GuppyMeow 	= Isaac.GetSoundIdByName("Guppy Meow"),
	GuppyPounce = Isaac.GetSoundIdByName("Guppy Pounce"),

	-- Fake Monstro
	CardboardImpact = Isaac.GetSoundIdByName("Cardboard Impact"),

	-- Home cutscene
	DoorOpen = Isaac.GetSoundIdByName("Home Door Open"),
}



--[[ Room lists ]]--
mod.ReplacementBoss = StageAPI.RoomsList("Replacement Boss Rooms", require("resources.luarooms.replacement_boss"))
mod.MonstroRooms 	= StageAPI.RoomsList("Monstro Boss Rooms",     require("resources.luarooms.monstro_rooms"))
mod.ClosetRooms 	= StageAPI.RoomsList("Closet Rooms", 		   require("resources.luarooms.closet_rooms"))
mod.SatanCloset 	= StageAPI.RoomsList("Satan's Closet", 		   require("resources.luarooms.closet_satan"))