local addon = cfItemColors

local function initQuestie()
	local questieTooltips = QuestieLoader:ImportModule("QuestieTooltips")
	local nativeCheck = addon.checkQuestItem

	addon.checkQuestItem = function(itemID, itemClassId, bagId, bagItemButtonId)
		local cached = addon.questItemCache[itemID]
		if cached ~= nil then return cached end

		local isQuest = false

		-- Native checks (skip when activeQuestOnly)
		if not cfItemColorsDB.activeQuestOnly.enabled then
			if itemClassId == Enum.ItemClass.Questitem then
				isQuest = true
			end
			if not isQuest and bagId and bagItemButtonId then
				local info = C_Container.GetContainerItemQuestInfo(bagId, bagItemButtonId)
				if info and (info.isQuestItem or info.questID) then
					isQuest = true
				end
			end
		end

		-- Questie check (both modes)
		if not isQuest and questieTooltips.GetTooltip("i_" .. itemID) then
			isQuest = true
		end

		addon.questItemCache[itemID] = isQuest
		return isQuest
	end

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
