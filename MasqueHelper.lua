local MT = MageTools

MT.Masque = {}
local MSQ = nil
local groups = {}

function MT.Masque:Init()
    local lib = LibStub and LibStub("Masque", true)
    if lib then
        MSQ = lib
    end
end

function MT.Masque:GetGroup(name)
    if not MSQ then return nil end
    if not groups[name] then
        groups[name] = MSQ:Group("MageTools", name)
    end
    return groups[name]
end

function MT.Masque:IsEnabled()
    return MSQ ~= nil
end

function MT.Masque:AddButton(groupName, button, data)
    local group = self:GetGroup(groupName)
    if group then
        group:AddButton(button, data)
    end
end

function MT.Masque:ReSkin(groupName)
    local group = self:GetGroup(groupName)
    if group then
        group:ReSkin()
    end
end
