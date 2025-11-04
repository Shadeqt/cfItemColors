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

-- Normalizes addon names: trim, lowercase, strip separators/numbers
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

-- Generic function to check if any addon in a whitelist is active
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

-- Public API functions
function cfItemColors.Compatibility.IsBagAddonActive()
	return isAddonTypeActive(KNOWN_BAG_ADDONS)
end

function cfItemColors.Compatibility.IsAuctionAddonActive()
	return isAddonTypeActive(KNOWN_AH_ADDONS)
end
