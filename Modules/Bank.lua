-- Main coloring function from parent module
local applyQualityColorWithQuestCheck = cfItemColors.applyQualityColorWithQuestCheck

-- Localized WoW API calls for performance
local _GetContainerItemID = C_Container.GetContainerItemID
local _IsBagOpen = IsBagOpen
local _CreateFrame = CreateFrame
local _hooksecurefunc = hooksecurefunc
local _G = _G

-- WoW constants
local BANK_CONTAINER = BANK_CONTAINER  -- -1 (bank container ID)

-- Constants
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

	local containerItemId = _GetContainerItemID(BANK_CONTAINER, slotId)
	applyQualityColorWithQuestCheck(bankSlotButton, containerItemId)
end

-- Updates all bank container slots with quality colors
local function updateAllBankSlots()
	for slotId = 1, NUM_BANK_SLOTS do
		updateSingleBankSlot(slotId)
	end
end

-- Events needed for bank container coverage
local eventFrame = _CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")  -- Bank container (ID:-1)
eventFrame:RegisterEvent("BANKFRAME_OPENED")         -- Bank window opened

-- Processes bank changes and window opening
eventFrame:SetScript("OnEvent", function(_, event, slotId)
	if event == "PLAYERBANKSLOTS_CHANGED" then
		updateSingleBankSlot(slotId)
	elseif event == "BANKFRAME_OPENED" then
		updateAllBankSlots()
	end
end)


