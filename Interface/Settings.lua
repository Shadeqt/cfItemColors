local panel = CreateFrame("Frame", "cfItemColorsSettingsPanel")
panel.name = "cfItemColors"
panel:Hide()

local addon = cfItemColors
local W = addon.Widgets
local M = addon.MODULES
local COL2 = 300
W.panel = panel
W.pendingState = {}

-- Warning + save
local function HasUnsavedChanges()
	for key, pending in pairs(W.pendingState) do
		local data = cfItemColorsDB[key]
		if data and pending ~= data.enabled then
			return true
		end
	end
	return false
end

local warning = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
warning:SetText("Click '|cffffd100Save Changes|r' to apply")
warning:Hide()

function W.UpdateWarning()
	if HasUnsavedChanges() then warning:Show() else warning:Hide() end
end

-- Tooltips
local T = W.TOOLTIPS
T[M.BAGS] = "Add quality-colored borders to items in your bags"
T[M.BANK] = "Add quality-colored borders to items in the bank"
T[M.CHARACTER] = "Add quality-colored borders to equipped items on the character sheet"
T[M.INSPECT] = "Add quality-colored borders to equipped items on the inspect frame"
T[M.LOOT] = "Add quality-colored borders to items in the loot window"
T[M.MAILBOX] = "Add quality-colored borders to mail attachments"
T[M.MERCHANT] = "Add quality-colored borders to items in the merchant window"
T[M.PROFESSIONS] = "Add quality-colored borders to items in tradeskill and trainer windows"
T[M.QUEST] = "Add quality-colored borders to quest reward items"
T[M.TRADE] = "Add quality-colored borders to items in the trade window"

-- Items
local title = W.CreateTitle(panel, "cfItemColors")
local itemsHeader = W.CreateHeader(title, "Items")
local itemsSection = W.CreateSection(itemsHeader)
local bags = W.CreateCheckbox(itemsSection, "Bags", M.BAGS)
local bank = W.CreateCheckbox(bags, "Bank", M.BANK, COL2)
local character = W.CreateCheckbox(bags, "Character", M.CHARACTER)
local inspect = W.CreateCheckbox(character, "Inspect", M.INSPECT, COL2)
local loot = W.CreateCheckbox(character, "Loot", M.LOOT)
local merchant = W.CreateCheckbox(loot, "Merchant", M.MERCHANT, COL2)
local professions = W.CreateCheckbox(loot, "Professions", M.PROFESSIONS)
local quest = W.CreateCheckbox(professions, "Quest", M.QUEST, COL2)
local activeQuestOnly = W.CreateCheckbox(professions, "Active Quest Items Only", "activeQuestOnly", nil, quest)

-- Player Trading
local tradingHeader = W.CreateHeader(itemsSection, "Player Trading")
local tradingSection = W.CreateSection(tradingHeader)
local trade = W.CreateCheckbox(tradingSection, "Trade", M.TRADE)
local mailbox = W.CreateCheckbox(trade, "Mailbox", M.MAILBOX, COL2)

-- Conflicts
W.ApplyConflict(bags)
W.ApplyConflict(bank)

-- Save Changes
local reloadBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
reloadBtn:SetPoint("TOPLEFT", tradingSection.section, "BOTTOMLEFT", 0, -10)
reloadBtn:SetSize(120, 25)
reloadBtn:SetText("Save Changes")
reloadBtn:SetScript("OnClick", function()
	for key, enabled in pairs(W.pendingState) do
		if cfItemColorsDB[key] then
			cfItemColorsDB[key].enabled = enabled
		end
	end
	ReloadUI()
end)

warning:SetPoint("LEFT", reloadBtn, "RIGHT", 8, 0)

local info = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
info:SetPoint("TOPLEFT", reloadBtn, "BOTTOMLEFT", 4, -8)
info:SetText("Type |cffffffff/cfic|r to open this panel")

-- Register
local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name)
Settings.RegisterAddOnCategory(category)

SLASH_CFITEMCOLORS1 = "/cfic"
SlashCmdList["CFITEMCOLORS"] = function()
	Settings.OpenToCategory(category:GetID())
end
