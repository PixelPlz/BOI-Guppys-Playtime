local mod = GuppysPlaytime



-- Create the custom stage entry
mod.Stage = StageAPI.CustomStage("The Closet")
mod.Stage:SetDisplayName("???")
mod.Stage:SetReplace(StageAPI.StageOverride.CatacombsOne)
mod.Stage:SetLevelgenStage(LevelStage.STAGE1_1, StageType.STAGETYPE_WOTL)
mod.Stage:SetStageNumber(LevelStage.STAGE3_1, LevelStage.STAGE3_1)
mod.Stage.IsSecondStage = false



-- Set stage skins
mod.StageGrids = StageAPI.GridGfx()

-- Rocks / decorations
mod.StageGrids:SetRocks("gfx/grid/rocks_closet.png")
mod.StageGrids:SetDecorations("gfx/grid/props_0ex_isaacs_bedroom.png", "gfx/grid/props_0ex_isaacs_bedroom.anm2")

-- VS screen spots
mod.Stage:SetSpots("gfx/ui/boss/bossspot_11_darkroom.png", "gfx/ui/boss/playerspot_11_darkroom.png")



-- Set the stage backdrop
mod.ClosetBackdrop = StageAPI.BackdropHelper({
    Walls = {"1", "2"},
    --NFloors = {"nfloor"},
    LFloors = {"lfloor"},
    Corners = {"corner"}
}, "gfx/backdrop/closet/closet_", ".png")

mod.StageGfx = StageAPI.RoomGfx(mod.ClosetBackdrop, mod.StageGrids, "_default", "stageapi/shading/shading")
mod.Stage:SetRoomGfx(mod.StageGfx, {RoomType.ROOM_DEFAULT, RoomType.ROOM_BOSS})



-- Secret room backdrop
mod.SecretBackdrop = StageAPI.BackdropHelper({
    Walls = {"1", "2"},
    --NFloors = {"nfloor"},
    --LFloors = {"lfloor"},
    --Corners = {"corner"}
}, "gfx/backdrop/closet/closet_secret_", ".png")

mod.SecretGfx = StageAPI.RoomGfx(mod.SecretBackdrop, mod.StageGrids, "_default", "stageapi/shading/shading")
mod.Stage:SetRoomGfx(mod.SecretGfx, {RoomType.ROOM_SECRET})




-- Set the music
mod.Stage:SetStageMusic(Music.MUSIC_DARK_CLOSET)
mod.Stage:SetBossMusic(Music.MUSIC_MINESHAFT_ESCAPE, Music.MUSIC_BOSS_OVER, Music.MUSIC_JINGLE_BOSS, Music.MUSIC_JINGLE_BOSS_OVER3)



-- Set floor generation stuff
mod.Stage:SetRequireRoomTypeMatching(true)
mod.Stage:SetPregenerationEnabled(true)

-- Room layouts
mod.Stage:SetRooms({
	[RoomType.ROOM_DEFAULT] = mod.ClosetRooms,
	[RoomType.ROOM_SECRET]  = mod.ClosetRooms,
})



-- Set the boss
mod.StageAPIBosses = {
	SatanShadow = StageAPI.AddBossData("Satan's Shadow", {
		Name = "Satan's Shadow",
		Portrait = "gfx/ui/boss/portrait_84.0_satan.png",
		Bossname = "gfx/ui/boss/bossname_84.0_satan.png",
		Rooms = mod.SatanCloset,
		Entity = {Type = mod.Entities.Type, Variant = mod.Entities.SatanShadow},
		Offset = Vector(8, -16),
	}),
}

mod.StageBosses = {
	"Satan's Shadow",
}
mod.Stage:SetBosses(mod.StageBosses, true)



-- Override skull drops
mod.Stage:OverrideRockAltEffects({RoomType.ROOM_DEFAULT, RoomType.ROOM_BOSS, RoomType.ROOM_SECRET})

StageAPI.AddCallback("The Closet", "POST_OVERRIDDEN_ALT_ROCK_BREAK", 1, function(gridpos, gridvar, shroomData, customGrid)
    if mod.Stage:IsStage() then
		SFXManager():Stop(SoundEffect.SOUND_MUSHROOM_POOF_2)
        SFXManager():Play(SoundEffect.SOUND_ROCK_CRUMBLE)

		if shroomData then
			for _, spawn in ipairs(shroomData) do
				-- Black heart
				if spawn.Type == EntityType.ENTITY_PICKUP and spawn.Variant == PickupVariant.PICKUP_COLLECTIBLE then
					Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_BLACK, gridpos, Vector.Zero, nil)
					break
				end

				-- Bone heart
				if spawn.Type == EntityType.ENTITY_PICKUP and spawn.Variant == PickupVariant.PICKUP_PILL then
					Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_BONE, gridpos, Vector.Zero, nil)
					break
				end

				-- Bony
				if spawn.Type == EntityType.ENTITY_EFFECT and spawn.Variant == EffectVariant.FART then
					Isaac.Spawn(EntityType.ENTITY_BONY, 0, 0, gridpos, Vector.Zero, nil)
					break
				end
			end
		end
    end
end)






