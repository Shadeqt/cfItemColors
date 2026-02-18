local addon = cfItemColors
local db = cfItemColorsDB

-- Known bag addon folder names
local KNOWN_BAG_ADDONS = {
	"Bagnon", "Baganator", "ArkInventory", "AdiBags", "BetterBags",
	"OneBag3", "Bagnonium", "Baggins", "BankItems", "BankStack",
	"OneBank3", "Inventorian", "BaudBag", "Sorted", "LiteBag",
}

-- Known auction house addon folder names
local KNOWN_AH_ADDONS = {
	"Auctionator", "TradeSkillMaster", "Auctioneer", "AuctionMaster",
	"aux", "AuctionLite", "AuctionBuddy", "AuctionFaster",
}

-- Returns first loaded addon name from list, or nil
local function findLoadedAddon(addonList)
	for _, name in ipairs(addonList) do
		if C_AddOns.IsAddOnLoaded(name) then
			return name
		end
	end
end

-- Map module names to their conflict addon lists
local MODULE_CONFLICT_MAP = {
	Bags = KNOWN_BAG_ADDONS,
	Bank = KNOWN_BAG_ADDONS,
	AuctionHouse = KNOWN_AH_ADDONS,
}

-- Run conflict detection and update database
for moduleName, _ in pairs(addon.MODULES) do
	local addonList = MODULE_CONFLICT_MAP[moduleName]
	if addonList then
		local conflictAddon = findLoadedAddon(addonList)
		if conflictAddon then
			db[moduleName].enabled = false
			db[moduleName].conflict = conflictAddon .. " detected"
		end
	end
end
