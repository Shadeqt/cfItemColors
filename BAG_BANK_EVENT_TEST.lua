local addon = cfItemColors

-- WoW API calls
local _CreateFrame = CreateFrame
local _C_Container = C_Container
local _C_Timer = C_Timer
local _IsBagOpen = IsBagOpen
local _GetTime = GetTime

-- Constants
local NUM_BAG_SLOTS = NUM_BAG_SLOTS
local NUM_BANKBAGSLOTS = NUM_BANKBAGSLOTS
local BANK_CONTAINER = BANK_CONTAINER

print("=== BAG AND BANK EVENT INVESTIGATION LOADED ===")
print("This module will log ALL bag and bank related events")
print("Watch your chat for detailed event information")
print("================================================")

-- Event tracking frame
local investigationFrame = _CreateFrame("Frame")

-- All possible bag and bank related events for Classic Era
local BAG_EVENTS = {
	-- Bag content events
	"BAG_UPDATE",
	"BAG_UPDATE_DELAYED",
	"BAG_UPDATE_COOLDOWN",

	-- Bag slot events
	"BAG_NEW_ITEMS_UPDATED",
	"BAG_SLOT_FLAGS_UPDATED",
	"ITEM_LOCK_CHANGED",
	"ITEM_LOCKED",
	"ITEM_UNLOCKED",

	-- Bank events
	"BANKFRAME_OPENED",
	"BANKFRAME_CLOSED",
	"PLAYERBANKSLOTS_CHANGED",
	"PLAYERBANKBAGSLOTS_CHANGED",

	-- Container events
	"ITEM_PUSH",
	"BAG_CONTAINER_UPDATE",

	-- Inventory events that might affect bags
	"UNIT_INVENTORY_CHANGED",
	"PLAYER_EQUIPMENT_CHANGED",

	-- Player entering world (for initialization)
	"PLAYER_ENTERING_WORLD",

	-- Additional container events
	"BAG_CLOSED",
	"BAG_OPEN",
}

-- Event counter
local eventCounts = {}
for _, event in ipairs(BAG_EVENTS) do
	eventCounts[event] = 0
end

-- Register all events
for _, event in ipairs(BAG_EVENTS) do
	investigationFrame:RegisterEvent(event)
	print("|cff00ff00Registered:|r " .. event)
end

-- Helper function to get bag info
local function getBagInfo(bagId)
	if not bagId then return "nil" end

	local numSlots = _C_Container.GetContainerNumSlots(bagId)
	local freeSlots = _C_Container.GetContainerNumFreeSlots(bagId)
	local isOpen = _IsBagOpen(bagId)
	local openStatus = isOpen and "OPEN" or "CLOSED"

	local bagType = "unknown"
	if bagId == 0 then
		bagType = "BACKPACK"
	elseif bagId == BANK_CONTAINER then
		bagType = "BANK"
	elseif bagId >= 1 and bagId <= NUM_BAG_SLOTS then
		bagType = "BAG"
	elseif bagId >= (NUM_BAG_SLOTS + 1) and bagId <= (NUM_BAG_SLOTS + NUM_BANKBAGSLOTS) then
		bagType = "BANK_BAG"
	end

	return string.format("%s [ID:%d, Slots:%d/%d, %s]", bagType, bagId, numSlots - freeSlots, numSlots, openStatus)
end

-- Helper function to get item info
local function getItemInfo(bagId, slotId)
	if not bagId or not slotId then return "nil" end

	local itemId = _C_Container.GetContainerItemID(bagId, slotId)
	if not itemId then return "empty" end

	local containerInfo = _C_Container.GetContainerItemInfo(bagId, slotId)
	if not containerInfo then return "itemId:" .. itemId .. " (no info)" end

	local itemLink = containerInfo.hyperlink
	local itemName = itemLink and itemLink:match("%[(.-)%]") or "unknown"
	local stackCount = containerInfo.stackCount or 0
	local quality = containerInfo.quality or 0

	return string.format("%s (x%d, q%d, id:%d)", itemName, stackCount, quality, itemId)
end

