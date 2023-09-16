local mod = GuppysPlaytime

local Settings = {
	Cooldown = {90, 180},
	PounceDistance = 180,
	Damage = 20,
}

local States = {
	Sleeping = 0,
	Idle = 1,
	Moving = 2,
	AttackStart = 3,
	Attacking = 4,
}



function mod:GuppyInit(entity)
	entity.FireCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
	entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
	entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
	entity:GetSprite():Load("gfx/003.088_bumbo.anm2", true)
	entity.State = States.Idle
end
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, mod.GuppyInit, mod.Entities.GuppyFamiliar)

function mod:GuppyUpdate(entity)
	local sprite = entity:GetSprite()
	local player = entity.Player
	local bff = entity.Player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS)


	-- Chilling
	if entity.State == States.Idle then
		entity.Velocity = mod:StopLerp(entity.Velocity)
		mod:LoopingAnim(sprite, "Level4Idle")

		-- Move
		if entity.Coins <= 0 then
			entity.State = States.Moving
			entity.Coins = mod:Random(20, 40)
			entity.TargetPosition = (player.Position - entity.Position):Rotated(mod:Random(-60, 60)):Normalized()
		else
			entity.Coins = entity.Coins - 1
		end

		-- Attack
		if entity.FireCooldown <= 0 then
			entity.State = States.AttackStart
			sprite:Play("Level4Spawn", true)
			entity.FireCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
		else
			entity.FireCooldown = entity.FireCooldown - 1
		end


	-- Moving around
	elseif entity.State == States.Moving then
		entity.Velocity = mod:Lerp(entity.Velocity, entity.TargetPosition:Resized(2), 0.25)
		mod:LoopingAnim(sprite, "Level4Walking")
		mod:FlipTowardsMovement(entity, sprite)

		if entity.Coins <= 0 then
			entity.State = States.Idle
			entity.Coins = mod:Random(30, 60)
		else
			entity.Coins = entity.Coins - 1
		end


	-- Start attacking
	elseif entity.State == States.AttackStart then
		entity.Velocity = mod:StopLerp(entity.Velocity)

		if sprite:IsFinished() then
			entity.State = States.Attacking
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
			entity.CollisionDamage = Settings.Damage

			local size = bff == true and 1.25 or 1
			entity:SetSize(20, Vector(size, size), 12)

			-- Get position to jump to
			entity:PickEnemyTarget(Settings.PounceDistance * 2, 0, 1, Vector.Zero, 0)
			if entity.Target == nil then
				entity.Target = entity.Player
			end

			entity.TargetPosition = entity.Position + (entity.Target.Position - entity.Position):Resized(Settings.PounceDistance)
			entity.TargetPosition = Game():GetRoom():FindFreePickupSpawnPosition(entity.TargetPosition, 0, true, false)
		end

	-- Attacking
	elseif entity.State == States.Attacking then
		if entity.Position:Distance(entity.TargetPosition) < 20 then
			entity.State = States.Idle
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
			entity.CollisionDamage = 4

			local size = bff == true and 1.25 or 1
			entity:SetSize(13, Vector(size, size), 12)

		else
			entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(entity.TargetPosition:Distance(entity.Position) / 6), 0.25)
			mod:FlipTowardsMovement(entity, sprite)
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
			guppy.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
			guppy.CollisionDamage = 4

			local bff = guppy:ToFamiliar().Player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS)
			local size = bff == true and 1.25 or 1
			guppy:SetSize(13, Vector(size, size), 12)
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