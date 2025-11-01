local isActive, addonName = cfItemColors.IsBagAddonActive()
if isActive then
	print("cfItemColors: Bag addon detected (" .. addonName .. "), bank module disabled")
	return
end

-- Shared dependencies
local applyQualityColorWithQuestCheck = cfItemColors.applyQualityColorWithQuestCheck

-- WoW constants
local BANK_CONTAINER = BANK_CONTAINER -- -1, bank container ID representing main bank storage

-- Module constants
local NUM_BANK_SLOTS = 24 -- 24, total slots in main bank container (excludes bag slots)

-- Module states
local bankSlotButtonCache = {}
for i = 1, NUM_BANK_SLOTS do
	bankSlotButtonCache[i] = _G["BankFrameItem" .. i]
end

local function updateSingleBankSlot(slotId)
	if slotId < 1 or slotId > NUM_BANK_SLOTS then return end

	local bankSlotButton = bankSlotButtonCache[slotId]
	if not bankSlotButton then return end

	local containerItemId = C_Container.GetContainerItemId(BANK_CONTAINER, slotId)
	applyQualityColorWithQuestCheck(bankSlotButton, containerItemId)
end

-- Updates all bank container slots with quality colors
local function updateAllBankSlots()
	for i = 1, NUM_BANK_SLOTS do
		updateSingleBankSlot(i)
	end
end

-- Events needed for bank container coverage
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")  -- Bank container (Id:-1)
eventFrame:RegisterEvent("BANKFRAME_OPENED")         -- Bank window opened

-- Processes bank changes and window opening
eventFrame:SetScript("OnEvent", function(_, event, slotId)
	if event == "PLAYERBANKSLOTS_CHANGED" then
		updateSingleBankSlot(slotId)
	elseif event == "BANKFRAME_OPENED" then
		updateAllBankSlots()
	end
end)


