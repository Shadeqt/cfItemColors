-- Create addon namespace
cfItemColors = {}

local addon = cfItemColors

-- Module name constants
addon.MODULES = {
	BAGS = "Bags",
	BANK = "Bank",
	CHARACTER = "Character",
	INSPECT = "Inspect",
	LOOT = "Loot",
	MAILBOX = "Mailbox",
	MERCHANT = "Merchant",
	PROFESSIONS = "Professions",
	QUEST = "Quest",

	TRADE = "Trade",
}

-- Database defaults
local dbDefaults = {}
for _, moduleName in pairs(addon.MODULES) do
	dbDefaults[moduleName] = {
		enabled = true,
		conflict = nil
	}
end
dbDefaults.activeQuestOnly = { enabled = false }

-- Create DB with defaults at file load (modules check enabled state at load time)
if not cfItemColorsDB then cfItemColorsDB = {} end
for key, value in pairs(dbDefaults) do
	if cfItemColorsDB[key] == nil then
		cfItemColorsDB[key] = value
	end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
	if addonName ~= "cfItemColors" then return end
	self:UnregisterEvent("ADDON_LOADED")

	-- Initialize database from SavedVariables (available at ADDON_LOADED)
	local db = cfItemColorsDB or {}
	cfItemColorsDB = db

	-- Apply defaults for any missing keys
	for key, value in pairs(dbDefaults) do
		if db[key] == nil then
			db[key] = value
		end
	end

	-- Remove keys from DB that aren't in defaults
	for key in pairs(db) do
		if dbDefaults[key] == nil then
			db[key] = nil
		end
	end

end)