-- Event handler with detailed logging
investigationFrame:SetScript("OnEvent", function(self, event, ...)
	local arg1, arg2, arg3, arg4 = ...
	eventCounts[event] = (eventCounts[event] or 0) + 1

	local timestamp = string.format("[%.2f]", _GetTime())
	local countInfo = string.format("[#%d]", eventCounts[event])

	print("|cffff9900" .. timestamp .. " " .. countInfo .. " |cff00ffff" .. event .. "|r")

	-- Event-specific detailed logging
	if event == "BAG_UPDATE" then
		local bagId = arg1
		print("  |cffffaa00Bag Updated:|r " .. getBagInfo(bagId))

		-- List all items in the updated bag
		if bagId then
			local numSlots = _C_Container.GetContainerNumSlots(bagId)
			if numSlots and numSlots > 0 then
				print("  |cffaaaaaa  Contents:|r")
				for slotId = 1, numSlots do
					local itemInfo = getItemInfo(bagId, slotId)
					if itemInfo ~= "empty" then
						print("    |cffaaaaaa  Slot " .. slotId .. ":|r " .. itemInfo)
					end
				end
			end
		end

	elseif event == "BAG_UPDATE_DELAYED" then
		print("  |cffffaa00Info:|r All pending bag updates completed")

	elseif event == "BAG_UPDATE_COOLDOWN" then
		local bagId = arg1
		print("  |cffffaa00Bag Cooldown:|r " .. getBagInfo(bagId))

	elseif event == "BAG_NEW_ITEMS_UPDATED" then
		print("  |cffffaa00Info:|r New items flags updated")

	elseif event == "BAG_SLOT_FLAGS_UPDATED" then
		local bagId, slotId = arg1, arg2
		print("  |cffffaa00Slot Flags:|r " .. getBagInfo(bagId))
		print("  |cffffaa00  Slot:|r " .. (slotId or "nil") .. " - " .. getItemInfo(bagId, slotId))

	elseif event == "ITEM_LOCK_CHANGED" then
		local bagId, slotId = arg1, arg2
		if bagId and slotId then
			print("  |cffffaa00Item Lock:|r " .. getBagInfo(bagId))
			print("  |cffffaa00  Slot:|r " .. slotId .. " - " .. getItemInfo(bagId, slotId))
		else
			print("  |cffffaa00Equipment Lock:|r bagId=" .. tostring(bagId) .. ", slotId=" .. tostring(slotId))
		end

	elseif event == "ITEM_LOCKED" then
		local bagId, slotId = arg1, arg2
		if bagId and slotId then
			print("  |cffff6600Item LOCKED:|r " .. getBagInfo(bagId))
			print("  |cffff6600  Slot:|r " .. slotId .. " - " .. getItemInfo(bagId, slotId))
		else
			print("  |cffff6600Equipment LOCKED:|r bagId=" .. tostring(bagId) .. ", slotId=" .. tostring(slotId))
		end

	elseif event == "ITEM_UNLOCKED" then
		local bagId, slotId = arg1, arg2
		if bagId and slotId then
			print("  |cff66ff00Item UNLOCKED:|r " .. getBagInfo(bagId))
			print("  |cff66ff00  Slot:|r " .. slotId .. " - " .. getItemInfo(bagId, slotId))
		else
			print("  |cff66ff00Equipment UNLOCKED:|r bagId=" .. tostring(bagId) .. ", slotId=" .. tostring(slotId))
		end

	elseif event == "BANKFRAME_OPENED" then
		print("  |cff00ff00Bank Opened|r")
		local numSlots = _C_Container.GetContainerNumSlots(BANK_CONTAINER)
		print("  |cffffaa00Bank has " .. numSlots .. " slots|r")

	elseif event == "BANKFRAME_CLOSED" then
		print("  |cffff0000Bank Closed|r")

	elseif event == "PLAYERBANKSLOTS_CHANGED" then
		local slotId = arg1
		print("  |cffffaa00Bank Slot Changed:|r " .. slotId .. " - " .. getItemInfo(BANK_CONTAINER, slotId))

	elseif event == "PLAYERBANKBAGSLOTS_CHANGED" then
		local slotId = arg1
		print("  |cffffaa00Bank Bag Slot Changed:|r " .. slotId)

	elseif event == "ITEM_PUSH" then
		local bagId, iconFileID = arg1, arg2
		print("  |cffffaa00Item Pushed:|r " .. getBagInfo(bagId))
		print("  |cffffaa00  Icon:|r " .. tostring(iconFileID))

	elseif event == "BAG_CONTAINER_UPDATE" then
		print("  |cffff00ffContainer Update:|r All containers refreshed")

	elseif event == "UNIT_INVENTORY_CHANGED" then
		local unitTarget = arg1
		print("  |cffffaa00Unit:|r " .. tostring(unitTarget))

	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		local equipmentSlot, hasCurrent = arg1, arg2
		print("  |cffffaa00Equipment Slot:|r " .. tostring(equipmentSlot) .. ", Has Item: " .. tostring(hasCurrent))

	elseif event == "PLAYER_ENTERING_WORLD" then
		local isInitialLogin, isReloadingUi = arg1, arg2
		print("  |cffffaa00Initial Login:|r " .. tostring(isInitialLogin))
		print("  |cffffaa00Reloading UI:|r " .. tostring(isReloadingUi))

	elseif event == "BAG_CLOSED" then
		local bagId = arg1
		print("  |cffffaa00Bag Closed:|r " .. getBagInfo(bagId))

	elseif event == "BAG_OPEN" then
		local bagId = arg1
		print("  |cffffaa00Bag Opened:|r " .. getBagInfo(bagId))

	else
		-- Generic logging for any other events
		print("  |cffffaa00Args:|r " .. tostring(arg1) .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4))
	end
