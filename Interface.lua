-- Settings panel frame
local panel = CreateFrame("Frame", "cfItemColorsPanel")
panel.name = "cfItemColors"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("cfItemColors Settings")

-- Helper function to create a checkbox
local function createCheckbox(parent, anchorTo, xOffset, yOffset, dbKey, labelText)
	local check = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
	check:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", xOffset, yOffset)
	check.Text:SetText(labelText)
	check:SetChecked(cfItemColorsDB[dbKey])
	check:SetScript("OnClick", function(self)
		cfItemColorsDB[dbKey] = self:GetChecked()
	end)
	return check
end

-- Left column checkboxes
local bagsCheck = createCheckbox(panel, title, 0, -16, "enableBags", "Enable Bags")
local bankCheck = createCheckbox(panel, bagsCheck, 0, -8, "enableBank", "Enable Bank")
local characterCheck = createCheckbox(panel, bankCheck, 0, -8, "enableCharacter", "Enable Character Sheet")
local inspectCheck = createCheckbox(panel, characterCheck, 0, -8, "enableInspect", "Enable Inspect Window")
local lootCheck = createCheckbox(panel, inspectCheck, 0, -8, "enableLoot", "Enable Loot Rolls")
local mailboxCheck = createCheckbox(panel, lootCheck, 0, -8, "enableMailbox", "Enable Mailbox")

-- Right column checkboxes
local merchantCheck = createCheckbox(panel, title, 250, -16, "enableMerchant", "Enable Merchant")
local professionsCheck = createCheckbox(panel, merchantCheck, 0, -8, "enableProfessions", "Enable Professions")
local questCheck = createCheckbox(panel, professionsCheck, 0, -8, "enableQuest", "Enable Quest Window")
local questObjectiveCheck = createCheckbox(panel, questCheck, 0, -8, "enableQuestObjective", "Enable Quest Objectives")
local tradeCheck = createCheckbox(panel, questObjectiveCheck, 0, -8, "enableTrade", "Enable Trade Window")

-- Reload UI button
local reloadBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
reloadBtn:SetPoint("TOPLEFT", mailboxCheck, "BOTTOMLEFT", 0, -16)
reloadBtn:SetSize(120, 25)
reloadBtn:SetText("Reload UI")
reloadBtn:SetScript("OnClick", function()
	ReloadUI()
end)

-- Warning text
local warning = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
warning:SetPoint("LEFT", reloadBtn, "RIGHT", 8, 0)
warning:SetText("|cffFF6600Changes require a reload to take effect|r")

-- Info text
local info = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
info:SetPoint("TOPLEFT", reloadBtn, "BOTTOMLEFT", 4, -8)
info:SetText("Type |cffFFFF00/cfic|r to open this panel")

-- Refresh checkboxes when panel is shown
panel:SetScript("OnShow", function(self)
	bagsCheck:SetChecked(cfItemColorsDB.enableBags)
	bankCheck:SetChecked(cfItemColorsDB.enableBank)
	characterCheck:SetChecked(cfItemColorsDB.enableCharacter)
	inspectCheck:SetChecked(cfItemColorsDB.enableInspect)
	lootCheck:SetChecked(cfItemColorsDB.enableLoot)
	mailboxCheck:SetChecked(cfItemColorsDB.enableMailbox)
	merchantCheck:SetChecked(cfItemColorsDB.enableMerchant)
	professionsCheck:SetChecked(cfItemColorsDB.enableProfessions)
	questCheck:SetChecked(cfItemColorsDB.enableQuest)
	questObjectiveCheck:SetChecked(cfItemColorsDB.enableQuestObjective)
	tradeCheck:SetChecked(cfItemColorsDB.enableTrade)
end)

-- Register with settings API (for modern WoW versions)
if Settings and Settings.RegisterCanvasLayoutCategory then
	local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
	category.ID = panel.name
	Settings.RegisterAddOnCategory(category)
end

-- Slash command to open settings panel
SLASH_CFITEMCOLORS1 = "/cfic"
SlashCmdList["CFITEMCOLORS"] = function()
	if Settings and Settings.OpenToCategory then
		Settings.OpenToCategory(panel.name)
	else
		InterfaceOptionsFrame_OpenToCategory(panel)
		InterfaceOptionsFrame_OpenToCategory(panel) -- Called twice to fix Blizzard bug
	end
end
