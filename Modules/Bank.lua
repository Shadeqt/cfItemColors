local applyQualityColorWithQuestCheck = cfItemColors.ApplyQualityColorWithQuestCheck

-- Localized API calls
local _G = _G
local C_Container = C_Container
local BANK_CONTAINER = BANK_CONTAINER
local CreateFrame = CreateFrame

-- Constants
local NUM_BANK_SLOTS = 24

-- Cache button references to avoid repeated _G lookups
local slotButtonCache = {}
for i = 1, NUM_BANK_SLOTS do
	slotButtonCache[i] = _G["BankFrameItem" .. i]
end

-- Apply quality color to a single bank slot
local function UpdateSingleBankSlot(slotId)
	local bankSlotButton = slotButtonCache[slotId]
	if not bankSlotButton then return end

	local containerItemId = C_Container.GetContainerItemID(BANK_CONTAINER, slotId)
	applyQualityColorWithQuestCheck(bankSlotButton, containerItemId)
end

-- Apply quality colors to all bank slots
local function UpdateAllBankSlots()
	local numBankSlots = C_Container.GetContainerNumSlots(BANK_CONTAINER)
	for i = 1, numBankSlots do
		UpdateSingleBankSlot(i)
	end
end

-- Listen for bank events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("BANKFRAME_OPENED")
eventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
eventFrame:SetScript("OnEvent", function(_, event, slotId)
	if event == "BANKFRAME_OPENED" then
		UpdateAllBankSlots()
	elseif event == "PLAYERBANKSLOTS_CHANGED" then
		UpdateSingleBankSlot(slotId)
	end
end)
