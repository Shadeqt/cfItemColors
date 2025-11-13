cfItemColors.Compatibility = {}

-- Raw bag addon names (readable format with spaces/hyphens/numbers)
local RAW_BAG_ADDON_NAMES = {
	"Bagnon",
	"Baganator",
	"ArkInventory",
	"AdiBags",
	"BetterBags",
	"OneBag3",
	"Bagnonium",
	"Baggins",
	"BankItems",
	"BankStack",
	"OneBank3",
	"Inventorian",
	"Baud Bag",
	"Sorted",
	"LiteBag",
}

-- Raw auction house addon names
local RAW_AH_ADDON_NAMES = {
	"Auctionator",
	"TradeSkillMaster",
	"Auctioneer",
	"AuctionMaster",
	"aux",
	"AuctionLite",
	"AuctionBuddy",
	"AuctionFaster",
}

-- Normalizes addon name for comparison (trim, lowercase, strip separators/numbers)
local function normalizeAddonName(str)
	return str:gsub("^%s*(.-)%s*$", "%1"):lower():gsub("[%s%-_%d]", "")
end

-- Generate normalized whitelists at load time
local KNOWN_BAG_ADDONS = {}
for _, name in ipairs(RAW_BAG_ADDON_NAMES) do
	local normalized = normalizeAddonName(name)
	KNOWN_BAG_ADDONS[normalized] = true
end

local KNOWN_AH_ADDONS = {}
for _, name in ipairs(RAW_AH_ADDON_NAMES) do
	local normalized = normalizeAddonName(name)
	KNOWN_AH_ADDONS[normalized] = true
end

-- Map module names to their conflict detection whitelists
local MODULE_CONFLICT_MAP = {
	Bags = KNOWN_BAG_ADDONS,
	Bank = KNOWN_BAG_ADDONS,
	AuctionHouse = KNOWN_AH_ADDONS,
}

-- Checks if any addon from whitelist is active (returns isActive, addonName)
local function isAddonTypeActive(whitelist)
	for i = 1, C_AddOns.GetNumAddOns() do
		if C_AddOns.IsAddOnLoaded(i) then
			local name = C_AddOns.GetAddOnInfo(i)

			-- Gather all metadata fields
			local fields = {
				name,
				C_AddOns.GetAddOnMetadata(i, "Title"),
				C_AddOns.GetAddOnMetadata(i, "Notes"),
				C_AddOns.GetAddOnMetadata(i, "X-Notes"),
				C_AddOns.GetAddOnMetadata(i, "Category"),
				C_AddOns.GetAddOnMetadata(i, "X-Category"),
			}

			-- Check each field against whitelist
			for _, field in ipairs(fields) do
				if field then
					local normalized = normalizeAddonName(field)

					-- Check if normalized field contains any whitelist entry
					for addonName, _ in pairs(whitelist) do
						if normalized:find(addonName, 1, true) then
							return true, name
						end
					end
				end
			end
		end
	end

	return false, nil
end

-- Determines if module should load based on settings and conflicts (returns enabled, conflict)
function cfItemColors.Compatibility.ShouldModuleLoad(moduleName)
	-- Get user preference from DB
	local userEnabled = cfItemColorsDB[moduleName]

	if not userEnabled then
		return false, nil  -- User disabled, no message needed
	end

	-- Check for conflicts using the mapping
	local conflictList = MODULE_CONFLICT_MAP[moduleName]
	if conflictList then
		local isConflict, addonName = isAddonTypeActive(conflictList)
		if isConflict then
			return false, addonName .. " detected"
		end
	end

	return true, nil
end
