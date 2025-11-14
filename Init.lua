-- Create addon namespace
cfItemColors = {}

-- Localize for performance and consistency
local db = cfItemColorsDB
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
	QUEST_OBJECTIVE = "QuestObjective",
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

-- Initialize database immediately at file load
if not db then
	db = {}
	cfItemColorsDB = db
	for _, moduleName in pairs(addon.MODULES) do
		db[moduleName] = {
			enabled = true,
			conflict = nil
		}
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

-- Self-found detection on addon load
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
	if addonName ~= "cfItemColors" then return end

	-- Unregister event (only need to check once)
	self:UnregisterEvent("ADDON_LOADED")

	-- Check for self-found status and disable modules if needed
	if isPlayerSelfFound() then
		db[addon.MODULES.TRADE].enabled = false
		db[addon.MODULES.MAILBOX].enabled = false
	end

	-- Trigger module initialization callbacks
	addon:onInitComplete()
end)
