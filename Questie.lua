-- Optional Questie integration. When Questie is loaded, narrow the gold-quest
-- treatment from "every item Blizzard flags as a quest item" to "items Questie
-- currently tracks for an active quest" (using QuestieTooltips' per-itemID map).
-- If Questie is absent, this file is a no-op and Core's default behavior stands.

local _, addon = ...

local function init()
    local tooltips = QuestieLoader and QuestieLoader:ImportModule("QuestieTooltips")
    if not tooltips then return end

    addon.isActiveQuestItem = function(bagId, bagItemButtonId)
        if not (bagId and bagItemButtonId) then return false end
        local itemID = C_Container.GetContainerItemID(bagId, bagItemButtonId)
        return itemID and tooltips.GetTooltip("i_" .. itemID) ~= nil
    end

    -- Re-paint any bag already open at the moment we took over; otherwise it
    -- stays on the pre-override (broad) coloring until next toggle.
    if addon.refreshBags then addon.refreshBags() end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if Questie and Questie.API and Questie.API.RegisterOnReady then
        Questie.API.RegisterOnReady(init)
    end
end)
