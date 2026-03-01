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

-- Callback system for modules waiting on init completion
addon.initListeners = {}

-- WoW constants
local BUFF_MAX_DISPLAY = BUFF_MAX_DISPLAY -- 32, max buffs on player

-- Detects if player has self-found adventurer buff
local function isPlayerSelfFound()
	for i = 1, BUFF_MAX_DISPLAY do
		local _, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", i)
		if not spellId then return false end
		if spellId == 431567 then return true end
	end
	return false
end

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

function addon:registerInitListener(callback)
	table.insert(self.initListeners, callback)
end

function addon:onInitComplete()
	for _, listener in ipairs(self.initListeners) do
		listener()
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

	-- Check for self-found status and disable modules if needed
	if isPlayerSelfFound() then
		db[addon.MODULES.TRADE].enabled = false
		db[addon.MODULES.MAILBOX].enabled = false
	end

	-- Trigger module initialization callbacks
	addon:onInitComplete()
end)
