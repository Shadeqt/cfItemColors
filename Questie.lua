-- Optional Questie integration. When Questie is loaded, narrow the gold-quest treatment from
-- "every item Blizzard flags as a quest item" to "items that belong to a quest in your log"
-- (objective, special-objective, and provided/source items). The set is built from
-- QuestiePlayer.currentQuestlog + QuestieDB, so it is independent of quest *tracking*:
-- untracking a quest no longer drops the border (the earlier QuestieTooltips.lookupByKey
-- source was cleared on untrack whenever hideUntrackedQuestsMapIcons was enabled). If Questie
-- is absent, this file is a no-op and Core's default behavior stands.
--
-- Note: not-yet-accepted quest items shown in an NPC's quest-offer dialog are handled in
-- Quest.lua by item class, not here — they aren't in your quest log so this set can't see them.

local _, addon = ...

-- Items belonging to quests in the player's log: [itemID] = true. Rebuilt from currentQuestlog.
local questItemIDs = {}

local QuestiePlayer, QuestieDB

-- Add every item that belongs to a single quest into `set`. One definition of "the quest's
-- items", reused for the whole log (rebuild) and for a single previewed quest (offer dialog).
-- Together these mirror exactly the item tooltips Questie itself registers.
local function collectQuestItems(quest, set)
    if not quest then return end

    -- Objective items: "collect N of item" objectives.
    if quest.ObjectiveData then
        for _, objective in pairs(quest.ObjectiveData) do
            if objective.Type == "item" and objective.Id then
                set[objective.Id] = true
            end
        end
    end

    -- Special / extra objectives can also be item-type (item-type extraObjectives, plus any
    -- requiredSourceItems that aren't already a normal objective). Same {Type, Id} shape.
    if quest.SpecialObjectives then
        for _, objective in pairs(quest.SpecialObjectives) do
            if objective.Type == "item" and objective.Id then
                set[objective.Id] = true
            end
        end
    end

    -- Provided / source items that are NOT objectives but still belong to the quest: the item
    -- that started/provides it (e.g. "A Letter from the Diplomat"), any required source items,
    -- and a spell-cast item.
    if quest.sourceItemId then
        set[quest.sourceItemId] = true
    end
    if quest.SpellItemId then
        set[quest.SpellItemId] = true
    end
    if quest.requiredSourceItems then
        for _, itemId in pairs(quest.requiredSourceItems) do
            set[itemId] = true
        end
    end
end

-- Rebuild questItemIDs from the live quest log. Tracking-independent: currentQuestlog is
-- populated by QuestieQuest:GetAllQuestIds (not the tracker), and untracking leaves both it
-- and each quest's ObjectiveData intact. Cheap and rare (<=~25 quests x a few objectives,
-- GetQuest is memoized). Does NOT touch offeredQuestItemIDs (the preview set is independent).
local function rebuild()
    table.wipe(questItemIDs)
    for questId in pairs(QuestiePlayer.currentQuestlog) do
        collectQuestItems(QuestieDB.GetQuest(questId), questItemIDs)  -- handles bare-id entries
    end

    -- Re-paint any bag already open so the rebuilt set takes effect immediately; otherwise
    -- it stays on the previous coloring until next toggle.
    if addon.refreshBags then addon.refreshBags() end
end

local function init()
    QuestiePlayer = QuestieLoader and QuestieLoader:ImportModule("QuestiePlayer")
    QuestieDB = QuestieLoader and QuestieLoader:ImportModule("QuestieDB")
    if not (QuestiePlayer and QuestieDB) then return end

    -- Membership in questItemIDs is the sole signal under Questie; the caller's broad
    -- isQuestItem flag is ignored. (The quest-offer dialog colors not-yet-accepted quest items
    -- separately, by item class, in Quest.lua — it can't rely on this log-based set.)
    addon.isActiveQuestItem = function(itemID)
        return (itemID and questItemIDs[itemID] == true) or false
    end

    rebuild()

    _G.cfQII = questItemIDs  -- TEMP DEBUG: remove after verifying

    -- Update on quest-log structure changes via Questie's own quest-update callback rather
    -- than Blizzard's raw QUEST_ACCEPTED/QUEST_REMOVED. Questie fires this only AFTER it has
    -- confirmed the quest's objective data is cached (HandleQuestAccepted retries internally
    -- every 0.5s until QuestLogCache reports the objectives ready), so the item objectives we
    -- read are guaranteed populated — no fragile one-frame C_Timer.After(0) guess that could
    -- read a half-built quest and drop its items from the set for the whole session.
    -- Membership only changes when a quest enters/leaves the log, so we ignore QUEST_UPDATED
    -- (objective-progress ticks); accept / turn-in / abandon are the structural reasons.
    --
    -- ACCEPT is asymmetric: Questie propagates QUEST_ACCEPTED *before* QuestieQuest:AcceptQuest
    -- inserts the quest into QuestiePlayer.currentQuestlog, so a full rebuild() here would loop
    -- a log that doesn't yet contain the new quest and miss its items (the border then stays
    -- off until the next /reload). The quest's objectives are already cached at this point, so
    -- collect them directly by the questId the callback hands us, additively, and repaint.
    -- Turn-in / abandon remove the quest from currentQuestlog *before* propagating, so a full
    -- rebuild() correctly drops the gone quest's items.
    local Enums = Questie.API.Enums.QuestUpdateTriggerReason
    Questie.API.RegisterForQuestUpdates(function(questId, _, triggerReason)
        if triggerReason == Enums.QUEST_ACCEPTED then
            collectQuestItems(QuestieDB.GetQuest(questId), questItemIDs)
            if addon.refreshBags then addon.refreshBags() end
        elseif triggerReason == Enums.QUEST_TURNED_IN
            or triggerReason == Enums.QUEST_ABANDONED then
            rebuild()
        end
    end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if Questie and Questie.API and Questie.API.RegisterOnReady then
        Questie.API.RegisterOnReady(init)
    end
end)
