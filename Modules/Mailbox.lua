-- Shared dependencies
local applyQualityColor = cfItemColors.applyQualityColor

-- WoW constants
local INBOXITEMS_TO_DISPLAY = INBOXITEMS_TO_DISPLAY -- 7, inbox items per page
local ATTACHMENTS_MAX_SEND = ATTACHMENTS_MAX_SEND -- 12, max attachments when sending mail
local ATTACHMENTS_MAX_RECEIVE = ATTACHMENTS_MAX_RECEIVE -- 16, max attachments when receiving mail

-- Module states
local inboxButtonCache = {}
local sendMailButtonCache = {}
local openMailButtonCache = {}

for i = 1, INBOXITEMS_TO_DISPLAY do
	inboxButtonCache[i] = _G["MailItem" .. i .. "Button"]
end

for i = 1, ATTACHMENTS_MAX_SEND do
	sendMailButtonCache[i] = _G["SendMailAttachment" .. i]
end

for i = 1, ATTACHMENTS_MAX_RECEIVE do
	openMailButtonCache[i] = _G["OpenMailAttachmentButton" .. i]
end

local function updateInboxItems()
	local numItems = GetInboxNumItems()
	local pageOffset = ((InboxFrame and InboxFrame.pageNum or 1) - 1) * INBOXITEMS_TO_DISPLAY

	for i = 1, INBOXITEMS_TO_DISPLAY do
		local button = inboxButtonCache[i]
		if button then
			local mailIndex = pageOffset + i
			if mailIndex <= numItems then
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
			else
				applyQualityColor(button, nil)
			end
		end
	end
end

-- Update send mail attachment colors
local function updateSendMailItems()
	for i = 1, ATTACHMENTS_MAX_SEND do
		local button = sendMailButtonCache[i]
		if button then
			local itemLink = GetSendMailItemLink(i)
			applyQualityColor(button, itemLink)
		end
	end
end

-- Update open mail attachment colors
local function updateOpenMailItems()
	if not InboxFrame or not InboxFrame.openMailId then
		return
	end

	local mailId = InboxFrame.openMailId
	for i = 1, ATTACHMENTS_MAX_RECEIVE do
		local button = openMailButtonCache[i]
		if button then
			local itemLink = GetInboxItemLink(mailId, i)
			applyQualityColor(button, itemLink)
		end
	end
end

-- Clear all mailbox colors
local function clearAllMailboxColors()
	for i = 1, INBOXITEMS_TO_DISPLAY do
		local button = inboxButtonCache[i]
		if button then
			applyQualityColor(button, nil)
		end
	end

	for i = 1, ATTACHMENTS_MAX_SEND do
		local button = sendMailButtonCache[i]
		if button then
			applyQualityColor(button, nil)
		end
	end

	for i = 1, ATTACHMENTS_MAX_RECEIVE do
		local button = openMailButtonCache[i]
		if button then
			applyQualityColor(button, nil)
		end
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
	if event == "MAIL_SHOW" then
		-- Mailbox opened - update both inbox and send mail
		updateInboxItems()
		updateSendMailItems()
		updateOpenMailItems()
		
	elseif event == "MAIL_INBOX_UPDATE" then
		-- Inbox updated - refresh inbox items
		updateInboxItems()
		updateOpenMailItems()
		
	elseif event == "MAIL_SEND_INFO_UPDATE" then
		-- Send mail updated - refresh send mail attachments
		updateSendMailItems()
		
	elseif event == "MAIL_SUCCESS" then
		-- Mail operation completed - refresh both send mail and open mail items
		updateSendMailItems()
		updateOpenMailItems()
		
	elseif event == "MAIL_SEND_SUCCESS" then
		-- Mail sent successfully - clear send mail attachments
		updateSendMailItems()
		
	-- MAIL_CLOSED event removed - no need to clear colors since we recolor on open
	end
end)

-- Hook into OpenMail frame show to update colors
local function hookOpenMailFrame()
	if OpenMailFrame then
		local originalShow = OpenMailFrame.Show
		OpenMailFrame.Show = function(self, ...)
			if originalShow then
				originalShow(self, ...)
			else
				self:Show()
			end
			-- Update colors immediately
			updateOpenMailItems()
		end
	end
end

-- Hook when addon loads or when OpenMailFrame becomes available
if OpenMailFrame then
	hookOpenMailFrame()
else
	local hookFrame = CreateFrame("Frame")
	hookFrame:RegisterEvent("ADDON_LOADED")
	hookFrame:SetScript("OnEvent", function(_, event, addonName)
		if OpenMailFrame then
			hookOpenMailFrame()
			hookFrame:UnregisterEvent("ADDON_LOADED")
		end
	end)
end