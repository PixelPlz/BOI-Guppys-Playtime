local mod = GuppysPlaytime



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

		-- Spawn hallucinations
		mod:TryCreateHallucination()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.NewRoomBasement)

function mod:RemoveSomeEnemies(Type, Variant, SubType, GridIndex, Seed)
	local level = Game():GetLevel()

	if Isaac.GetChallenge() == mod.ChallengeID and level:GetAbsoluteStage() == LevelStage.STAGE1_2 then
    	local room = Game():GetRoom()

		-- Replace enemies with blood on the floor in empty rooms / treasure rooms
		if ((room:GetType() == RoomType.ROOM_DEFAULT and room:GetDecorationSeed() % 2 == 0) or room:GetType() == RoomType.ROOM_TREASURE)
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
		-- Always use the Basement
		if level:GetStageType() ~= StageType.STAGETYPE_ORIGINAL then
			Isaac.ExecuteCommand("stage " .. stageNum) -- This is dumb but whatever
		end

		-- Force Famine as the first boss
		level:ForceHorsemanBoss(1)


		-- Replace the second floor boss with fake Monstro
		local roomsList = level:GetRooms()

		for i = 0, #roomsList - 1 do
			local desc = roomsList:Get(i)

			if desc.Data.Type == RoomType.ROOM_BOSS and stageNum == 2 then
				local overwriteDesc = level:GetRoomByIdx(desc.SafeGridIndex)
				local newData = StageAPI.GetGotoDataForTypeShape(RoomType.ROOM_BOSS, RoomShape.ROOMSHAPE_1x1)
				overwriteDesc.Data = newData

				-- Set room data
				local newBossRoom = StageAPI.LevelRoom{
					RoomType = RoomType.ROOM_BOSS,
					RequireRoomType = true,
					RoomsList = mod.MonstroRooms,
					RoomDescriptor = overwriteDesc
				}
				StageAPI.SetLevelRoom(newBossRoom, overwriteDesc.ListIndex)

				break
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.EnterBasement)



-- Fake Monstro death
function mod:MonstroInit(entity)
	if Isaac.GetChallenge() == mod.ChallengeID and entity.SubType == 1000 then
		entity:GetSprite():Load("gfx/fake monstro.anm2", true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.MonstroInit, EntityType.ENTITY_MONSTRO)

function mod:MonstroRender(entity, offset)
	if not Game():IsPaused() and Isaac.GetChallenge() == mod.ChallengeID and entity.SubType == 1000 and entity:GetSprite():IsPlaying("Death") then
		local sprite = entity:GetSprite()

		-- Fade the music out
		if sprite:IsEventTriggered("BloodStart") then
			MusicManager():Fadeout(0.01)

		-- Land sound
		elseif sprite:IsEventTriggered("Land") and not entity:GetData().impactSound then
			mod:PlaySound(entity, mod.Sounds.CardboardImpact, 2)
			entity:GetData().impactSound = true

		-- Change floor
		elseif sprite:IsEventTriggered("Shoot") then
			StageAPI.GotoCustomStage(mod.Stage, false)
			Game():Fadein(0.0125)
			mod:ResetPlayers()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.MonstroRender, EntityType.ENTITY_MONSTRO)