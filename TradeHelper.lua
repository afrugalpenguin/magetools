local MT = MageTools
local TH = {}
MT:RegisterModule("TradeHelper", TH)

local queue = {}  -- { { name = "Player", request = "water" }, ... }
local queueFrame = nil
local queueButtons = {}
local pendingTrade = nil  -- name of player we're trying to trade with

function TH:Init()
    self:CreateQueueFrame()
    self:UpdateQueueDisplay()
end

function TH:GetQueueSize()
    return #queue
end

-- Whisper handling
function TH:MatchKeyword(msg)
    msg = strlower(msg)
    local matched = {}
    for _, keyword in ipairs(MageToolsDB.whisperKeywords) do
        local lk = strlower(keyword)
        if strfind(msg, lk) then
            if lk == "food" then
                matched.food = true
            elseif lk == "water" then
                matched.water = true
            else
                -- Generic keywords (e.g. "mage", "beer") request water
                matched.water = true
            end
        end
    end
    if matched.food and matched.water then
        return "both"
    elseif matched.food then
        return "food"
    elseif matched.water then
        return "water"
    end
    return nil
end

local function NotifyConjureSession()
    local cm = MT.modules["ConjureManager"]
    if cm and cm.UpdateSessionIfShown then
        cm:UpdateSessionIfShown()
    end
end

function TH:AddToQueue(name, request)
    -- Check for duplicates, update existing
    for _, entry in ipairs(queue) do
        if entry.name == name then
            entry.request = request
            self:UpdateQueueDisplay()
            NotifyConjureSession()
            return
        end
    end
    tinsert(queue, { name = name, request = request })
    self:UpdateQueueDisplay()
    NotifyConjureSession()

    if MageToolsDB.autoReply then
        local position = #queue
        local reqText = request
        if request == "both" then reqText = "food and water" end
        SendChatMessage("You're queued for " .. reqText .. ". " .. (position - 1) .. " ahead of you.", "WHISPER", nil, name)
    end

    -- Show queue frame if hidden
    if not queueFrame:IsShown() then
        queueFrame:Show()
    end
end

function TH:RemoveFromQueue(index)
    local entry = tremove(queue, index)
    if entry and MageToolsDB.autoReply then
        SendChatMessage("Enjoy!", "WHISPER", nil, entry.name)
    end
    self:UpdateQueueDisplay()
    NotifyConjureSession()
    if #queue == 0 then
        queueFrame:Hide()
    end
end

-- Find conjured items in bags and trade them
function TH:FindConjuredItem(itemType)
    local itemList
    if itemType == "food" then
        itemList = MT.CONJURED_FOOD
    else
        itemList = MT.CONJURED_WATER
    end
    -- Find a full stack first (20), otherwise any stack
    local bestBag, bestSlot, bestCount = nil, nil, 0
    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                for _, validID in ipairs(itemList) do
                    if info.itemID == validID then
                        if info.stackCount and info.stackCount > bestCount then
                            bestBag, bestSlot, bestCount = bag, slot, info.stackCount
                        end
                    end
                end
            end
        end
    end
    return bestBag, bestSlot
end

function TH:PlaceItemsInTrade(request)
    local tradeSlot = 1
    if request == "food" or request == "both" then
        local bag, slot = self:FindConjuredItem("food")
        if bag then
            C_Container.PickupContainerItem(bag, slot)
            ClickTradeButton(tradeSlot)
            tradeSlot = tradeSlot + 1
        end
    end
    if request == "water" or request == "both" then
        local bag, slot = self:FindConjuredItem("water")
        if bag then
            C_Container.PickupContainerItem(bag, slot)
            ClickTradeButton(tradeSlot)
        end
    end
end

