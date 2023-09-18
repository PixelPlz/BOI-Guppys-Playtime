local mod = GuppysPlaytime



function mod:SatanShadowInit(entity)
	if entity.Variant == mod.Entities.SatanShadow then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)
        entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

		entity.State = NpcState.STATE_IDLE
		entity:GetSprite().Color = Color(1,1,1, 0)
		entity.ProjectileCooldown = 90

		-- Disable Enhanced Boss Bars bar
		if HPBars then
			HPBars.BossIgnoreList["200.6666"] = true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.SatanShadowInit, mod.Entities.Type)

function mod:SatanShadowUpdate(entity)
	if entity.Variant == mod.Entities.SatanShadow then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()

		local baseParams = ProjectileParams()
		baseParams.Variant = ProjectileVariant.PROJECTILE_HUSH
		baseParams.Scale = 1.35
		baseParams.Color = Color(0,0,0, 1)
		baseParams.FallingSpeedModifier = 1
		baseParams.FallingAccelModifier = -0.1

		local shotSpeedModifier = entity.I2 * 0.2


		-- Heartbeat effect
		if entity.FrameCount > 10 and entity:IsFrame(50 - math.floor(entity.I2 * 3.6), 0) then
			local sound = SoundEffect.SOUND_HEARTBEAT
			local volume = 1 + entity.I2 * 0.2

			if entity.I2 >= 6 then
				sound = SoundEffect.SOUND_HEARTBEAT_FASTER
				volume = volume + 0.3
			end

			mod:PlaySound(nil, sound, volume)
		end


		-- Invisible
		if entity.State == NpcState.STATE_IDLE then
			-- Stay at a point around the player, change this point every 60 frames
			if entity:IsFrame(60, 0) then
				entity.V1 = Vector(mod:Random(7) * 45, 0)
			end
			entity.TargetPosition = target.Position + Vector.FromAngle(entity.V1.X):Resized(100)

			if entity.Position:Distance(entity.TargetPosition) < 20 then
				entity.Velocity = mod:StopLerp(entity.Velocity)
			else
				entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(4.5 + entity.I2 * 0.25), 0.25)
			end

			mod:LoopingAnim(sprite, "Walk")

			if entity.ProjectileCooldown <= 0 then
				-- Go home Isaac...
				if entity.I2 >= 11 then
					Isaac.ExecuteCommand("stage 13") -- This is dumb but whatever
					Game():Fadein(0.0125)
					mod:ResetPlayers()

				-- Fade in
				else
					if entity.I2 == 10 then
						entity.ProjectileCooldown = 45
					else
						entity.ProjectileCooldown = 90 - math.floor(entity.I2 * 4.5)
					end

					entity.State = NpcState.STATE_JUMP
					mod:PlaySound(nil, mod.Sounds.HallucinationDisappear, 0.9)
					entity.I2 = entity.I2 + 1
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Fade in
		elseif entity.State == NpcState.STATE_JUMP then
			entity.Velocity = Vector.Zero
			mod:LoopingAnim(sprite, "Walk")

			if sprite.Color.A >= 0.9 then
				sprite.Color = Color(1,1,1, 1)

				-- Choose attack
				local attack = mod:Random(1, 3)
				entity.State = NpcState.STATE_ATTACK + (attack - 1)
				sprite:Play("Attack0" .. attack, true)

			else
				sprite.Color = Color.Lerp(sprite.Color, Color(1,1,1, 1), 0.13)
			end


		-- Fade out
		elseif entity.State == NpcState.STATE_STOMP then
			entity.Velocity = Vector.Zero
			mod:LoopingAnim(sprite, "Walk")

			if sprite.Color.A <= 0.1 then
				entity.State = NpcState.STATE_IDLE
				sprite.Color = Color(1,1,1, 0)
			else
				sprite.Color = Color.Lerp(sprite.Color, Color(1,1,1, 0), 0.13)
			end


		-- Attack 1
		elseif entity.State == NpcState.STATE_ATTACK then
			entity.Velocity = Vector.Zero

			local params = baseParams
			params.HeightModifier = -15

			if sprite:IsEventTriggered("Shoot") then
				entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(7 + shotSpeedModifier), 4, params)
				mod:PlaySound(entity, SoundEffect.SOUND_SATAN_SPIT, 1.1, 0.95)

			elseif sprite:IsEventTriggered("Shoot2") then
				entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(6 + shotSpeedModifier), 5, params)
				mod:PlaySound(entity, SoundEffect.SOUND_SATAN_SPIT, 1.1, 0.9)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_STOMP
			end


		-- Attack 2
		elseif entity.State == NpcState.STATE_ATTACK2 then
			entity.Velocity = Vector.Zero

			-- Start
			if sprite:IsEventTriggered("Shoot") then
				entity.I1 = 1
				mod:PlaySound(entity, SoundEffect.SOUND_SATAN_RISE_UP, 1.2, 0.95)

			-- Stop
			elseif sprite:IsEventTriggered("Shoot2") then
				entity.I1 = 0
			end

			-- Shooting
			if entity.I1 == 1 and entity:IsFrame(3, 0) then
				local params = baseParams
				params.HeightModifier = -15

				local pos = target.Position
				if target.Velocity:Length() > 0.15 then
					pos = target.Position + target.Velocity * 40
				end
				entity:FireProjectiles(entity.Position, (pos - entity.Position):Resized(7 + shotSpeedModifier), 0, params)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_STOMP
			end


		-- Attack 3
		elseif entity.State == NpcState.STATE_ATTACK3 then
			entity.Velocity = Vector.Zero

			if sprite:IsEventTriggered("Shoot") then
				local params = baseParams
				params.CircleAngle = 0

				for i = -1, 1, 2 do
					local pos = entity.Position + Vector(i * 90, -40)
					entity:FireProjectiles(pos, Vector(6 + shotSpeedModifier, 16), 9, params)
				end
				mod:PlaySound(entity, SoundEffect.SOUND_SATAN_BLAST, 1, 0.95)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_STOMP
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.SatanShadowUpdate, mod.Entities.Type)