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
}
mod:LoadScripts(generalScripts)


-- Floors
local floorScripts = {
	"basement",
	"closet",
	"home",
}
mod:LoadScripts(floorScripts, "floors")


-- Enemies
local enemyScripts = {
	"sadSatan",
}
mod:LoadScripts(enemyScripts)