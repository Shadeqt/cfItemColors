local _, addon = ...

-- Hooks TradeSkillFrame (crafted item + reagents) and ClassTrainerFrame (recipe
-- items at profession trainers — `ClassTrainerFrame` is the shared frame for both
-- class and profession trainers in Classic). For class abilities,
-- GetTrainerServiceItemLink returns nil, the border just stays hidden — no harm.

local function updateTradeSkillItems()
    local selectedIndex = GetTradeSkillSelectionIndex()

    addon.applyQualityColor(_G.TradeSkillSkillIcon, GetTradeSkillItemLink(selectedIndex))

    local numReagents = GetTradeSkillNumReagents(selectedIndex)
    for i = 1, numReagents do
        addon.applyQualityColor(_G["TradeSkillReagent" .. i], GetTradeSkillReagentItemLink(selectedIndex, i))
    end
end

local function updateClassTrainerIcon()
    addon.applyQualityColor(_G.ClassTrainerSkillIcon, GetTrainerServiceItemLink(GetTrainerSelectionIndex()))
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_TradeSkillUI", function()
    hooksecurefunc("TradeSkillFrame_SetSelection", updateTradeSkillItems)
end)

EventUtil.ContinueOnAddOnLoaded("Blizzard_TrainerUI", function()
    hooksecurefunc("ClassTrainerFrame_Update", updateClassTrainerIcon)
end)
