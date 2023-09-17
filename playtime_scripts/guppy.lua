local mod = GuppysPlaytime

local Settings = {
	MoveSpeed = 2.5,

	IdleSize = 16,
	PounceSize = 24,

	IdleDamage = 4,
	PounceDamage = 20,

	Cooldown = {90, 180},
	PounceDistance = 180,
	Gravity = 1,
	JumpStrength = 7,
	LandHeight = 0,
}

local States = {
	Idle = 0,
	Moving = 1,
	Meowing = 2,
	AttackStart = 3,
	Attacking = 4,
}



function mod:GuppyInit(entity)
	entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
	entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

	entity.FireCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
	entity.Hearts = mod:Random(100, 200)
end
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, mod.GuppyInit, mod.Entities.GuppyFamiliar)

function mod:GuppyUpdate(entity)
	local sprite = entity:GetSprite()
	local player = entity.Player
	local bff = entity.Player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS)


	-- Chilling
	if entity.State == States.Idle then
		entity.Velocity = mod:StopLerp(entity.Velocity)
		mod:LoopingAnim(sprite, "Idle")

		-- Meow :3
		if entity.Hearts <= 0 then
			entity.State = States.Meowing
			sprite:Play("Meow", true)
			entity.Hearts = mod:Random(100, 200)
		else
			entity.Hearts = entity.Hearts - 1
		end

		-- Move
		if entity.Coins <= 0 then
			entity.State = States.Moving
			entity.Coins = mod:Random(30, 60)
			entity.Keys = mod:Random(20, 40) -- Move time
			entity.TargetPosition = (player.Position - entity.Position):Rotated(mod:Random(-60, 60)):Normalized()
		else
			entity.Coins = entity.Coins - 1
		end

		-- Attack
		if entity.FireCooldown <= 0 then
			entity.State = States.AttackStart
			sprite:Play("PouncePrepare", true)
			entity.FireCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
		else
			entity.FireCooldown = entity.FireCooldown - 1
		end


	-- Moving around
	elseif entity.State == States.Moving then
		entity.Velocity = mod:Lerp(entity.Velocity, entity.TargetPosition:Resized(Settings.MoveSpeed), 0.25)
		mod:LoopingAnim(sprite, "Walk")
		mod:FlipTowardsMovement(entity, sprite)

		if entity.Keys <= 0 then
			entity.State = States.Idle
		else
			entity.Keys = entity.Keys - 1
		end


	-- Meowing :3
	elseif entity.State == States.Meowing then
		entity.Velocity = mod:StopLerp(entity.Velocity)

		if sprite:IsEventTriggered("Meow") then
			mod:PlaySound(nil, mod.Sounds.GuppyMeow, 2.5, 1 + mod:Random(-10, 10) / 100)
		end
		if sprite:IsFinished() then
			entity.State = States.Idle
		end


	-- Start attacking
	elseif entity.State == States.AttackStart then
		entity.Velocity = mod:StopLerp(entity.Velocity)

		if sprite:IsFinished() then
			entity.State = States.Attacking
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
			entity.CollisionDamage = Settings.PounceDamage
			mod:PlaySound(nil, mod.Sounds.GuppyPounce, 1.25)

			-- Set size
			local size = bff == true and 1.25 or 1
			entity:SetSize(Settings.PounceSize, Vector(size, size), 12)

			-- Get position to jump to
			entity:PickEnemyTarget(Settings.PounceDistance * 2, 0, 1, Vector.Zero, 0)
			if entity.Target == nil then
				entity.Target = entity.Player
			end

			entity.TargetPosition = entity.Position + (entity.Target.Position - entity.Position):Resized(Settings.PounceDistance)
			entity.TargetPosition = Game():GetRoom():FindFreePickupSpawnPosition(entity.TargetPosition, 0, true, false)

			-- Jump
			entity.OrbitDistance = Vector(0, Settings.JumpStrength)
		end

	-- Attacking
	elseif entity.State == States.Attacking then
		mod:LoopingAnim(sprite, "PounceAir")

		-- Update height
		entity.OrbitDistance = Vector(0, entity.OrbitDistance.Y - Settings.Gravity)
		entity.PositionOffset = Vector(0, math.min(Settings.LandHeight, entity.PositionOffset.Y - entity.OrbitDistance.Y))

		-- Land
		if entity.Position:Distance(entity.TargetPosition) < 20 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if entity.PositionOffset.Y >= Settings.LandHeight then
				entity.State = States.Idle
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
				entity.CollisionDamage = Settings.IdleDamage
				entity.PositionOffset = Vector.Zero

				-- Set size
				local size = bff == true and 1.25 or 1
				entity:SetSize(Settings.IdleSize, Vector(size, size), 12)
			end

		-- Move to position
		else
			entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(entity.TargetPosition:Distance(entity.Position) / 7.5), 0.25)
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
			guppy.Velocity = Vector.Zero

			-- Reset state
			guppy:ToFamiliar().State = States.Idle
			guppy.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
			guppy.CollisionDamage = Settings.IdleDamage
			guppy.PositionOffset = Vector.Zero

			local bff = guppy:ToFamiliar().Player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS)
			local size = bff == true and 1.25 or 1
			guppy:SetSize(Settings.IdleSize, Vector(size, size), 12)
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