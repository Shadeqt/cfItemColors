local addon = cfItemColors

local function initQuestie()
	addon.questieTooltips = QuestieLoader:ImportModule("QuestieTooltips")

	-- Wipe quest item cache on quest changes so items get re-checked
	local eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("QUEST_ACCEPTED")
	eventFrame:RegisterEvent("QUEST_REMOVED")
	eventFrame:SetScript("OnEvent", function()
		wipe(addon.questItemCache)
	end)

end

-- Wait for Questie to be fully initialized
if Questie and Questie.API and Questie.API.RegisterOnReady then
	Questie.API.RegisterOnReady(initQuestie)
else
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("ADDON_LOADED")
	frame:SetScript("OnEvent", function(self, _, addonName)
		if addonName == "Questie" and Questie and Questie.API and Questie.API.RegisterOnReady then
			self:UnregisterEvent("ADDON_LOADED")
			Questie.API.RegisterOnReady(initQuestie)
		end
	end)
end