-- Queue Frame
function TH:CreateQueueFrame()
    queueFrame = CreateFrame("Frame", "MageToolsQueue", UIParent, "BackdropTemplate")
    queueFrame:SetSize(200, 40)
    queueFrame:SetPoint("RIGHT", UIParent, "RIGHT", -20, 0)
    queueFrame:SetFrameStrata("MEDIUM")
    queueFrame:SetClampedToScreen(true)
    queueFrame:SetMovable(true)
    queueFrame:EnableMouse(true)
    queueFrame:RegisterForDrag("LeftButton")
    queueFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    queueFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    queueFrame:Hide()

    tinsert(UISpecialFrames, "MageToolsQueue")

    queueFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    queueFrame:SetBackdropColor(0, 0, 0, 0.8)

    -- Title
    local title = queueFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", 0, -6)
    title:SetText("|cff69ccf0Trade Queue|r")
    queueFrame.title = title

    -- Conjure session shortcut button
    local conjBtn = CreateFrame("Button", nil, queueFrame)
    conjBtn:SetSize(14, 14)
    conjBtn:SetPoint("TOPRIGHT", queueFrame, "TOPRIGHT", -6, -4)
    local conjIcon = conjBtn:CreateTexture(nil, "ARTWORK")
    conjIcon:SetAllPoints()
    conjIcon:SetTexture("Interface\\Icons\\INV_Misc_Gem_Emerald_02")
    conjIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local conjHL = conjBtn:CreateTexture(nil, "HIGHLIGHT")
    conjHL:SetAllPoints()
    conjHL:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    conjHL:SetBlendMode("ADD")
    conjBtn:SetScript("OnClick", function()
        local cm = MT.modules["ConjureManager"]
        if cm then cm:ToggleConjureSession() end
    end)
    conjBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Open Conjure Session")
        GameTooltip:Show()
    end)
    conjBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Create row buttons (SecureActionButton to auto-target on click)
    for i = 1, MageToolsDB.maxQueueDisplay do
        local row = CreateFrame("Button", "MageToolsQueueRow" .. i, queueFrame, "SecureActionButtonTemplate")
        row:SetSize(180, 18)
        row:SetPoint("TOP", queueFrame, "TOP", 0, -8 - (i * 18))
        row:RegisterForClicks("AnyUp")
        row:SetAttribute("type1", "macro")  -- left-click: target via macro

        -- Clear template-injected normal texture
        local tmplNormal = row:GetNormalTexture()
        if tmplNormal then tmplNormal:SetTexture(nil); tmplNormal:Hide() end

        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", 6, 0)
        row.nameText = nameText

        local reqText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        reqText:SetPoint("RIGHT", -6, 0)
        row.reqText = reqText

        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

        -- Left-click: target + set pending. Right-click: remove from queue.
        row:SetScript("PostClick", function(self, button)
            if not queue[i] then return end
            if button == "RightButton" then
                TH:RemoveFromQueue(i)
            else
                pendingTrade = queue[i]
                print("|cff69ccf0MageTools|r Targeting " .. queue[i].name .. ". Open trade to deliver.")
            end
        end)

        row:Hide()
        tinsert(queueButtons, row)
    end
end

function TH:UpdateQueueDisplay()
    local maxDisplay = math.min(MageToolsDB.maxQueueDisplay, #queueButtons)
    local visibleCount = math.min(#queue, maxDisplay)
    for i = 1, maxDisplay do
        if i <= visibleCount then
            local entry = queue[i]
            queueButtons[i].nameText:SetText(entry.name)
            local reqLabel = entry.request
            if reqLabel == "both" then reqLabel = "food+water" end
            queueButtons[i].reqText:SetText("|cffaaaaaa" .. reqLabel .. "|r")
            queueButtons[i]:SetAttribute("macrotext1", "/target " .. entry.name)
            queueButtons[i]:Show()
        else
            queueButtons[i]:SetAttribute("macrotext1", "")
            queueButtons[i]:Hide()
        end
    end
    -- Resize frame
    local height = 28 + (visibleCount * 18)
    queueFrame:SetSize(200, math.max(40, height))
end

function TH:RebuildQueue()
    if not queueFrame then return end
    local maxDisplay = MageToolsDB.maxQueueDisplay
    -- Create additional rows if needed
    for i = #queueButtons + 1, maxDisplay do
        local row = CreateFrame("Button", "MageToolsQueueRow" .. i, queueFrame, "SecureActionButtonTemplate")
        row:SetSize(180, 18)
        row:SetPoint("TOP", queueFrame, "TOP", 0, -8 - (i * 18))
        row:RegisterForClicks("AnyUp")
        row:SetAttribute("type1", "macro")
        local tmplNormal = row:GetNormalTexture()
        if tmplNormal then tmplNormal:SetTexture(nil); tmplNormal:Hide() end
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", 6, 0)
        row.nameText = nameText
        local reqText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        reqText:SetPoint("RIGHT", -6, 0)
        row.reqText = reqText
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row:SetScript("PostClick", function(self, button)
            if not queue[i] then return end
            if button == "RightButton" then
                TH:RemoveFromQueue(i)
            else
                pendingTrade = queue[i]
                print("|cff69ccf0MageTools|r Targeting " .. queue[i].name .. ". Open trade to deliver.")
            end
        end)
        row:Hide()
        tinsert(queueButtons, row)
    end
    self:UpdateQueueDisplay()
end

function TH:ToggleQueue()
    if queueFrame:IsShown() then
        queueFrame:Hide()
        MageToolsDB.queueVisible = false
    else
        queueFrame:Show()
        MageToolsDB.queueVisible = true
    end
end

function TH:OnEvent(event, ...)
    if event == "CHAT_MSG_WHISPER" then
        local msg, sender = ...
        local request = self:MatchKeyword(msg)
        if request then
            -- Strip realm name if present
            local name = strsplit("-", sender)
            self:AddToQueue(name, request)
        end
    elseif event == "TRADE_SHOW" then
        -- Trade window opened — if we have a pending trade, place items
        if pendingTrade and MageToolsDB.autoPlaceItems then
            self:PlaceItemsInTrade(pendingTrade.request)
        end
    elseif event == "UI_INFO_MESSAGE" then
        local _, msg = ...
        if msg == ERR_TRADE_COMPLETE then
            -- Find and remove the served player
            if pendingTrade then
                for i, entry in ipairs(queue) do
                    if entry.name == pendingTrade.name then
                        self:RemoveFromQueue(i)
                        break
                    end
                end
                pendingTrade = nil
            end
        end
    elseif event == "TRADE_CLOSED" then
        pendingTrade = nil
    end
end

MT:RegisterEvents("CHAT_MSG_WHISPER", "TRADE_SHOW", "TRADE_CLOSED", "UI_INFO_MESSAGE")
