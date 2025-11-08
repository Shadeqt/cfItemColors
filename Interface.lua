-- Settings panel frame
local panel = CreateFrame("Frame", "cfItemColorsPanel")
panel.name = "cfItemColors"

-- Pending state (created fresh on panel open)
local pendingState = nil

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("cfItemColors Settings")

-- Helper function to create a checkbox
local function createCheckbox(parent, anchorTo, xOffset, yOffset, dbKey, labelText)
	local check = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
	check:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", xOffset, yOffset)
	check.Text:SetText(labelText)
	check.dbKey = dbKey  -- Store the key for later use
	check:SetScript("OnClick", function(self)
		pendingState[self.dbKey] = self:GetChecked()
	end)
	return check
end

-- Left column checkboxes
local bagsCheck = createCheckbox(panel, title, 0, -16, "enableBags", "Enable Bags")
local bankCheck = createCheckbox(panel, bagsCheck, 0, -8, "enableBank", "Enable Bank")
local characterCheck = createCheckbox(panel, bankCheck, 0, -8, "enableCharacter", "Enable Character Sheet")
local inspectCheck = createCheckbox(panel, characterCheck, 0, -8, "enableInspect", "Enable Inspect Window")
local lootCheck = createCheckbox(panel, inspectCheck, 0, -8, "enableLoot", "Enable Loot Window")

-- Right column checkboxes
local merchantCheck = createCheckbox(panel, title, 250, -16, "enableMerchant", "Enable Merchant")
local professionsCheck = createCheckbox(panel, merchantCheck, 0, -8, "enableProfessions", "Enable Professions")
local questCheck = createCheckbox(panel, professionsCheck, 0, -8, "enableQuest", "Enable Quest Window")
local questObjectiveCheck = createCheckbox(panel, questCheck, 0, -8, "enableQuestObjective", "Enable Quest Objectives")

-- Group 2 Header: Player Trading
local group2Header = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
group2Header:SetPoint("TOPLEFT", lootCheck, "BOTTOMLEFT", 0, -16)
group2Header:SetText("|cffFFD700Player Trading:|r")

-- Group 2 checkboxes (Player trading features) - in columns
local tradeCheck = createCheckbox(panel, group2Header, 0, -8, "enableTrade", "Enable Trade Window")
local mailboxCheck = createCheckbox(panel, group2Header, 250, -8, "enableMailbox", "Enable Mailbox")

-- Reload UI button
local reloadBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
reloadBtn:SetPoint("TOPLEFT", tradeCheck, "BOTTOMLEFT", 0, -16)
reloadBtn:SetSize(120, 25)
reloadBtn:SetText("Reload UI")
reloadBtn:SetScript("OnClick", function()
	-- Commit pending changes to database
	for key, value in pairs(pendingState) do
		cfItemColorsDB[key] = value
	end
	ReloadUI()
end)

-- Warning text
local warning = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
warning:SetPoint("LEFT", reloadBtn, "RIGHT", 8, 0)
warning:SetText("|cffFF6600Click 'Reload UI' to apply changes|r")

-- Info text
local info = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
info:SetPoint("TOPLEFT", reloadBtn, "BOTTOMLEFT", 4, -8)
info:SetText("Type |cffFFFF00/cfic|r to open this panel")

-- Function to initialize checkboxes from database
local function initializeCheckboxes()
	-- Copy database to pending state
	pendingState = {
		enableBags = cfItemColorsDB.enableBags,
		enableBank = cfItemColorsDB.enableBank,
		enableCharacter = cfItemColorsDB.enableCharacter,
		enableInspect = cfItemColorsDB.enableInspect,
		enableLoot = cfItemColorsDB.enableLoot,
		enableMailbox = cfItemColorsDB.enableMailbox,
		enableMerchant = cfItemColorsDB.enableMerchant,
		enableProfessions = cfItemColorsDB.enableProfessions,
		enableQuest = cfItemColorsDB.enableQuest,
		enableQuestObjective = cfItemColorsDB.enableQuestObjective,
		enableTrade = cfItemColorsDB.enableTrade,
	}

	-- Set checkboxes from pending state
	bagsCheck:SetChecked(pendingState.enableBags)
	bankCheck:SetChecked(pendingState.enableBank)
	characterCheck:SetChecked(pendingState.enableCharacter)
	inspectCheck:SetChecked(pendingState.enableInspect)
	lootCheck:SetChecked(pendingState.enableLoot)
	mailboxCheck:SetChecked(pendingState.enableMailbox)
	merchantCheck:SetChecked(pendingState.enableMerchant)
	professionsCheck:SetChecked(pendingState.enableProfessions)
	questCheck:SetChecked(pendingState.enableQuest)
	questObjectiveCheck:SetChecked(pendingState.enableQuestObjective)
	tradeCheck:SetChecked(pendingState.enableTrade)
end

-- Initialize immediately (fixes OnShow not firing on first open)
initializeCheckboxes()

-- OnShow: Refresh checkboxes from database
panel:SetScript("OnShow", initializeCheckboxes)

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