end)

-- Hook bag toggle functions
hooksecurefunc("ToggleBag", function(bagId)
	-- Check state after toggle completes
	_C_Timer.After(0.01, function()
		local isOpen = _IsBagOpen(bagId)
		local state = isOpen and "|cff00ff00OPENED|r" or "|cffff0000CLOSED|r"
		print("|cffff9900[Hook] ToggleBag|r → bagId: " .. tostring(bagId) .. " → " .. state)
	end)
end)

hooksecurefunc("ToggleBackpack", function()
	-- Check state after toggle completes
	_C_Timer.After(0.01, function()
		-- Count how many bags are actually open
		local openBagCount = 0
		for bagId = 0, NUM_BAG_SLOTS do
			if _IsBagOpen(bagId) then
				openBagCount = openBagCount + 1
			end
		end

		-- Check if it's "all bags" mode by looking at ContainerFrame1
		local containerFrame = _G["ContainerFrame1"]
		local isAllBagsMode = containerFrame and containerFrame.allBags

		if isAllBagsMode then
			local state = (openBagCount > 0) and "|cff00ff00ALL BAGS OPENED|r" or "|cffff0000ALL BAGS CLOSED|r"
			print("|cffff9900[Hook] ToggleBackpack|r → " .. state .. " (allBags mode, " .. openBagCount .. " bags open)")
		else
			local state = (openBagCount > 0) and "|cff00ff00BACKPACK OPENED|r" or "|cffff0000BACKPACK CLOSED|r"
			print("|cffff9900[Hook] ToggleBackpack|r → " .. state .. " (individual mode, " .. openBagCount .. " bags open)")
		end
	end)
end)

-- Hook additional bag functions that might be used for closing
if OpenBag then
	hooksecurefunc("OpenBag", function(bagId, forceUpdate)
		print("|cffff9900[Hook] OpenBag|r → bagId: " .. tostring(bagId) .. ", forceUpdate: " .. tostring(forceUpdate))
	end)
end

if CloseBag then
	hooksecurefunc("CloseBag", function(bagId)
		print("|cffff9900[Hook] CloseBag|r → bagId: " .. tostring(bagId))
	end)
end

if CloseAllBags then
	hooksecurefunc("CloseAllBags", function()
		print("|cffff9900[Hook] CloseAllBags|r")
	end)
end

if OpenAllBags then
	hooksecurefunc("OpenAllBags", function(forceUpdate)
		print("|cffff9900[Hook] OpenAllBags|r → forceUpdate: " .. tostring(forceUpdate))
	end)
end

print("|cff00ff00Bag/Bank investigation ready - events will print to chat|r")
