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
	"satanShadow",
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






-- TODO ordered by priority:
-- Guppy sprites + attacks (ASAP pls)
-- Cardboard Monstro
-- Costume with Isaac's eyes sewn shut in the closet (not in home)
-- Shadowy hallucinations
-- Jumpscare enemies? (probably not enough time)
-- Fix first floor boss vs screen showing monstro if he was replaced (if possible???)