-- Prevent these room types from appearing
mod.RoomTypeBlacklist = {
	RoomType.ROOM_SHOP, RoomType.ROOM_TREASURE, RoomType.ROOM_MINIBOSS, RoomType.ROOM_SUPERSECRET, RoomType.ROOM_ARCADE, RoomType.ROOM_CURSE, RoomType.ROOM_CHALLENGE,
	RoomType.ROOM_LIBRARY, RoomType.ROOM_SACRIFICE, RoomType.ROOM_ISAACS, RoomType.ROOM_BARREN, RoomType.ROOM_CHEST, RoomType.ROOM_DICE, RoomType.ROOM_PLANETARIUM,
}

function mod:EnterCloset()
	if mod.Stage:IsStage() then
		local level = Game():GetLevel()

		-- Disable devil rooms
		level:DisableDevilRoom()

		-- Darkness + no HUD + no shooting
		mod:CreateAlwaysActiveEffects()


		-- Get rooms to replace
		local roomsList = level:GetRooms()
		local roomsToReplace = {}
		local IIVroomsToReplace = {}
		local IIHroomsToReplace = {}

		for i = 0, #roomsList - 1 do
			local desc = roomsList:Get(i)
			local shape = desc.Data.Shape

			-- Small rooms
			if shape == RoomShape.ROOMSHAPE_IH or shape == RoomShape.ROOMSHAPE_IV then
				table.insert(roomsToReplace, desc.SafeGridIndex)

			-- IIV rooms
			elseif shape == RoomShape.ROOMSHAPE_IIV then
				table.insert(IIVroomsToReplace, desc.SafeGridIndex)

			-- IIH rooms
			elseif shape == RoomShape.ROOMSHAPE_IIH then
				table.insert(IIHroomsToReplace, desc.SafeGridIndex)

			-- Blacklisted room types
			else
				for j, entry in pairs(mod.RoomTypeBlacklist) do
					if desc.Data.Type == entry then
						table.insert(roomsToReplace, desc.SafeGridIndex)
						break
					end
				end
			end
		end


		-- Replace rooms
		for i = 0, 2 do
			local table = roomsToReplace
			local shape = RoomShape.ROOMSHAPE_1x1

			if i == 1 then
				table = IIVroomsToReplace
				shape = RoomShape.ROOMSHAPE_1x2
			elseif i == 2 then
				table = IIHroomsToReplace
				shape = RoomShape.ROOMSHAPE_2x1
			end

			-- New room data
			for j, room in pairs(table) do
				local overwriteDesc = level:GetRoomByIdx(room)
				local newData = StageAPI.GetGotoDataForTypeShape(RoomType.ROOM_DEFAULT, shape)
				overwriteDesc.Data = newData

				-- Set room data
				local newRoom = StageAPI.LevelRoom{
					RoomType = RoomType.ROOM_DEFAULT,
					RequireRoomType = true,
					RoomsList = mod.ClosetRooms,
					RoomDescriptor = overwriteDesc
				}
				StageAPI.SetLevelRoom(newRoom, overwriteDesc.ListIndex)
			end
		end

		-- Update the minimap
		level:UpdateVisibility()


		-- Add stitched eyes costume
		for i = 1, Game():GetNumPlayers() do
			local player = Isaac.GetPlayer(i)
			if player:Exists() then
				player:AddNullCostume (mod.StitchedEyesCostume)
			end
		end
	end
end
mod:AddPriorityCallback(ModCallbacks.MC_POST_NEW_LEVEL, CallbackPriority.EARLY, mod.EnterCloset)



function mod:NewRoomCloset()
	if mod.Stage:IsStage() then
		local level = Game():GetLevel()
		local room = Game():GetRoom()

		-- Darkness + no HUD + no shooting
		mod:CreateAlwaysActiveEffects()

		-- Create mist
		mod:CreateMist()


		-- Update doors
		for grindex = 0, room:GetGridSize() - 1 do
			local grid = room:GetGridEntity(grindex)

			if grid ~= nil and grid:GetType() == GridEntityType.GRID_DOOR then
				local door = grid:ToDoor()

				if door.TargetRoomType ~= RoomType.ROOM_SECRET and door.TargetRoomType ~= RoomType.ROOM_BOSS and door.CurrentRoomType == RoomType.ROOM_DEFAULT then
					door:SetRoomTypes(door.CurrentRoomType, RoomType.ROOM_DEFAULT) -- For curse rooms mainly

					grid:GetSprite():Load("gfx/grid/door_closet.anm2", true)
					grid:GetSprite():Play("Opened", true)

					door:Open()
					door:TryBlowOpen(false, nil) -- For rooms that were super secret rooms
				end
			end
		end


		-- Spawn dead Guppy
		if level:GetCurrentRoomIndex() == level:GetStartingRoomIndex() then
			Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.Entities.DeadGuppy, 0, room:GetGridPosition(81), Vector.Zero, nil)
		end


		-- Improved Backdrops fix for boss room
		if ImprovedBackdrops and room:GetType() == RoomType.ROOM_BOSS then
			Game():ShowHallucination(0, BackdropType.DARK_CLOSET)
			SFXManager():Stop(SoundEffect.SOUND_DEATH_CARD)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.NewRoomCloset)