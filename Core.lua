-- Shared primitives for cfItemColors: quality-color lookup, border + quest-marker
-- drawing, and the public addon.applyQualityColor entry point used by every
-- Modules/* file. The default addon.isActiveQuestItem treats every Blizzard-
-- flagged quest item as active; Questie.lua replaces it with a narrower check
-- (only items in actively tracked quests) when Questie is loaded.

local _, addon = ...

addon.EQUIPMENT_SLOTS = {
    "Head", "Neck", "Shoulder", "Shirt", "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands",
    "Finger0", "Finger1", "Trinket0", "Trinket1", "Back", "MainHand", "SecondaryHand", "Ranged", "Tabard",
}

local QUALITY_COMMON   = 1
local QUALITY_UNCOMMON = 2
local QUEST_QUALITY    = 99  -- synthetic quality for active-quest items (gold)

local QUALITY_COLORS = setmetatable({
    [QUEST_QUALITY] = { r = 1.0, g = 0.82, b = 0.0 },
}, {
    __index = function(self, quality)
        local r, g, b = C_Item.GetItemQualityColor(quality)
        if r then
            self[quality] = { r = r, g = g, b = b }
            return self[quality]
        end
    end,
})

-- Default: every item Blizzard flags as a quest item gets the gold treatment.
-- Questie.lua overrides addon.isActiveQuestItem when Questie is loaded, narrowing
-- the set to items in actively tracked quests.
function addon.isActiveQuestItem(bagId, bagItemButtonId)
    if not (bagId and bagItemButtonId) then return false end
    local info = C_Container.GetContainerItemQuestInfo(bagId, bagItemButtonId)
    return info and info.isQuestItem == true
end

local function createBorder(button)
    if button.customBorder then return button.customBorder end

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetTexCoord(0.225, 0.775, 0.225, 0.775)
    border:SetBlendMode("ADD")
    border:SetAlpha(0.8)

    local buttonName = button:GetName()
    local iconTexture = (buttonName and _G[buttonName .. "IconTexture"]) or button.Icon or button.icon
    border:SetAllPoints(iconTexture or button)
    border:Hide()

    button.customBorder = border
    return border
end

local function updateBorder(button, itemQuality)
    if itemQuality and itemQuality >= QUALITY_UNCOMMON then
        local border = createBorder(button)
        local color  = QUALITY_COLORS[itemQuality]
        if not color then return end
        border:SetVertexColor(color.r, color.g, color.b, 0.6)
        border:Show()
    elseif button.customBorder then
        button.customBorder:Hide()
    end
end

local function hideQuestMarker(button)
    if button.questMarker then button.questMarker:Hide() end
end

local function applyQuestMarker(button, bagId, bagItemButtonId)
    if button.beginsQuest == false or not bagId or not bagItemButtonId then
        hideQuestMarker(button)
        return
    end

    local info        = C_Container.GetContainerItemQuestInfo(bagId, bagItemButtonId)
    local questId     = info and info.questID
    local isCompleted = questId and C_QuestLog.IsQuestFlaggedCompleted(questId)

    if not questId or isCompleted then
        button.beginsQuest = false
        hideQuestMarker(button)
        return
    end

    if not button.questMarker then
        button.questMarker = button:CreateTexture(nil, "OVERLAY")
        button.questMarker:SetSize(16, 16)
        button.questMarker:SetPoint("BOTTOMRIGHT", -2, 4)
    end

    local texture = info.isActive and "Interface\\GossipFrame\\ActiveQuestIcon"
                                    or "Interface\\GossipFrame\\AvailableQuestIcon"
    button.questMarker:SetTexture(texture)
    button.beginsQuest = true
    button.questMarker:Show()
end

function addon.applyQualityColor(button, itemIdOrLink, bagId, bagItemButtonId)
    if not button then return end

    if not itemIdOrLink then
        updateBorder(button, nil)
        applyQuestMarker(button, nil, nil)
        return
    end

    local itemID = C_Item.GetItemInfoInstant(itemIdOrLink)
    if not itemID then return end

    local itemQuality = C_Item.GetItemQualityByID(itemIdOrLink)
    if not itemQuality then
        -- Item data not cached yet — wait for it to load, then retry.
        local item = type(itemIdOrLink) == "number"
            and Item:CreateFromItemID(itemIdOrLink)
            or  Item:CreateFromItemLink(itemIdOrLink)
        if item and not item:IsItemEmpty() then
            item:ContinueOnItemLoad(function()
                C_Timer.After(0, function()
                    addon.applyQualityColor(button, itemIdOrLink, bagId, bagItemButtonId)
                end)
            end)
        end
        return
    end

    if itemQuality <= QUALITY_COMMON and addon.isActiveQuestItem(bagId, bagItemButtonId) then
        itemQuality = QUEST_QUALITY
    end

    button.beginsQuest = nil
    updateBorder(button, itemQuality)
    applyQuestMarker(button, bagId, bagItemButtonId)
end
