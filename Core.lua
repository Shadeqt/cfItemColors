-- Shared primitives for cfItemColors: quality-color lookup, border + quest-marker
-- drawing, and the public addon.applyQualityColor / addon.applyQuestMarker entry
-- points used by every Modules/* file. Each module resolves its own surface's quest
-- signal (bags/loot from Blizzard's per-slot APIs, turn-in by assertion) and passes
-- it in; the default addon.isActiveQuestItem simply trusts that flag, while Questie.lua
-- replaces it with an itemID-keyed check (only items in quests Questie tracks).

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

-- Decides whether an item gets the gold active-quest treatment. The default trusts
-- the per-surface quest flag the caller resolved from Blizzard's own quest-item APIs
-- (GetContainerItemQuestInfo for bag/bank slots, GetLootSlotInfo for loot, ...) — that
-- flag is Blizzard's "objective item for one of your quests" signal and needs no bag
-- slot. itemID is unused by the default but is the key Questie.lua's override keys on,
-- narrowing the set to items in quests Questie is currently tracking.
function addon.isActiveQuestItem(itemID, isQuestItem)
    return isQuestItem == true
end

-- Resolves the icon texture a border should anchor to. Most buttons expose it as a
-- global <name>IconTexture; some use a .Icon/.icon member, and a few (e.g. the
-- crafted-item icon in the trade-skill window) paint it as the button's NormalTexture.
local function findIconTexture(button)
    local buttonName = button:GetName()
    local named = buttonName and _G[buttonName .. "IconTexture"]
    if named then return named end
    if button.Icon then return button.Icon end
    if button.icon then return button.icon end
    return button.GetNormalTexture and button:GetNormalTexture()
end

local function createBorder(button)
    if button.customBorder then return button.customBorder end

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetTexCoord(0.225, 0.775, 0.225, 0.775)
    border:SetBlendMode("ADD")

    local iconTexture = findIconTexture(button)
    border:SetAllPoints(iconTexture or button)
    border:Hide()

    button.customBorder = border
    return border
end

-- Equalize perceived border brightness across qualities. Blizzard's quality colors
-- vary widely in luminance (green/gold glow far brighter than blue under ADD), so
-- scale each border's alpha inversely to its color luminance, using rare blue's
-- luminance as the reference (the dimmest border color). Blue lands at full alpha;
-- every brighter quality (purple/green/gold) is dimmed down to match it.
local BORDER_TARGET_LUMINANCE = 0.36  -- rare blue
local function borderAlpha(color)
    local lum = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b
    return math.min(BORDER_TARGET_LUMINANCE / lum, 1.0)
end

local function updateBorder(button, itemQuality)
    if itemQuality and itemQuality >= QUALITY_UNCOMMON then
        local border = createBorder(button)
        local color  = QUALITY_COLORS[itemQuality]
        if not color then return end
        border:SetVertexColor(color.r, color.g, color.b, borderAlpha(color))
        border:Show()
    elseif button.customBorder then
        button.customBorder:Hide()
    end
end

local function hideQuestMarker(button)
    if button.questMarker then button.questMarker:Hide() end
end

-- True when the slot's item begins a quest you haven't completed yet. This is the
-- single source of truth shared by the begins-quest marker and the gold border, so
-- the two always agree: any item showing the ! / ? icon also gets the gold border.
-- Bag/bank-only — questInfo comes from C_Container.GetContainerItemQuestInfo.
function addon.beginsUncompletedQuest(questInfo)
    local questId = questInfo and questInfo.questID
    return (questId and not C_QuestLog.IsQuestFlaggedCompleted(questId)) or false
end

-- Draws the begins-quest marker (the ! / ? icon) for items that start an
-- uncompleted quest. Bag/bank-only: the caller passes the ItemQuestInfo it already
-- fetched for that slot (questID/isActive). Pass nil to just hide the marker.
function addon.applyQuestMarker(button, questInfo)
    if not addon.beginsUncompletedQuest(questInfo) then
        hideQuestMarker(button)
        return
    end

    if not button.questMarker then
        button.questMarker = button:CreateTexture(nil, "OVERLAY")
        button.questMarker:SetSize(16, 16)
        button.questMarker:SetPoint("BOTTOMRIGHT", -2, 4)
    end

    local texture = questInfo.isActive and "Interface\\GossipFrame\\ActiveQuestIcon"
                                         or "Interface\\GossipFrame\\AvailableQuestIcon"
    button.questMarker:SetTexture(texture)
    button.questMarker:Show()
end

-- Colors a button's border by item quality. isQuestItem is the caller's resolved
-- "this is an objective for a quest you're on" flag: bags/loot read it from Blizzard's
-- per-slot quest APIs, the turn-in panel asserts it, and surfaces with no such signal
-- pass nothing (Questie's override still recognizes them by itemID). beginsQuest is the
-- bag/bank caller's "this item starts an uncompleted quest" flag (see
-- addon.beginsUncompletedQuest) — it golds quest-starter items so their border matches
-- the begins-quest marker. Both signals only upgrade common/poor items to gold.
function addon.applyQualityColor(button, itemIdOrLink, isQuestItem, beginsQuest)
    if not button then return end

    if not itemIdOrLink then
        updateBorder(button, nil)
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
                    addon.applyQualityColor(button, itemIdOrLink, isQuestItem, beginsQuest)
                end)
            end)
        end
        return
    end

    if itemQuality <= QUALITY_COMMON and (addon.isActiveQuestItem(itemID, isQuestItem) or beginsQuest) then
        itemQuality = QUEST_QUALITY
    end

    updateBorder(button, itemQuality)
end
