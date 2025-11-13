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

-- Self-found detection (deferred, requires buffs to be loaded)
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
	-- Wait 1 second for buffs to load, then check
	C_Timer.After(1, function()
		-- Unregister event (only need to check once)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")

		-- Self-found: disable trade/mailbox by default
		if isPlayerSelfFound() then
			db[addon.MODULES.TRADE].enabled = false
			db[addon.MODULES.MAILBOX].enabled = false
		end
	end)
end)
