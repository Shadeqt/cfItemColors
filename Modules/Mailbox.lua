local db = cfItemColorsDB
local addon = cfItemColors

-- WoW constants
local INBOXITEMS_TO_DISPLAY = INBOXITEMS_TO_DISPLAY -- 7
local ATTACHMENTS_MAX_SEND = ATTACHMENTS_MAX_SEND -- 12
local ATTACHMENTS_MAX_RECEIVE = ATTACHMENTS_MAX_RECEIVE -- 16

-- Updates inbox mail buttons based on highest quality attachment
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

		addon.applyQualityColor(button, bestItemLink)
	end
end

-- Updates send mail attachment buttons
local function updateSendMailItems()
	for i = 1, ATTACHMENTS_MAX_SEND do
		local button = _G["SendMailAttachment" .. i]
		local itemLink = GetSendMailItemLink(i)
		addon.applyQualityColor(button, itemLink)
	end
end

-- Updates open mail attachment buttons
local function updateOpenMailItems()
	local mailId = InboxFrame and InboxFrame.openMailID
	if not mailId then return end

	for i = 1, ATTACHMENTS_MAX_RECEIVE do
		local button = _G["OpenMailAttachmentButton" .. i]
		local itemLink = GetInboxItemLink(mailId, i)
		addon.applyQualityColor(button, itemLink)
	end
end

-- Deferred initialization function (called after init completes)
local function initializeMailboxModule()
	-- Module enable check
	if not db[addon.MODULES.MAILBOX].enabled then return end

	-- Update colors on mailbox changes - inbox, send form, and sent mail
	local eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")  		-- Inbox changes
	eventFrame:RegisterEvent("MAIL_SEND_INFO_UPDATE")  	-- Send form updated
	eventFrame:RegisterEvent("MAIL_SEND_SUCCESS")  		-- Mail sent successfully

	eventFrame:SetScript("OnEvent", function(_, event)
		if event == "MAIL_INBOX_UPDATE" then
			updateInboxItems()
		elseif event == "MAIL_SEND_INFO_UPDATE" or event == "MAIL_SEND_SUCCESS" then
			updateSendMailItems()
		end
	end)

	hooksecurefunc("OpenMail_Update", updateOpenMailItems)  -- Opened mail updates
end

-- Register to wait for init completion
addon:registerInitListener(initializeMailboxModule)
