local Widgets = {}
cfItemColors.Widgets = Widgets

local TOOLTIPS = {}
Widgets.TOOLTIPS = TOOLTIPS

function Widgets.CreateTitle(anchor, text)
	local fontString = anchor:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	fontString:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
	fontString:SetText(text)
	local separator = Widgets.CreateSeparator(fontString)
	return separator
end

function Widgets.CreateHeader(anchor, text)
	local anchorFrame = anchor.section or anchor
	local parent = anchorFrame:GetParent() or anchorFrame
	local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fontString:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -10)
	fontString:SetText(text)
	return fontString
end

function Widgets.CreateSeparator(anchor)
	local parent = anchor:GetParent() or anchor
	local separator = parent:CreateTexture(nil, "ARTWORK")
	separator:SetHeight(1)
	separator:SetColorTexture(0.5, 0.5, 0.5, 0.5)
	separator:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
	separator:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
	return separator
end

local function FitToContent(interior, padding)
	local section = interior:GetParent()
	local sectionTop = section:GetTop()
	if not sectionTop then return end
	local lowestBottom = sectionTop
	for _, child in pairs({section:GetChildren()}) do
		local childBottom = child:GetBottom()
		if childBottom and childBottom < lowestBottom then
			lowestBottom = childBottom
		end
	end
	section:SetHeight(sectionTop - lowestBottom + (padding or 10))
end

function Widgets.CreateSection(anchor)
	local parent = anchor:GetParent() or anchor
	local section = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	section:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
	section:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
	section:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	section:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)

	local interior = CreateFrame("Frame", nil, section)
	interior:SetPoint("TOPLEFT", section, "TOPLEFT", 4, 0)
	interior:SetSize(1, 1)
	interior.section = section

	Widgets.panel:HookScript("OnShow", function()
		FitToContent(interior)
	end)

	return interior
end

local function AddTooltip(frame, text)
	if not text then return end
	frame:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(text)
		GameTooltip:Show()
	end)
	frame:HookScript("OnLeave", GameTooltip_Hide)
end

function Widgets.CreateCheckbox(anchor, label, dbKey, col2, dependency)
	local parent = anchor:GetParent() or anchor
	local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
	if col2 then
		checkbox:SetPoint("TOPLEFT", anchor, "TOPLEFT", col2, 0)
	else
		checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
	end
	checkbox.Text:SetText(label)
	checkbox:SetHitRectInsets(0, -checkbox.Text:GetStringWidth(), 0, 0)
	checkbox:SetScript("OnShow", function(self)
		self:SetChecked(cfItemColorsDB and cfItemColorsDB[dbKey] and cfItemColorsDB[dbKey].enabled)
	end)
	checkbox:SetScript("OnClick", function(self)
		cfItemColorsDB[dbKey].enabled = self:GetChecked()
	end)

	if dependency then
		local function UpdateState()
			local active = dependency:GetChecked()
			if active then
				checkbox:Enable()
				checkbox.Text:SetTextColor(1, 0.82, 0)
			else
				checkbox:Disable()
				checkbox.Text:SetTextColor(0.5, 0.5, 0.5)
			end
		end
		dependency:HookScript("OnClick", UpdateState)
		dependency:HookScript("OnShow", UpdateState)
	end

	AddTooltip(checkbox, TOOLTIPS[dbKey])
	return checkbox
end
