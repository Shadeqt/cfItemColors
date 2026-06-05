-- Optional Questie integration. When Questie is loaded, narrow the gold-quest
-- treatment from "every item Blizzard flags as a quest item" to "items Questie
-- currently tracks for an active quest" (using QuestieTooltips' per-itemID map).
-- If Questie is absent, this file is a no-op and Core's default behavior stands.

local _, addon = ...

local function init()
    local tooltips = QuestieLoader and QuestieLoader:ImportModule("QuestieTooltips")
    local player = QuestieLoader and QuestieLoader:ImportModule("QuestiePlayer")
    if not (tooltips and player) then return end

    -- Read QuestieTooltips.lookupByKey directly rather than QuestieTooltips.GetTooltip:
    -- GetTooltip is a display builder that merges in *group members'* quest objectives
    -- (via _FetchTooltipsForGroupMembers), so it golds items only a party member needs.
    -- lookupByKey["i_"<itemID>] holds only the player's own registered objectives, so it
    -- answers "is this an item for one of MY active quests". The currentQuestlog check
    -- guards against stale entries (lookupByKey is only pruned lazily inside GetTooltip).
    addon.isActiveQuestItem = function(itemID, isQuestItem)
        if not itemID then return false end
        local entries = tooltips.lookupByKey["i_" .. itemID]
        if not entries then return false end
        for _, t in pairs(entries) do
            if t.objective and player.currentQuestlog[t.questId] then
                return true
            end
        end
        return false
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
