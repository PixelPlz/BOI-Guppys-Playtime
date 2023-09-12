local mod = GuppysPlaytime

mod.MonstroRooms = StageAPI.RoomsList("Monstro Boss Rooms", require("resources.luarooms.monstro_rooms"))
mod.ReplacementBoss = StageAPI.RoomsList("Replacement Boss Rooms", require("resources.luarooms.replacement_boss"))



function mod:NewRoomBasement()
	local level = Game():GetLevel()

	if Isaac.GetChallenge() == mod.ChallengeID and level:GetAbsoluteStage() == LevelStage.STAGE1_2 then
    	local room = Game():GetRoom()

		-- Empty room
		if room:GetType() == RoomType.ROOM_DEFAULT and room:GetDecorationSeed() % 2 == 0 then
			MusicManager():VolumeSlide(0.666, 0.01)

			-- Create mist
			for i = 1, mod:Random(2, 4) do
				local dir = room:GetDecorationSeed() % 2
				local mistSpeed = mod:Random(25, 100) / 100

				local spawnX = mod:Random(room:GetTopLeftPos().X - 400, (room:GetGridWidth() * 40) + 400)
				local spawnY = mod:Random(room:GetTopLeftPos().Y, room:GetBottomRightPos().Y)

				Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.Entities.ClosetMist, 0, Vector(spawnX, spawnY), Vector(mod:GetSign(dir) * mistSpeed, 0), nil):Update()
			end

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

		-- Replace enemies with blood on the floor in empty rooms
		if room:GetType() == RoomType.ROOM_DEFAULT and room:GetDecorationSeed() % 2 == 0
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
			or (isEerie == true and desc.Data.Subtype ~= 1)) then -- Always spawn Monstro on the second floor
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

			print("BOSS ROOM REPLACED")

		else
			print("Boss room replacement not required :D")
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.EnterBasement)



-- Replace these with a render callback
function mod:monstroPreDeath(entity)
	if entity:HasMortalDamage() or entity:IsDead() then
		MusicManager():Fadeout(0.01)

		--Game():FinishChallenge()
		--Game():Fadeout(100, 3)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.monstroPreDeath, EntityType.ENTITY_MONSTRO)

function mod:monstroDeath(entity)
	StageAPI.GotoCustomStage(mod.Stage, false)
	Game():Fadein(0.0125)


	-- Reset players
	for i = 1, Game():GetNumPlayers() do
		local player = Isaac.GetPlayer(i)

		if player:Exists() then
			player:AnimateAppear()
			player:AddControlsCooldown(160)
			player.Velocity = Vector.Zero


			-- Remove all items
			local maxID = Isaac.GetItemConfig():GetCollectibles().Size - 1
			for id = 1, maxID do
				if ItemConfig.Config.IsValidCollectible(id) then
					player:RemoveCollectible(id, false, ActiveSlot.SLOT_PRIMARY, true)
				end
			end


			-- Remove all trinkets
			maxID = Isaac.GetItemConfig():GetTrinkets().Size - 1
			for id = 1, maxID do
				if ItemConfig.Config.IsValidCollectible(id) then
					player:TryRemoveTrinket(id)
				end
			end


			-- Set health to 3 red hearts
			player:AddMaxHearts((player:GetMaxHearts() - 6) * -1, false)
			player:AddSoulHearts(-player:GetSoulHearts())
			player:AddEternalHearts(-player:GetEternalHearts())
			player:AddBlackHearts(-player:GetBlackHearts())
			player:AddGoldenHearts(-player:GetGoldenHearts())
			player:AddBoneHearts(-player:GetBoneHearts())
			player:AddRottenHearts(-player:GetRottenHearts())
			player:AddBrokenHearts(-player:GetBrokenHearts())


			-- Remove all bombs except for one
			local bombNum = (player:GetNumBombs() - 1) * -1
			if bombNum < 0 then
				player:AddBombs(bombNum)
			end


			-- Reset other collectibles
			player:AddCoins(-player:GetNumCoins())
			player:AddKeys(-player:GetNumKeys())

			for j = 0, 1 do
				player:SetCard(j, Card.CARD_NULL)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.monstroDeath, EntityType.ENTITY_MONSTRO)