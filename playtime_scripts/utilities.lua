local mod = GuppysPlaytime



--[[ Utility functions ]]--
-- Lerp
function mod:Lerp(first, second, percent)
	return (first + (second - first) * percent)
end

-- Lerp to Vector.Zero
function mod:StopLerp(vector)
	return mod:Lerp(vector, Vector.Zero, 0.25)
end


-- Replaces math.random 
function mod:Random(min, max, rng)
	rng = rng or mod.RNG

	-- Float
	if not min and not max then
		return rng:RandomFloat()

	-- Integer
	elseif min and not max then
		return rng:RandomInt(min + 1)

	-- Range
	else
		local difference = math.abs(min)

		-- For ranges with negative numbers
		if min < 0 then
			max = max + difference
			return rng:RandomInt(max + 1) - difference
		-- For positive only
		else
			max = max - difference
			return rng:RandomInt(max + 1) + difference
		end
	end
end


-- Get a random sign
function mod:RandomSign()
	if mod:Random(1) == 0 then
		return -1
	else
		return 1
	end
end

-- Get sign from 1 or 0 / true or false
function mod:GetSign(value)
	if (type(value) == "number" and value == 1) or (type(value) == "boolean" and value == true) then
		return 1
	else
		return -1
	end
end


-- Better sound function
function mod:PlaySound(entity, id, volume, pitch, cooldown, loop, pan)
	volume = volume or 1
	pitch = pitch or 1
	cooldown = cooldown or 0
	pan = pan or 0

	if entity then
		entity:ToNPC():PlaySound(id, volume, cooldown, loop, pitch)
	else
		SFXManager():Play(id, volume, cooldown, loop, pitch, pan)
	end
end



--[[ Sprite functions ]]--
-- Looping animation
function mod:LoopingAnim(sprite, anim)
	if not sprite:IsPlaying(anim) then
		sprite:Play(anim, true)
	end
end


-- Flip towards the entity's movement
function mod:FlipTowardsMovement(entity, sprite, otherWay)
	if (otherWay == true and entity.Velocity.X > 0) or (otherWay ~= true and entity.Velocity.X < 0) then
		sprite.FlipX = true
	else
		sprite.FlipX = false
	end
end



--[[ Misc. functions ]]--
-- Reset all player
function mod:ResetPlayers()
	local isHome = Game():GetLevel():GetAbsoluteStage() == LevelStage.STAGE8

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
			player:SetFullHearts()

			player:AddSoulHearts(-player:GetSoulHearts())
			player:AddEternalHearts(-player:GetEternalHearts())
			player:AddBlackHearts(-player:GetBlackHearts())
			player:AddGoldenHearts(-player:GetGoldenHearts())
			player:AddBoneHearts(-player:GetBoneHearts())
			player:AddRottenHearts(-player:GetRottenHearts())
			player:AddBrokenHearts(-player:GetBrokenHearts())


			-- Remove all bombs except for one
			if isHome == false then
				local bombNum = (player:GetNumBombs() - 1) * -1
				if bombNum < 0 then
					player:AddBombs(bombNum)
				end

			-- Remove all bombs when going home
			else
				player:AddBombs(-player:GetNumBombs())
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