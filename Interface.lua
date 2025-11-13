local db = cfItemColorsDB
local addon = cfItemColors

-- Settings panel frame
local panel = CreateFrame("Frame", "cfItemColorsPanel")
panel.name = "cfItemColors"

-- Module state
local allCheckboxes = {}
local pendingState = {}

-- Creates a checkbox for a module (conflict detection deferred to initialization)
local function createCheckbox(parent, anchorTo, xOffset, yOffset, moduleName)
	local check = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
	check:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", xOffset, yOffset)
	check.Text:SetText(moduleName)
	check.moduleName = moduleName -- Store module name

	-- OnClick handler will be set during initialization if no conflict
	return check
end

-- Title
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("cfItemColors Settings")

-- Left column checkboxes
allCheckboxes.bagsCheck = createCheckbox(panel, title, 0, -16, addon.MODULES.BAGS)
allCheckboxes.bankCheck = createCheckbox(panel, allCheckboxes.bagsCheck, 0, -8, addon.MODULES.BANK)
allCheckboxes.characterCheck = createCheckbox(panel, allCheckboxes.bankCheck, 0, -8, addon.MODULES.CHARACTER)
allCheckboxes.inspectCheck = createCheckbox(panel, allCheckboxes.characterCheck, 0, -8, addon.MODULES.INSPECT)
allCheckboxes.lootCheck = createCheckbox(panel, allCheckboxes.inspectCheck, 0, -8, addon.MODULES.LOOT)

-- Right column checkboxes
allCheckboxes.merchantCheck = createCheckbox(panel, title, 250, -16, addon.MODULES.MERCHANT)
allCheckboxes.professionsCheck = createCheckbox(panel, allCheckboxes.merchantCheck, 0, -8, addon.MODULES.PROFESSIONS)
allCheckboxes.questCheck = createCheckbox(panel, allCheckboxes.professionsCheck, 0, -8, addon.MODULES.QUEST)
allCheckboxes.questObjectiveCheck = createCheckbox(panel, allCheckboxes.questCheck, 0, -8, addon.MODULES.QUEST_OBJECTIVE)

-- Explanatory note for Quest Objectives
local questObjNote = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
questObjNote:SetPoint("TOPLEFT", allCheckboxes.questObjectiveCheck, "BOTTOMLEFT", 20, -2)
questObjNote:SetTextColor(0.7, 0.7, 0.7)
questObjNote:SetText("Detects common items (materials, reagents, etc.) needed for active quests")

-- Group 2 Header: Player Trading
local group2Header = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
group2Header:SetPoint("TOPLEFT", allCheckboxes.lootCheck, "BOTTOMLEFT", 0, -16)
group2Header:SetText("|cffFFD700Player Trading:|r")

-- Group 2 checkboxes (Player trading features) - in columns
allCheckboxes.tradeCheck = createCheckbox(panel, group2Header, 0, -8, addon.MODULES.TRADE)
allCheckboxes.mailboxCheck = createCheckbox(panel, group2Header, 250, -8, addon.MODULES.MAILBOX)

-- Reload UI button
local reloadBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
reloadBtn:SetPoint("TOPLEFT", allCheckboxes.tradeCheck, "BOTTOMLEFT", 0, -16)
reloadBtn:SetSize(120, 25)
reloadBtn:SetText("Reload UI")
reloadBtn:SetScript("OnClick", function()
	-- Commit pending changes to database
	for moduleName, enabled in pairs(pendingState) do
		db[moduleName].enabled = enabled
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

-- Initializes all checkboxes from database with conflict detection
local function initializeCheckboxes()
	-- Clear and repopulate pending state from database
	for k in pairs(pendingState) do
		pendingState[k] = nil
	end
	for _, moduleName in pairs(addon.MODULES) do
		local moduleData = db[moduleName]
		pendingState[moduleName] = moduleData.enabled
	end

	-- Configure each checkbox with conflict detection
	for _, check in pairs(allCheckboxes) do
		local moduleData = db[check.moduleName]
		local enabled, conflict = moduleData.enabled, moduleData.conflict

		if conflict then
			-- Conflict detected - uncheck and disable checkbox, add warning
			check:SetChecked(false)
			check:Disable()

			-- Gray out the label text
			check.Text:SetTextColor(0.5, 0.5, 0.5)

			-- Create warning text if not already created
			if not check.warningText then
				check.warningText = check:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
				check.warningText:SetPoint("LEFT", check.Text, "RIGHT", 4, 0)
			end
			check.warningText:SetText("|cffFF7F00(" .. conflict .. ")|r")
		else
			-- No conflict - set checked state from DB and enable checkbox
			check:SetChecked(enabled)
			check:Enable()

			-- Restore normal label text color
			check.Text:SetTextColor(1.0, 1.0, 1.0)

			check:SetScript("OnClick", function(self)
				pendingState[self.moduleName] = self:GetChecked()
			end)

			-- Hide warning text if it exists
			if check.warningText then
				check.warningText:SetText("")
			end
		end
	end
end

-- Initialize interface checkboxes when all addons loaded
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", initializeCheckboxes)

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
	end
end
