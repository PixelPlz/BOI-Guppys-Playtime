local mod = GuppysPlaytime



-- Darkness + no HUD + no shooting
function mod:ClosetAlwaysActiveStuff()
	Game():Darken(1, 100)
	--Game():GetHUD():SetVisible(false)

	for i = 1, Game():GetNumPlayers() do
		local player = Isaac.GetPlayer(i)
		if player:Exists() then
			player:SetShootingCooldown(100)
		end
	end
end

function mod:ClosetDarknessUpdate(effect)
	local room = Game():GetRoom()

	if effect:IsFrame(2, 0) then
		mod:ClosetAlwaysActiveStuff()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.ClosetDarknessUpdate, mod.Entities.ClosetDarkness)



-- Mist
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