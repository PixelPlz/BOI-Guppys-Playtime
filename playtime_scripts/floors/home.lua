local mod = GuppysPlaytime



function mod:EnterHome()
	local level = Game():GetLevel()

	if Isaac.GetChallenge() == mod.ChallengeID and level:GetAbsoluteStage() == LevelStage.STAGE8 then
    	local room = Game():GetRoom()

        -- Keep the door closed + no HUD + no shooting
        mod:ClosetAlwaysActiveStuff()
		mod:CreateAlwaysActiveEffects()

        -- Disable music
		MusicManager():Fadeout(0.01)


        -- Close the door
        local door = room:GetDoor(DoorSlot.DOWN0)
        if door ~= nil then
            door:GetSprite():SetFrame(100)
        end


        -- Spawn the shaking chest
        local spawned = false

        -- Replace the golden chest with the shaking chest
        for i, chest in pairs(Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LOCKEDCHEST, -1, false, false)) do
            Isaac.Spawn(mod.Entities.Type, mod.Entities.ShakingChest, 0, chest.Position, Vector.Zero, nil)
            chest:Remove()
            spawned = true
            break
        end

        if spawned == false then
            Isaac.Spawn(mod.Entities.Type, mod.Entities.ShakingChest, 0, room:GetGridPosition(77), Vector.Zero, nil) -- Hardcoded yippie
        end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.EnterHome)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.EnterHome) -- For that one person that I know is gonna quit during it



-- Shaking Chest (this controls the ending too)
function mod:ShakingChestInit(entity)
	if entity.Variant == mod.Entities.ShakingChest then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
        entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)
        entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

        entity.StateFrame = 20
        entity.I1 = entity.StateFrame
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.ShakingChestInit, mod.Entities.Type)

function mod:ShakingChestUpdate(entity)
	if entity.Variant == mod.Entities.ShakingChest then
        local sprite = entity:GetSprite()

        if not sprite:IsPlaying("Shake") then
            mod:LoopingAnim(sprite, "Idle")
        end


        if entity.StateFrame <= 0 then
            -- Open the door
            if entity.I2 == 6 then
                local door = Game():GetRoom():GetDoor(DoorSlot.DOWN0)
                if door ~= nil then
                    door:GetSprite():Play("Open", true)
                end
                mod:PlaySound(nil, Isaac.GetSoundIdByName("Home Door Open"))

                entity.StateFrame = 35
                entity.I2 = entity.I2 + 1


            -- End the challenge
            elseif entity.I2 >= 7 then
                Game():FinishChallenge()
			    Game():Fadeout(100, 3)


            -- Shake less and less
            else
                sprite:Play("Shake", true)
                mod:PlaySound(entity, SoundEffect.SOUND_CHEST_OPEN, 0.9 - entity.I2 * 0.1, 0.9)

                entity.I1 = math.floor(entity.I1 * 1.4)
                entity.StateFrame = entity.I1
                entity.I2 = entity.I2 + 1
            end

		else
			entity.StateFrame = entity.StateFrame - 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ShakingChestUpdate, mod.Entities.Type)