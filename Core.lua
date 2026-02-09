MageTools = {}
MageTools.modules = {}

local frame = CreateFrame("Frame")

local defaults = {
    hudVisible = true,
    hudX = 0,
    hudY = 0,
    hudPoint = "CENTER",
    whisperKeywords = { "water", "food", "mage" },
    stacksPerPerson = 1,
    autoReply = true,
    queueVisible = true,
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
    if cmd == "hud" then
        local cm = MageTools.modules["ConjureManager"]
        if cm then cm:ToggleHUD() end
    elseif cmd == "conjure" then
        local cm = MageTools.modules["ConjureManager"]
        if cm then cm:ToggleConjureSession() end
    elseif cmd == "queue" then
        local th = MageTools.modules["TradeHelper"]
        if th then th:ToggleQueue() end
    elseif cmd == "config" then
        print("|cff69ccf0MageTools|r config:")
        print("  HUD visible: " .. tostring(MageToolsDB.hudVisible))
        print("  Auto-reply: " .. tostring(MageToolsDB.autoReply))
        print("  Stacks/person: " .. MageToolsDB.stacksPerPerson)
        print("  Keywords: " .. table.concat(MageToolsDB.whisperKeywords, ", "))
    else
        print("|cff69ccf0MageTools|r commands:")
        print("  /mgt hud - Toggle HUD")
        print("  /mgt conjure - Conjure session")
        print("  /mgt queue - Toggle trade queue")
        print("  /mgt config - Show config")
    end
end
