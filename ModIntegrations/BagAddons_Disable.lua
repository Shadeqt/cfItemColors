local addon = cfItemColors
local M = addon.MODULES

local BAG_ADDONS = {
	"Bagnon", "Baganator", "ArkInventory", "AdiBags", "BetterBags",
	"OneBag3", "OneBank3", "Bagnonium", "Combuctor", "Baggins",
	"Inventorian", "BaudBag", "Sorted", "LiteBag", "BankItems",
	"BankStack", "BetterCombinedBag",
}

local function IsBagAddonLoaded()
	for _, name in ipairs(BAG_ADDONS) do
		if C_AddOns.IsAddOnLoaded(name) then
			return true
		end
	end
	return false
end

if IsBagAddonLoaded() then
	cfItemColorsDB[M.BAGS].enabled = false
	cfItemColorsDB[M.BANK].enabled = false
end
