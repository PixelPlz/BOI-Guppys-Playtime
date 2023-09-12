local mod = GuppysPlaytime



-- Create the custom stage entry
mod.Stage = StageAPI.CustomStage("The Closet")
mod.Stage:SetDisplayName("???")
mod.Stage:SetReplace(StageAPI.StageOverride.CatacombsOne)
mod.Stage:SetLevelgenStage(LevelStage.STAGE1_1, StageType.STAGETYPE_WOTL)
mod.Stage:SetStageNumber(LevelStage.STAGE3_1, LevelStage.STAGE3_1)
mod.Stage.IsSecondStage = false



-- Set stage skins
mod.StageGrids = StageAPI.GridGfx()

-- Rocks / decorations
mod.StageGrids:SetRocks("gfx/grid/rocks_mausoleum.png")
mod.StageGrids:SetDecorations("gfx/grid/props_0ex_isaacs_bedroom.png", "gfx/grid/props_0ex_isaacs_bedroom.anm2")



-- Set the stage backdrop
mod.ClosetBackdrop = StageAPI.BackdropHelper({
    Walls = {"1", "2"},
    --NFloors = {"nfloor"},
    LFloors = {"lfloor"},
    Corners = {"corner"}
}, "gfx/backdrop/closet/closet_", ".png")

mod.StageGfx = StageAPI.RoomGfx(mod.ClosetBackdrop, mod.StageGrids, "_default", "stageapi/shading/shading")
mod.Stage:SetRoomGfx(mod.StageGfx, {RoomType.ROOM_DEFAULT, RoomType.ROOM_BOSS})



-- Secret room backdrop
mod.SecretBackdrop = StageAPI.BackdropHelper({
    Walls = {"1", "2"},
    --NFloors = {"nfloor"},
    --LFloors = {"lfloor"},
    --Corners = {"corner"}
}, "gfx/backdrop/closet/closet_secret_", ".png")

mod.SecretGfx = StageAPI.RoomGfx(mod.SecretBackdrop, mod.StageGrids, "_default", "stageapi/shading/shading")
mod.Stage:SetRoomGfx(mod.SecretGfx, {RoomType.ROOM_SECRET})



-- Set the music
mod.Stage:SetStageMusic(Music.MUSIC_DARK_CLOSET)
mod.Stage:SetBossMusic(Music.MUSIC_MINESHAFT_ESCAPE, Music.MUSIC_BOSS_OVER, Music.MUSIC_JINGLE_BOSS, Music.MUSIC_JINGLE_BOSS_OVER3)



-- Set floor generation stuff
mod.Stage:SetRequireRoomTypeMatching(true)
mod.Stage:SetPregenerationEnabled(true)
--mod.Stage:SetBosses(mod.StageBosses, true)


-- Room layouts
mod.ClosetRooms = StageAPI.RoomsList("Closet Rooms", require("resources.luarooms.closet_rooms"))
mod.SecretRooms = StageAPI.RoomsList("Closet Secret Rooms", require("resources.luarooms.secret_rooms"))

mod.Stage:SetRooms({
	[RoomType.ROOM_DEFAULT] = mod.ClosetRooms,
	[RoomType.ROOM_SECRET]  = mod.SecretRooms,
})






-- Prevent these room types from appearing
mod.RoomTypeBlacklist = {
	RoomType.ROOM_SHOP, RoomType.ROOM_TREASURE, RoomType.ROOM_MINIBOSS, RoomType.ROOM_SUPERSECRET, RoomType.ROOM_ARCADE, RoomType.ROOM_CURSE, RoomType.ROOM_CHALLENGE,
	RoomType.ROOM_LIBRARY, RoomType.ROOM_SACRIFICE, RoomType.ROOM_ISAACS, RoomType.ROOM_BARREN, RoomType.ROOM_CHEST, RoomType.ROOM_DICE, RoomType.ROOM_PLANETARIUM,
}

