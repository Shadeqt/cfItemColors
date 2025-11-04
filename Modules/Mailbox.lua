-- Shared dependencies
local applyQualityColor = cfItemColors.applyQualityColor

-- WoW constants
local INBOXITEMS_TO_DISPLAY = INBOXITEMS_TO_DISPLAY -- 7, inbox items per page
local ATTACHMENTS_MAX_SEND = ATTACHMENTS_MAX_SEND -- 12, max attachments when sending mail
local ATTACHMENTS_MAX_RECEIVE = ATTACHMENTS_MAX_RECEIVE -- 16, max attachments when receiving mail

local function updateInboxItems()
	local numItems = GetInboxNumItems()
	local pageOffset = ((InboxFrame and InboxFrame.pageNum or 1) - 1) * INBOXITEMS_TO_DISPLAY

	for i = 1, INBOXITEMS_TO_DISPLAY do
		local button = _G["MailItem" .. i .. "Button"]
		local mailIndex = pageOffset + i

		-- Find highest quality item in this mail
		local bestItemLink = nil
		local bestQuality = -1

		-- Check all possible attachments in this mail
		for j = 1, ATTACHMENTS_MAX_RECEIVE do
			local name, itemTexture, count, quality, canUse = GetInboxItem(mailIndex, j)
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

-- Event frame for mailbox monitoring
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
eventFrame:RegisterEvent("MAIL_SEND_INFO_UPDATE")
eventFrame:RegisterEvent("MAIL_SUCCESS")
eventFrame:RegisterEvent("MAIL_SEND_SUCCESS")

-- Handle mailbox events
eventFrame:SetScript("OnEvent", function(_, event)
	print("Mailbox event:", event)
	if event == "MAIL_SHOW" then
		updateInboxItems()
		updateSendMailItems()
		updateOpenMailItems()
	elseif event == "MAIL_INBOX_UPDATE" then
		updateInboxItems()
		updateOpenMailItems()
	elseif event == "MAIL_SEND_INFO_UPDATE" then
		updateSendMailItems()
	elseif event == "MAIL_SUCCESS" then
		updateSendMailItems()
		updateOpenMailItems()
	elseif event == "MAIL_SEND_SUCCESS" then
		updateSendMailItems()
	end
end)

-- Hook into OpenMailFrame update to handle opened mail
hooksecurefunc("OpenMail_Update", updateOpenMailItems)
