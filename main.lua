GuppysPlaytime = RegisterMod("Guppy's Playtime", 1)
local mod = GuppysPlaytime



--[[ Load scripts ]]--
function mod:LoadScripts(scripts, subfolder)
	subfolder = subfolder or ""
	for i, script in pairs(scripts) do
		include("playtime_scripts." .. subfolder .. "." .. script)
	end
end


-- General
local generalScripts = {
	"constants",
	"utilities",

	"guppy",
	"effects",
	"satanShadow",
}
mod:LoadScripts(generalScripts)


-- Floors
local floorScripts = {
	"basement",
	"closet",
	"home",
}
mod:LoadScripts(floorScripts, "floors")



-- Known issues:
-- Mist does not go off-screen completely before respawning in thin rooms
-- Random crash when starting new run
-- Stage transition shows the wrong stage type if it wasn't the Basement originally