-- Early exit if bag addon detected
local isActive, addonName = cfItemColors.IsBagAddonActive()
if isActive then
	print("cfItemColors: Bag addon detected (" .. addonName .. "), bank module disabled")
	return
end

-- WoW API Constants
local BANK_CONTAINER = BANK_CONTAINER -- -1 (bank container Id)

-- Module Constants
local NUM_BANK_SLOTS = 24

-- Cache bank slot button references to avoid repeated _G lookups
local bankSlotButtonCache = {}
for i = 1, NUM_BANK_SLOTS do
	bankSlotButtonCache[i] = _G["BankFrameItem" .. i]
end

-- Updates a single bank container slot with quality color
local function updateSingleBankSlot(slotId)
	if slotId < 1 or slotId > NUM_BANK_SLOTS then return end

	local bankSlotButton = bankSlotButtonCache[slotId]
	if not bankSlotButton then return end

	local containerItemId = C_Container.GetContainerItemId(BANK_CONTAINER, slotId)
	cfItemColors.applyQualityColorWithQuestCheck(bankSlotButton, containerItemId)
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


