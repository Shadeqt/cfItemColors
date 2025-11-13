-- Module name constants
cfItemColors.MODULES = {
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

-- Initialize database and run conflict detection on first login
local initFrame = CreateFrame("Frame")

initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")  -- Deferred initialization check
initFrame:SetScript("OnEvent", function(self, event)
	-- Wait 1 second for buffs to load, then check
	C_Timer.After(1, function()
		-- Unregister event (only need to check once)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")

		-- Initialize database on first load (buffs are now available)
		if not cfItemColorsDB then
			cfItemColorsDB = {}
			for _, moduleName in pairs(cfItemColors.MODULES) do
				cfItemColorsDB[moduleName] = {
					enabled = true,
					conflict = nil
				}
			end

			-- Self-found: disable trade/mailbox by default
			if isPlayerSelfFound() then
				cfItemColorsDB[cfItemColors.MODULES.TRADE].enabled = false
				cfItemColorsDB[cfItemColors.MODULES.MAILBOX].enabled = false
			end
		end

		-- Refresh conflict detection (runs every load)
		for _, moduleName in pairs(cfItemColors.MODULES) do
			local _, conflictAddon = cfItemColors.Compatibility.ShouldModuleLoad(moduleName)
			cfItemColorsDB[moduleName].conflict = conflictAddon
		end
	end)
end)

-- Returns module state (enabled, conflict) from database
function cfItemColors.GetModuleState(moduleName)
	-- DB might not exist yet during file load (before PLAYER_LOGIN)
	if not cfItemColorsDB then return true, nil end
	local data = cfItemColorsDB[moduleName]
	if not data then return false, nil end
	return data.enabled, data.conflict
end

-- Updates module enabled state in database
function cfItemColors.SetModuleEnabled(moduleName, enabled)
	if cfItemColorsDB[moduleName] then
		cfItemColorsDB[moduleName].enabled = enabled
	end
end
