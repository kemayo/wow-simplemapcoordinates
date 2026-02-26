local myname, ns = ...

local frame = CreateFrame("Frame", "SimpleMapCoordinatesFloatingFrame", UIParent, "BackdropTemplate")
frame:SetBackdrop({
    edgeFile = [[Interface\Buttons\WHITE8X8]],
    bgFile = [[Interface\Buttons\WHITE8X8]],
    edgeSize = 1,
})

frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetClampedToScreen(true)
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
-- frame:SetScript("OnMouseUp", function(w, button)
--     if button == "RightButton" then
--         return ns:ShowFloatingConfigMenu(w)
--     end
-- end)

frame.text = frame:CreateFontString("$parentPlayer", "OVERLAY", "NumberFontNormal")
frame.text:SetJustifyH("CENTER")
frame.text:SetAllPoints()

frame:SetPoint("CENTER")
frame:SetSize(120, 18)

local t, WAIT_TIME = 0, 0.2
frame:SetScript("OnUpdate", function(self, elapsed)
    t = t + elapsed
    if t < WAIT_TIME then return end
    t = 0

    if C_PetBattles.IsInBattle() then return self:Hide() end
    if not ns.db.floating_combat and InCombatLockdown() then return self:Hide() end
    if not (ns.db.floating_player or ns.db.floating_mapID) then
        return self:Hide()
    end
    local mapID = C_Map.GetBestMapForUnit("player")
    local position = mapID and C_Map.GetPlayerMapPosition(mapID, "player")

    if ns.db.floating_mapID and ns.db.floating_player then
        self.text:SetFormattedText("#%s %s", mapID or "??", ns.FormatPositionAsCoords(position))
    elseif ns.db.floating_player then
        self.text:SetText(ns.FormatPositionAsCoords(position))
    elseif ns.db.floating_mapID then
        self.text:SetFormattedText("#%s", mapID or "??")
    end
    self:SetWidth(frame.text:GetUnboundedStringWidth() + 4)
end)

frame:SetScript("OnEvent", function(_, event, ...)
    if frame[event] then
        frame[event](frame, event, ...)
    end
end)
function frame:PET_BATTLE_OPENING_START()
    self:Hide()
end
function frame:PET_BATTLE_CLOSE()
    ns:RefreshFloating()
end
function frame:PLAYER_REGEN_DISABLED()
    if not ns.db.floating_combat then
        self:Hide()
    end
end
function frame:PLAYER_REGEN_ENABLED()
    ns:RefreshFloating()
end
frame:RegisterEvent("PET_BATTLE_CLOSE")
frame:RegisterEvent("PET_BATTLE_OPENING_START")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

function ns:RefreshFloating()
    if not (self.db.floating_player or self.db.floating_mapID) then
        return
    end
    if self.db.floating_backdrop then
        frame:SetBackdropColor(0, 0, 0, .5)
        frame:SetBackdropBorderColor(0, 0, 0, .5)
    else
        frame:SetBackdropColor(0, 0, 0, 0)
        frame:SetBackdropBorderColor(0, 0, 0, 0)
    end
    frame:Show()
end
