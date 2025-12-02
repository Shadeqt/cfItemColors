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

-- Helper function to create a separator line
local function createSeparator(parent, anchorTo, width, yOffset)
	local separator = parent:CreateTexture(nil, "ARTWORK")
	separator:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, yOffset)
	separator:SetSize(width, 1)
	separator:SetColorTexture(0.5, 0.5, 0.5, 0.5)
	return separator
end

-- Check if pending state differs from saved database
local function hasUnsavedChanges()
	for moduleName, pending in pairs(pendingState) do
		if pending ~= db[moduleName].enabled then
			return true
		end
	end
	return false
end

-- Title
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("cfItemColors Settings")

local titleSeparator = createSeparator(panel, title, 500, -8)

-- Left column checkboxes
allCheckboxes.bagsCheck = createCheckbox(panel, titleSeparator, 0, -8, addon.MODULES.BAGS)
allCheckboxes.bankCheck = createCheckbox(panel, allCheckboxes.bagsCheck, 0, -8, addon.MODULES.BANK)
allCheckboxes.characterCheck = createCheckbox(panel, allCheckboxes.bankCheck, 0, -8, addon.MODULES.CHARACTER)
allCheckboxes.inspectCheck = createCheckbox(panel, allCheckboxes.characterCheck, 0, -8, addon.MODULES.INSPECT)
allCheckboxes.lootCheck = createCheckbox(panel, allCheckboxes.inspectCheck, 0, -8, addon.MODULES.LOOT)

-- Right column checkboxes
allCheckboxes.merchantCheck = createCheckbox(panel, titleSeparator, 250, -8, addon.MODULES.MERCHANT)
allCheckboxes.professionsCheck = createCheckbox(panel, allCheckboxes.merchantCheck, 0, -8, addon.MODULES.PROFESSIONS)
allCheckboxes.questCheck = createCheckbox(panel, allCheckboxes.professionsCheck, 0, -8, addon.MODULES.QUEST)
allCheckboxes.questObjectiveCheck = createCheckbox(panel, allCheckboxes.questCheck, 0, -8, addon.MODULES.QUEST_OBJECTIVE)

-- Explanatory note for Quest Objectives
local questObjNote = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
questObjNote:SetPoint("TOPLEFT", allCheckboxes.questObjectiveCheck, "BOTTOMLEFT", 4, 0)
questObjNote:SetText("|cffffffffDetects common items (materials, reagents, etc.) needed for active quests|r")

local section1Separator = createSeparator(panel, allCheckboxes.lootCheck, 500, -8)

-- Group 2 Header: Player Trading
local group2Header = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
group2Header:SetPoint("TOPLEFT", section1Separator, "BOTTOMLEFT", 0, -8)
group2Header:SetText("Player Trading:")

-- Group 2 checkboxes (Player trading features) - in columns
allCheckboxes.tradeCheck = createCheckbox(panel, group2Header, 0, -8, addon.MODULES.TRADE)
allCheckboxes.mailboxCheck = createCheckbox(panel, group2Header, 250, -8, addon.MODULES.MAILBOX)

local section2Separator = createSeparator(panel, allCheckboxes.tradeCheck, 500, -8)

-- Reload UI button
local reloadBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
reloadBtn:SetPoint("TOPLEFT", section2Separator, "BOTTOMLEFT", 0, -8)
reloadBtn:SetSize(120, 25)
reloadBtn:SetText("Save Changes")
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
warning:SetText("Click '|cffffd100Save Changes|r' to apply")

-- Info text
local info = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
info:SetPoint("TOPLEFT", reloadBtn, "BOTTOMLEFT", 4, -8)
info:SetText("Type |cffffffff/cfic|r to open this panel")

-- Initializes all checkboxes from database with conflict detection
local function initializeCheckboxes()
	-- Hide warning initially (no unsaved changes)
	warning:Hide()

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
			check.Text:SetTextColor(0.5, 0.5, 0.5)

			-- Create warning text if not already created
			if not check.warningText then
				check.warningText = check:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
				check.warningText:SetPoint("LEFT", check.Text, "RIGHT", 4, 0)
			end
			check.warningText:SetText("(" .. conflict .. ")")
		else
			-- No conflict - set checked state from DB and enable checkbox
			check:SetChecked(enabled)
			check:Enable()

			check:SetScript("OnClick", function(self)
				pendingState[self.moduleName] = self:GetChecked()
				if hasUnsavedChanges() then warning:Show() else warning:Hide() end
			end)

			-- Hide warning text if it exists
			if check.warningText then
				check.warningText:SetText("")
			end
		end
	end
end

-- Initialize interface checkboxes after init completes
-- (Must wait for self-found detection to complete before reading DB)
addon:registerInitListener(initializeCheckboxes)

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
