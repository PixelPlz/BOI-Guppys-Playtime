local mod = GuppysPlaytime

mod.MonstroRooms = StageAPI.RoomsList("Monstro Boss Rooms", require("resources.luarooms.monstro_rooms"))
mod.ReplacementBoss = StageAPI.RoomsList("Replacement Boss Rooms", require("resources.luarooms.replacement_boss"))



function mod:PostPlayerInit(player)
	if Isaac.GetChallenge() == mod.ChallengeID and not mod.Stage:IsStage() then
		local player = player:ToPlayer()

		-- Give the player Guppy
		if player and not player:HasCollectible(mod.GuppyItem) then
			player:AddCollectible(mod.GuppyItem, 0, true)
		end

		-- Give the player NO!
		if player and not player:HasTrinket(TrinketType.TRINKET_NO, true) then
			player:AddTrinket(TrinketType.TRINKET_NO, true)
			player:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER, UseFlag.USE_NOANIM, -1, 0)
		end
	end
end
mod:AddPriorityCallback(ModCallbacks.MC_POST_PLAYER_INIT, 100, mod.PostPlayerInit)



-- Make some rooms on Basement 2 empty
function mod:NewRoomBasement()
	local level = Game():GetLevel()

	if Isaac.GetChallenge() == mod.ChallengeID and level:GetAbsoluteStage() == LevelStage.STAGE1_2 then
    	local room = Game():GetRoom()

		-- Empty room / treasure room
		if (room:GetType() == RoomType.ROOM_DEFAULT and room:GetDecorationSeed() % 2 == 0) or room:GetType() == RoomType.ROOM_TREASURE then
			MusicManager():VolumeSlide(0.666, 0.01)
			mod:CreateMist()

		-- Normal room
		else
			MusicManager():VolumeSlide(1, 0.01)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.NewRoomBasement)

function mod:RemoveSomeEnemies(Type, Variant, SubType, GridIndex, Seed)
	local level = Game():GetLevel()

	if Isaac.GetChallenge() == mod.ChallengeID and level:GetAbsoluteStage() == LevelStage.STAGE1_2 then
    	local room = Game():GetRoom()

		-- Replace enemies with blood on the floor in empty rooms / treasure rooms
		if (room:GetType() == RoomType.ROOM_DEFAULT and room:GetDecorationSeed() % 2 == 0) or room:GetType() == RoomType.ROOM_TREASURE
		and Type < 1000 and Type ~= EntityType.ENTITY_FIREPLACE then
			return {EntityType.ENTITY_EFFECT - 1, EffectVariant.BLOOD_SPLAT, 0}
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_ROOM_ENTITY_SPAWN, mod.RemoveSomeEnemies)



function mod:EnterBasement()
	local level = Game():GetLevel()
	local stageNum = level:GetAbsoluteStage()

	if Isaac.GetChallenge() == mod.ChallengeID and level:GetAbsoluteStage() <= LevelStage.STAGE1_2 then
		local isEerie = stageNum == 2

		-- Always use the Basement
		if level:GetStageType() ~= StageType.STAGETYPE_ORIGINAL then
			Isaac.ExecuteCommand("stage " .. stageNum) -- This is dumb but whatever
		end

		-- Disable devil rooms
		level:DisableDevilRoom()


		-- Get the boss room for this floor
		local roomsList = level:GetRooms()
		local bossRoom = nil

		for i = 0, #roomsList - 1 do
			local desc = roomsList:Get(i)

			if desc.Data.Type == RoomType.ROOM_BOSS -- Is the boss room
			and ((isEerie == false and desc.Data.Subtype == 1) -- Don't spawn Monstro on the first floor
			or isEerie == true) then -- Always spawn Monstro on the second floor
				bossRoom = desc.SafeGridIndex
				break
			end
		end


		-- Replace boss room
		if bossRoom ~= nil then
			local overwriteDesc = level:GetRoomByIdx(bossRoom)
			local newData = StageAPI.GetGotoDataForTypeShape(RoomType.ROOM_BOSS, RoomShape.ROOMSHAPE_1x1)
			overwriteDesc.Data = newData

			-- Get the list of rooms to use
			local newRooms = nil
			if isEerie == true then
				newRooms = mod.MonstroRooms
			else
				newRooms = mod.ReplacementBoss
			end

			-- Set room data
			local newBossRoom = StageAPI.LevelRoom{
				RoomType = RoomType.ROOM_BOSS,
				RequireRoomType = true,
				RoomsList = newRooms,
				RoomDescriptor = overwriteDesc
			}
			StageAPI.SetLevelRoom(newBossRoom, overwriteDesc.ListIndex)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.EnterBasement)



-- Fake Monstro death
function mod:MonstroRender(entity, offset)
	if not Game():IsPaused() and Isaac.GetChallenge() == mod.ChallengeID and entity:GetSprite():IsPlaying("Death") then
		local sprite = entity:GetSprite()

		-- Fade the music out
		if sprite:GetFrame() == 1 then
			MusicManager():Fadeout(0.01)

		-- Change floor
		elseif sprite:GetFrame() == 75 then
			StageAPI.GotoCustomStage(mod.Stage, false)
			Game():Fadein(0.0125)
			mod:ResetPlayers()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.MonstroRender, EntityType.ENTITY_MONSTRO)