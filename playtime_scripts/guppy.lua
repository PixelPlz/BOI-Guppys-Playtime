local mod = GuppysPlaytime

local Settings = {
	Cooldown = 15,
	Damage = 20,
}

local States = {
	Idle = 0,
	Moving = 1,
}



-- Give the player Guppy at the start of the challenge
function mod:PostPlayerInit(player)
	if Isaac.GetChallenge() == mod.ChallengeID and not mod.Stage:IsStage() then
		local player = player:ToPlayer()

		if player and not player:HasCollectible(mod.GuppyItem) then
			player:AddCollectible(mod.GuppyItem, 0, true)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.PostPlayerInit)



function mod:GuppyInit(entity)
	--entity.FireCooldown = Settings.Cooldown -- Fire cooldown is the move cooldown
	entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
	entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
end
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, mod.GuppyInit, mod.Entities.GuppyFamiliar)

function mod:GuppyUpdate(entity)
	local sprite = entity:GetSprite()
	local player = entity.Player
	local bff = entity.Player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS)
	local data = entity:GetData()


	-- Chilling
	if entity.State == States.Idle then
		entity.Velocity = Vector.Zero

		if entity.Coins <= 0 then
			entity.State = States.Moving
			entity.Coins = mod:Random(20, 40)
			entity.TargetPosition = (player.Position - entity.Position):Rotated(mod:Random(-60, 60)):Normalized()
		else
			entity.Coins = entity.Coins - 1
		end


	-- Moving around
	elseif entity.State == States.Moving then
		entity.Velocity = mod:Lerp(entity.Velocity, entity.TargetPosition:Resized(2), 0.25)

		if entity.Coins <= 0 then
			entity.State = States.Idle
			entity.Coins = mod:Random(30, 60)
		else
			entity.Coins = entity.Coins - 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.GuppyUpdate, mod.Entities.GuppyFamiliar)



function mod:GuppyNewRoom()
	for i, guppy in pairs(Isaac.GetRoomEntities()) do
		if guppy.Type == EntityType.ENTITY_FAMILIAR and guppy.Variant == mod.Entities.GuppyFamiliar then
			-- Reset position
			local room = Game():GetRoom()
			local pos = guppy:ToFamiliar().Player.Position
			guppy.Position = room:GetGridPosition(room:GetGridIndex(pos))

			-- Reset state
			guppy:ToFamiliar().State = States.Idle
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.GuppyNewRoom)



function mod:GuppyCheck(player)
	local numFamiliars = player:GetCollectibleNum(mod.GuppyItem) + player:GetEffects():GetCollectibleEffectNum(mod.GuppyItem)
	local config = Isaac.GetItemConfig():GetCollectible(mod.GuppyItem)
	player:CheckFamiliar(mod.Entities.GuppyFamiliar, numFamiliars, player:GetCollectibleRNG(mod.GuppyItem), config)
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.GuppyCheck, CacheFlag.CACHE_FAMILIARS)