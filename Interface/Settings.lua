local panel = CreateFrame("Frame", "cfItemColorsSettingsPanel")
panel.name = "cfItemColors"
panel:Hide()

local addon = cfItemColors
local W = addon.Widgets
local M = addon.MODULES
local COL2 = 300
W.panel = panel

local T = W.TOOLTIPS
T[M.BAGS] = "Color item borders in your bags by rarity"
T[M.BANK] = "Color item borders in the bank window"
T[M.CHARACTER] = "Color equipped item borders on the character sheet"
T[M.INSPECT] = "Color equipped item borders on the inspect frame"
T[M.LOOT] = "Color item borders in the loot roll window"
T[M.MAILBOX] = "Color item borders in the inbox, send mail, and open mail windows"
T[M.MERCHANT] = "Color item borders on the vendor and buyback tabs"
T[M.PROFESSIONS] = "Color item borders in the tradeskill, craft, and class trainer windows"
T[M.QUEST] = "Color reward and required item borders in quest detail, progress, and quest log windows"
T[M.TRADE] = "Color item borders in the trade window"
T["activeQuestOnly"] = "Only highlight quest items tracked by Questie (requires Questie)"

-- Modules
local title = W.CreateTitle(panel, "cfItemColors")
local modulesHeader = W.CreateHeader(title, "Modules")
local modulesSection = W.CreateSection(modulesHeader)
local bags = W.CreateCheckbox(modulesSection, "Bags", M.BAGS)
local bank = W.CreateCheckbox(bags, "Bank", M.BANK, COL2)
local character = W.CreateCheckbox(bags, "Character", M.CHARACTER)
local inspect = W.CreateCheckbox(character, "Inspect", M.INSPECT, COL2)
local loot = W.CreateCheckbox(character, "Loot", M.LOOT)
local mailbox = W.CreateCheckbox(loot, "Mailbox", M.MAILBOX)
local merchant = W.CreateCheckbox(mailbox, "Merchant", M.MERCHANT)
local professions = W.CreateCheckbox(merchant, "Professions", M.PROFESSIONS)
local trade = W.CreateCheckbox(professions, "Trade", M.TRADE)
local quest = W.CreateCheckbox(trade, "Quest", M.QUEST)
local activeQuestOnly = W.CreateCheckbox(quest, "Active Questie Items Only", "activeQuestOnly", COL2, quest)

-- Reload UI
local reloadBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
reloadBtn:SetPoint("TOPLEFT", modulesSection.section, "BOTTOMLEFT", 0, -10)
reloadBtn:SetSize(120, 25)
reloadBtn:SetText("Reload UI")
reloadBtn:SetScript("OnClick", ReloadUI)

-- Register
local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name)
Settings.RegisterAddOnCategory(category)

SLASH_CFITEMCOLORS1 = "/cfic"
SlashCmdList["CFITEMCOLORS"] = function()
	Settings.OpenToCategory(category:GetID())
end
