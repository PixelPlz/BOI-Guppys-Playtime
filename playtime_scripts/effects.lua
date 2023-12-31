local mod = GuppysPlaytime



-- Always active effects
function mod:ClosetAlwaysActiveStuff()
	-- Keep the HUD hidden
	Game():GetHUD():SetVisible(false)

	-- Closet
	if Game():GetLevel():GetAbsoluteStage() ~= LevelStage.STAGE8 then
		-- Darkness
		Game():Darken(1, 20)

		-- Stop players from shooting
		for i = 1, Game():GetNumPlayers() do
			local player = Isaac.GetPlayer(i)
			if player:Exists() then
				player:SetShootingCooldown(100)
			end
		end

	-- Keep the door closed in home
	else
		Game():GetRoom():KeepDoorsClosed()
		MusicManager():Fadeout(0.01)
	end
end

function mod:CreateAlwaysActiveEffects()
	if not mod.ClosetDarkness or not mod.ClosetDarkness:Exists() then
		local darkness = Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.Entities.ClosetDarkness, 0, Vector.Zero, Vector.Zero, nil):ToEffect()
		darkness.Visible = false
		darkness:AddEntityFlags(EntityFlag.FLAG_PERSISTENT)
		mod.ClosetDarkness = darkness
	end
end

function mod:ClosetDarknessUpdate(effect)
	if effect:IsFrame(2, 0) then
		mod:ClosetAlwaysActiveStuff()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.ClosetDarknessUpdate, mod.Entities.ClosetDarkness)



-- Mist
-- Create mist in the room
function mod:CreateMist()
	local room = Game():GetRoom()

	for i = 1, mod:Random(2, 4) do
		local dir = room:GetDecorationSeed() % 2
		local mistSpeed = mod:Random(25, 100) / 100

		local spawnX = mod:Random(room:GetTopLeftPos().X - 400, (room:GetGridWidth() * 40) + 400)
		local spawnY = mod:Random(room:GetTopLeftPos().Y, room:GetBottomRightPos().Y)

		Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.Entities.ClosetMist, 0, Vector(spawnX, spawnY), Vector(mod:GetSign(dir) * mistSpeed, 0), nil):Update()
	end
end

function mod:ClosetMistInit(effect)
	local sprite = effect:GetSprite()

	sprite:Play("Idle")
	sprite:SetFrame(effect.Index % 4)
	sprite.PlaybackSpeed = 0

	sprite.Color = Color(1,1,1, 0.35)
	sprite.FlipX = mod:RandomSign()
	effect.DepthOffset = 10000
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.ClosetMistInit, mod.Entities.ClosetMist)

function mod:ClosetMistUpdate(effect)
	local room = Game():GetRoom()

	-- Replace self with a new one
	if room:IsPositionInRoom(effect.Position, -500) == false then
		local mistSpeed = mod:Random(50, 150) / 100

		local spawnX = room:GetTopLeftPos().X - 490 -- Left
		if effect.Position.X < room:GetCenterPos().X then
			spawnX = room:GetBottomRightPos().X + 490 -- Right
		end

		local spawnY = mod:Random(room:GetTopLeftPos().Y, room:GetBottomRightPos().Y)

		Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.Entities.ClosetMist, 0, Vector(spawnX, spawnY), effect.Velocity:Resized(mistSpeed), nil):Update()
		effect:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.ClosetMistUpdate, mod.Entities.ClosetMist)



-- Hallucination
-- Create a hallucination in the room
function mod:TryCreateHallucination()
	local max = 3
	if mod.Stage:IsStage() then
		max = 2
	end

	if mod:Random(1, max) == 1 then
		local pos = Game():GetRoom():GetRandomPosition(20)
		Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.Entities.Hallucination, 3 - max, pos, Vector.Zero, nil):Update()
	end
end

function mod:HallucinationInit(effect)
	effect:GetSprite().Color = Color(1,1,1, math.min(1, 0.1 + effect.SubType * 0.1))
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.HallucinationInit, mod.Entities.Hallucination)

function mod:HallucinationUpdate(effect)
	local sprite = effect:GetSprite()

	-- Watching
	if effect.State == 0 then
		mod:LoopingAnim(sprite, "Idle")

		-- Disappear if a player gets too close
		local nearest = Game():GetNearestPlayer(effect.Position)
		if nearest.Position:Distance(effect.Position) < 180 then
			effect.State = 1
			sprite:Play("Disappear", true)
			mod:PlaySound(nil, mod.Sounds.HallucinationDisappear, math.min(1, 0.25 + effect.SubType * 0.1))
		end

	-- Disappear
	elseif effect.State == 1 then
		if sprite:IsFinished() then
			effect:Remove()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.HallucinationUpdate, mod.Entities.Hallucination)