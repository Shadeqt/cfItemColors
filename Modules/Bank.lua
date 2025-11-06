local isConflict, conflictingAddon = cfItemColors.Compatibility.IsBagAddonActive()
if isConflict then
	print(conflictingAddon .. " has been detected. CfItemColors disabled bank module.")
	return
end

-- Shared dependencies
local applyQualityColor = cfItemColors.applyQualityColor

-- WoW constants
local BANK_CONTAINER = BANK_CONTAINER -- -1, bank container ID representing main bank storage

-- Module constants
local NUM_BANK_SLOTS = 24 -- 24, total slots in main bank container (excludes bag slots)

-- Updates a single bank slot with quality color
local function updateSingleBankSlot(slotId)
	local bankSlotButton = _G["BankFrameItem" .. slotId]
	local containerItemId = C_Container.GetContainerItemID(BANK_CONTAINER, slotId)
	applyQualityColor(bankSlotButton, containerItemId)
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
