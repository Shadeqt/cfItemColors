-- Module enable check
local enabled = cfItemColors.Init.GetModuleState(cfItemColors.Init.MODULES.MAILBOX)
if not enabled then return end

local applyQualityColor = cfItemColors.applyQualityColor

-- WoW API constants
local INBOXITEMS_TO_DISPLAY = INBOXITEMS_TO_DISPLAY -- 7
local ATTACHMENTS_MAX_SEND = ATTACHMENTS_MAX_SEND -- 12
local ATTACHMENTS_MAX_RECEIVE = ATTACHMENTS_MAX_RECEIVE -- 16

-- Update inbox mail item colors based on highest quality attachment
local function updateInboxItems()
	local numItems = GetInboxNumItems()
	local pageOffset = ((InboxFrame and InboxFrame.pageNum or 1) - 1) * INBOXITEMS_TO_DISPLAY
	local itemsOnPage = math.min(INBOXITEMS_TO_DISPLAY, numItems - pageOffset)

	for i = 1, itemsOnPage do
		local button = _G["MailItem" .. i .. "Button"]
		local mailIndex = pageOffset + i

		local bestItemLink = nil
		local bestQuality = -1

		-- Check all attachment slots (items don't shift when removed)
		for j = 1, ATTACHMENTS_MAX_RECEIVE do
			local name, _, _, _, quality = GetInboxItem(mailIndex, j)
			if name and quality and quality > bestQuality then
				bestQuality = quality
				bestItemLink = GetInboxItemLink(mailIndex, j)
			end
		end

		applyQualityColor(button, bestItemLink)
	end
end

-- Update send mail attachment colors
local function updateSendMailItems()
	for i = 1, ATTACHMENTS_MAX_SEND do
		local button = _G["SendMailAttachment" .. i]
		local itemLink = GetSendMailItemLink(i)
		applyQualityColor(button, itemLink)
	end
end

-- Update open mail attachment colors
local function updateOpenMailItems()
	local mailId = InboxFrame and InboxFrame.openMailID
	if not mailId then return end

	for i = 1, ATTACHMENTS_MAX_RECEIVE do
		local button = _G["OpenMailAttachmentButton" .. i]
		local itemLink = GetInboxItemLink(mailId, i)
		applyQualityColor(button, itemLink)
	end
end

-- Register mailbox events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
eventFrame:RegisterEvent("MAIL_SEND_INFO_UPDATE")
eventFrame:RegisterEvent("MAIL_SEND_SUCCESS")

eventFrame:SetScript("OnEvent", function(_, event)
	if event == "MAIL_INBOX_UPDATE" then
		updateInboxItems()
	elseif event == "MAIL_SEND_INFO_UPDATE" or event == "MAIL_SEND_SUCCESS" then
		updateSendMailItems()
	end
end)

-- Update opened mail attachments
hooksecurefunc("OpenMail_Update", updateOpenMailItems)