function mod:EnterCloset()
	if mod.Stage:IsStage() then
		local level = Game():GetLevel()

		-- Disable devil rooms
		level:DisableDevilRoom()

		-- Darkness + no HUD + no shooting
		mod:ClosetAlwaysActiveStuff()


		-- Replace rooms
		local roomsList = level:GetRooms()
		local roomsToReplace = {}
		local IIVroomsToReplace = {}
		local IIHroomsToReplace = {}

		for i = 0, #roomsList - 1 do
			local desc = roomsList:Get(i)
			local shape = desc.Data.Shape

			-- Small rooms
			if shape == RoomShape.ROOMSHAPE_IH or shape == RoomShape.ROOMSHAPE_IV then
				table.insert(roomsToReplace, desc.SafeGridIndex)

			-- IIV rooms
			elseif shape == RoomShape.ROOMSHAPE_IIV then
				table.insert(IIVroomsToReplace, desc.SafeGridIndex)

			-- IIH rooms
			elseif shape == RoomShape.ROOMSHAPE_IIH then
				table.insert(IIHroomsToReplace, desc.SafeGridIndex)

			-- Blacklisted room types
			else
				for j, entry in pairs(mod.RoomTypeBlacklist) do
					if desc.Data.Type == entry then
						table.insert(roomsToReplace, desc.SafeGridIndex)
						break
					end
				end
			end
		end


		for i = 0, 2 do
			local table = roomsToReplace
			local shape = RoomShape.ROOMSHAPE_1x1

			if i == 1 then
				table = IIVroomsToReplace
				shape = RoomShape.ROOMSHAPE_1x2
			elseif i == 2 then
				table = IIHroomsToReplace
				shape = RoomShape.ROOMSHAPE_2x1
			end

			-- New room data
			for j, room in pairs(table) do
				local overwriteDesc = level:GetRoomByIdx(room)
				local newData = StageAPI.GetGotoDataForTypeShape(RoomType.ROOM_DEFAULT, shape)
				overwriteDesc.Data = newData

				-- Set room data
				local newRoom = StageAPI.LevelRoom{
					RoomType = RoomType.ROOM_DEFAULT,
					RequireRoomType = true,
					RoomsList = mod.ClosetRooms,
					RoomDescriptor = overwriteDesc
				}
				StageAPI.SetLevelRoom(newRoom, overwriteDesc.ListIndex)
			end
		end


		-- Update the minimap
		level:UpdateVisibility()
	end
end
mod:AddPriorityCallback(ModCallbacks.MC_POST_NEW_LEVEL, CallbackPriority.EARLY, mod.EnterCloset)



function mod:NewRoomCloset()
	if mod.Stage:IsStage() then
		local room = Game():GetRoom()

		-- Darkness + no HUD + no shooting
		if not mod.ClosetDarkness or not mod.ClosetDarkness:Exists() then
			local darkness = Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.Entities.ClosetDarkness, 0, Vector.Zero, Vector.Zero, nil):ToEffect()
			darkness.Visible = false
			darkness:AddEntityFlags(EntityFlag.FLAG_PERSISTENT)
			mod.ClosetDarkness = darkness
		end


		-- Create mist
		for i = 1, mod:Random(2, 4) do
			local dir = room:GetDecorationSeed() % 2
			local mistSpeed = mod:Random(25, 100) / 100

			local spawnX = mod:Random(room:GetTopLeftPos().X - 400, (room:GetGridWidth() * 40) + 400)
			local spawnY = mod:Random(room:GetTopLeftPos().Y, room:GetBottomRightPos().Y)

			Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.Entities.ClosetMist, 0, Vector(spawnX, spawnY), Vector(mod:GetSign(dir) * mistSpeed, 0), nil):Update()
		end


		-- Update doors
		for grindex = 0, room:GetGridSize() - 1 do
			local grid = room:GetGridEntity(grindex)

			if grid ~= nil and grid:GetType() == GridEntityType.GRID_DOOR then
				local door = grid:ToDoor()

				if door.TargetRoomType ~= RoomType.ROOM_SECRET and door.TargetRoomType ~= RoomType.ROOM_BOSS and door.CurrentRoomType == RoomType.ROOM_DEFAULT then
					door:SetRoomTypes(door.CurrentRoomType, RoomType.ROOM_DEFAULT) -- For curse rooms mainly

					grid:GetSprite():Load("gfx/grid/door_closet.anm2", true)
					grid:GetSprite():Play("Opened", true)

					door:Open()
					door:TryBlowOpen(false, nil) -- For rooms that were super secret rooms
				end
			end
		end


		-- Improved Backdrops fix
		if ImprovedBackdrops and room:GetType() == RoomType.ROOM_BOSS then
			Game():ShowHallucination(0, BackdropType.DARK_CLOSET)
			SFXManager():Stop(SoundEffect.SOUND_DEATH_CARD)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.NewRoomCloset)