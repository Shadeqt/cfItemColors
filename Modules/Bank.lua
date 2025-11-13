local db = cfItemColorsDB
local addon = cfItemColors

-- Module enable check
if not db[addon.MODULES.BANK].enabled then return end

-- WoW constants
local BANK_CONTAINER = BANK_CONTAINER -- -1, bank container ID representing main bank storage

-- Module constants
local NUM_BANK_SLOTS = 24 -- 24, total slots in main bank container (excludes bag slots)

-- Updates a single bank container slot with quality color
local function updateSingleBankSlot(slotId)
	local bankSlotButton = _G["BankFrameItem" .. slotId]
	if not bankSlotButton then return end

	local containerItemId = C_Container.GetContainerItemID(BANK_CONTAINER, slotId)
	addon.applyQualityColor(bankSlotButton, containerItemId)
end

-- Updates all bank container slots
local function updateAllBankSlots()
	for i = 1, NUM_BANK_SLOTS do
		updateSingleBankSlot(i)
	end
end

-- Process bank changes and window opening events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")  	-- Bank container changes
eventFrame:RegisterEvent("BANKFRAME_OPENED")  			-- Bank window opened
eventFrame:SetScript("OnEvent", function(_, event, slotId)
	if event == "PLAYERBANKSLOTS_CHANGED" then
		updateSingleBankSlot(slotId)
	elseif event == "BANKFRAME_OPENED" then
		updateAllBankSlots()
	end
end)
