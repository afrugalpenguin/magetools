MageTools = {}
MageTools.modules = {}
MageTools.version = "2.0.5"

-- Make a child frame propagate drag events to its movable parent
function MageTools:PropagateDrag(child)
    child:RegisterForDrag("LeftButton")
    child:HookScript("OnDragStart", function(self)
        local parent = self:GetParent()
        parent:StartMoving()
    end)
    child:HookScript("OnDragStop", function(self)
        local parent = self:GetParent()
        parent:StopMovingOrSizing()
        if parent.SavePosition then parent:SavePosition() end
    end)
end

local frame = CreateFrame("Frame")

local defaults = {
    hudVisible = true,
    hudX = 0,
    hudY = 0,
    hudPoint = "CENTER",
    whisperKeywords = { "water", "food", "mage" },
    foodStacksPerPerson = 1,
    waterStacksPerPerson = 2,
    autoReply = true,
    queueVisible = true,
    hudButtonSize = 32,
    hudVertical = false,
    popupColumns = 5,
    popupCloseOnCast = true,
    autoPlaceItems = true,
    listenPartyChat = false,
    popupButtonSize = 36,
    maxQueueDisplay = 10,
    popupBgAlpha = 0.85,
    sessionBgAlpha = 0.9,
    showSessionOnLogin = false,
    popupKeybind = nil,
    popupReleaseMode = true,
}

function MageTools:RegisterModule(name, mod)
    self.modules[name] = mod
end

function MageTools:InitDB()
    MageToolsDB = MageToolsDB or {}
    for k, v in pairs(defaults) do
        if MageToolsDB[k] == nil then
            if type(v) == "table" then
                MageToolsDB[k] = {}
                for i, val in ipairs(v) do
                    MageToolsDB[k][i] = val
                end
            else
                MageToolsDB[k] = v
            end
        end
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == "MageTools" then
            local _, englishClass = UnitClass("player")
            if englishClass ~= "MAGE" then
                self:UnregisterEvent("ADDON_LOADED")
                return
            end
            MageTools:InitDB()
            MageTools.Masque:Init()
            for name, mod in pairs(MageTools.modules) do
                if mod.Init then
                    mod:Init()
                end
            end
            self:UnregisterEvent("ADDON_LOADED")
        end
        return
    end
    for name, mod in pairs(MageTools.modules) do
        if mod.OnEvent then
            mod:OnEvent(event, ...)
        end
    end
end)

function MageTools:RegisterEvents(...)
    for i = 1, select("#", ...) do
        frame:RegisterEvent(select(i, ...))
    end
end

-- Slash commands
SLASH_MAGETOOLS1 = "/magetools"
SLASH_MAGETOOLS2 = "/mgt"
SlashCmdList["MAGETOOLS"] = function(msg)
    local cmd = strlower(strtrim(msg))
    if cmd == "popup" then
        local pm = MageTools.modules["PopupMenu"]
        if pm then MageTools_TogglePopup() end
    elseif cmd == "hud" then
        local cm = MageTools.modules["ConjureManager"]
        if cm then cm:ToggleHUD() end
    elseif cmd == "conjure" then
        local cm = MageTools.modules["ConjureManager"]
        if cm then cm:ToggleConjureSession() end
    elseif cmd == "queue" then
        local th = MageTools.modules["TradeHelper"]
        if th then th:ToggleQueue() end
    elseif cmd == "whatsnew" then
        local wn = MageTools.modules["WhatsNew"]
        if wn then wn:Show() end
    elseif cmd == "options" then
        local opts = MageTools.modules["Options"]
        if opts then opts:Toggle() end
    elseif cmd == "config" then
        print("|cff69ccf0MageTools|r config:")
        print("  HUD visible: " .. tostring(MageToolsDB.hudVisible))
        print("  Auto-reply: " .. tostring(MageToolsDB.autoReply))
        print("  Food stacks/person: " .. MageToolsDB.foodStacksPerPerson)
        print("  Water stacks/person: " .. MageToolsDB.waterStacksPerPerson)
        print("  Keywords: " .. table.concat(MageToolsDB.whisperKeywords, ", "))
    elseif cmd == "tour" then
        local tour = MageTools.modules["Tour"]
        if tour then tour:Start() end
    else
        local wn = MageTools.modules["WhatsNew"]
        if wn and wn:ShouldShow() then
            wn:Show()
        else
            print("|cff69ccf0MageTools|r commands:")
            print("  /mgt popup - Toggle portal menu")
            print("  /mgt hud - Toggle HUD")
            print("  /mgt conjure - Conjure session")
            print("  /mgt queue - Toggle trade queue")
            print("  /mgt options - Open options panel")
            print("  /mgt whatsnew - View changelog")
            print("  /mgt config - Show config")
            print("  /mgt tour - Start onboarding tour")
        end
    end
end
