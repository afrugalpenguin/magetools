local MT = MageTools
local TH = {}
MT:RegisterModule("TradeHelper", TH)

local queue = {}  -- { { name = "Player", request = "water" }, ... }
local queueFrame = nil
local queueButtons = {}
local MAX_QUEUE_DISPLAY = 10
local pendingTrade = nil  -- name of player we're trying to trade with

function TH:Init()
    self:CreateQueueFrame()
    self:UpdateQueueDisplay()
end

-- Whisper handling
function TH:MatchKeyword(msg)
    msg = strlower(msg)
    local matched = {}
    for _, keyword in ipairs(MageToolsDB.whisperKeywords) do
        if strfind(msg, strlower(keyword)) then
            if keyword == "food" then
                matched.food = true
            elseif keyword == "water" then
                matched.water = true
            elseif keyword == "mage" then
                matched.food = true
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

function TH:AddToQueue(name, request)
    -- Check for duplicates, update existing
    for _, entry in ipairs(queue) do
        if entry.name == name then
            entry.request = request
            self:UpdateQueueDisplay()
            return
        end
    end
    tinsert(queue, { name = name, request = request })
    self:UpdateQueueDisplay()

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
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemID = GetContainerItemID(bag, slot)
            if itemID then
                for _, validID in ipairs(itemList) do
                    if itemID == validID then
                        local _, itemCount = GetContainerItemInfo(bag, slot)
                        if itemCount and itemCount > bestCount then
                            bestBag, bestSlot, bestCount = bag, slot, itemCount
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
            PickupContainerItem(bag, slot)
            ClickTradeButton(tradeSlot)
            tradeSlot = tradeSlot + 1
        end
    end
    if request == "water" or request == "both" then
        local bag, slot = self:FindConjuredItem("water")
        if bag then
            PickupContainerItem(bag, slot)
            ClickTradeButton(tradeSlot)
        end
    end
end

-- Queue Frame
function TH:CreateQueueFrame()
    queueFrame = CreateFrame("Frame", "MageToolsQueue", UIParent)
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

    -- Create row buttons
    for i = 1, MAX_QUEUE_DISPLAY do
        local row = CreateFrame("Button", "MageToolsQueueRow" .. i, queueFrame)
        row:SetSize(180, 18)
        row:SetPoint("TOP", queueFrame, "TOP", 0, -8 - (i * 18))

        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", 6, 0)
        row.nameText = nameText

        local reqText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        reqText:SetPoint("RIGHT", -6, 0)
        row.reqText = reqText

        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

        row:SetScript("OnClick", function()
            if queue[i] then
                -- Target player and initiate trade
                pendingTrade = queue[i]
                TargetByName(queue[i].name, true)
                InitiateTrade("target")
            end
        end)

        row:Hide()
        tinsert(queueButtons, row)
    end
end

function TH:UpdateQueueDisplay()
    local visibleCount = math.min(#queue, MAX_QUEUE_DISPLAY)
    for i = 1, MAX_QUEUE_DISPLAY do
        if i <= visibleCount then
            local entry = queue[i]
            queueButtons[i].nameText:SetText(entry.name)
            local reqLabel = entry.request
            if reqLabel == "both" then reqLabel = "food+water" end
            queueButtons[i].reqText:SetText("|cffaaaaaa" .. reqLabel .. "|r")
            queueButtons[i]:Show()
        else
            queueButtons[i]:Hide()
        end
    end
    -- Resize frame
    local height = 28 + (visibleCount * 18)
    queueFrame:SetSize(200, math.max(40, height))
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
        if pendingTrade then
            self:PlaceItemsInTrade(pendingTrade.request)
        end
    elseif event == "TRADE_ACCEPT_UPDATE" then
        -- Nothing needed here, handled on close
    elseif event == "UI_INFO_MESSAGE" then
        local _, msg = ...
        if msg and strfind(msg, "Trade complete") then
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
        -- Reset pending if trade cancelled
        -- (Don't remove from queue — they still need items)
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
        -- Remove offline players from queue
        local toRemove = {}
        for i, entry in ipairs(queue) do
            if not UnitIsConnected(entry.name) then
                tinsert(toRemove, i)
            end
        end
        for j = #toRemove, 1, -1 do
            tremove(queue, toRemove[j])
        end
        if #toRemove > 0 then
            self:UpdateQueueDisplay()
        end
    end
end

MT:RegisterEvents("CHAT_MSG_WHISPER", "TRADE_SHOW", "TRADE_CLOSED", "UI_INFO_MESSAGE", "PARTY_MEMBERS_CHANGED")
