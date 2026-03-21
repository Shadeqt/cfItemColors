local addon = cfItemColors

local function initQuestie()
	local QuestieTooltips = QuestieLoader:ImportModule("QuestieTooltips")
	addon.questieTooltips = QuestieTooltips

	-- Wipe quest item cache on quest changes so items get re-checked
	local eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("QUEST_ACCEPTED")
	eventFrame:RegisterEvent("QUEST_REMOVED")
	eventFrame:SetScript("OnEvent", function()
		wipe(addon.questItemCache)
	end)
end

-- Wait for Questie to load
if QuestieLoader then
	initQuestie()
else
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("ADDON_LOADED")
	frame:SetScript("OnEvent", function(self, _, addonName)
		if addonName == "Questie" and QuestieLoader then
			self:UnregisterEvent("ADDON_LOADED")
			initQuestie()
		end
	end)
end
