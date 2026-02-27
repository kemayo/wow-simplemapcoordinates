local myname, ns = ...

local CLASSIC = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE
local CLASSICERA = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC -- forever vanilla

local function MakeMinimapFrame(name)
    -- classic
    if CLASSIC then
        local frame = CreateFrame("FRAME", name, Minimap, "BackdropTemplate")
        frame:SetFrameStrata("MEDIUM")
        frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4, },
        })
        frame:SetBackdropColor(0.1, 0.1, 0.2, 1)
        return frame
    end
    local frame = CreateFrame("Frame", "SimpleMapCoordinatesMinimapPlayerFrame", Minimap, "NineSliceCodeTemplate")
    frame.layoutType = "UniqueCornersLayout"
    frame.layoutTextureKit = "ui-hud-minimap-button"
    frame:OnLoad()
    return frame
end

local playerFrame
do
    local frame = MakeMinimapFrame("SimpleMapCoordinatesMinimapPlayerFrame")

    frame.text = frame:CreateFontString("$parentText", "OVERLAY", "NumberFontNormal")
    frame.text:SetJustifyH("CENTER")
    frame.text:SetAllPoints()

    frame:SetPoint("TOP", Minimap, "BOTTOM", 0, CLASSIC and -10 or 0)
    frame:SetHeight(CLASSIC and 22 or 20)

    local t, WAIT_TIME = 1, 0.2
    frame:SetScript("OnUpdate", function(self, elapsed)
        t = t + elapsed
        if t < WAIT_TIME then return end
        t = 0

        if not (ns.db.minimap_player or ns.db.minimap_mapID) then
            return self:Hide()
        end
        local mapID = C_Map.GetBestMapForUnit("player")
        local position = mapID and C_Map.GetPlayerMapPosition(mapID, "player")

        if ns.db.minimap_mapID and ns.db.minimap_player then
            self.text:SetFormattedText("#%s %s", mapID or "??", ns.FormatPositionAsCoords(position))
        elseif ns.db.minimap_player then
            self.text:SetText(ns.FormatPositionAsCoords(position))
        elseif ns.db.minimap_mapID then
            self.text:SetFormattedText("#%s", mapID or "??")
        end
        self:SetWidth(frame.text:GetUnboundedStringWidth() + 6)
    end)

    playerFrame = frame
end

local cursorFrame = frame
do
    local frame = MakeMinimapFrame("SimpleMapCoordinatesMinimapCursorFrame")

    frame.text = frame:CreateFontString("$parentText", "OVERLAY", "NumberFontNormal")
    frame.text:SetJustifyH("CENTER")
    frame.text:SetAllPoints()

    frame:SetPoint("TOP", playerFrame, "BOTTOM", 0, CLASSIC and 2 or 0)
    frame:SetHeight(CLASSIC and 22 or 20)

    function frame:UpdatePositionText()
        local cPosition = Minimap:IsMouseOver() and ns.GetCursorPositionOnMinimap()
        self.text:SetFormattedText("C: %s", ns.FormatPositionAsCoords(cPosition))
        self:SetWidth(frame.text:GetUnboundedStringWidth() + 6)
        -- self:SetHeight(frame.text:GetStringHeight() + 4)
    end

    local t, WAIT_TIME = 0, 0.2
    frame:SetScript("OnUpdate", function(self, elapsed)
        t = t + elapsed
        if t < WAIT_TIME then return end
        t = 0

        if not ns.db.minimap_cursor then
            return self:Hide()
        end
        self:UpdatePositionText()
    end)
    frame:SetScript("OnShow", function(self)
        self:UpdatePositionText()
    end)

    Minimap:HookScript("OnEnter", function()
        if ns.db.minimap_cursor then
            frame:Show()
        end
    end)
    Minimap:HookScript("OnLeave", function()
        frame:Hide()
    end)

    cursorFrame = frame
end

function ns:RefreshMinimap()
    playerFrame:SetShown(self.db.minimap_player or self.db.minimap_mapID)
    cursorFrame:SetShown(self.db.minimap_cursor and Minimap:IsMouseOver())
end
ns.refreshers["Minimap"] = ns.RefreshMinimap

do
    -- I copied this from my ping code in QuestsChanged
    -- The classic fallbacks here are from HereBeDragons:
    local GetViewRadius, GetZoneSize
    if C_Minimap and C_Minimap.GetViewRadius then
        GetViewRadius = function() return C_Minimap.GetViewRadius() end
    else
        -- classic / mists
        local f = CreateFrame("FRAME")
        local indoors
        f:SetScript("OnEvent", function(self, event, ...)
            local zoom = Minimap:GetZoom()
            if GetCVar("minimapZoom") == GetCVar("minimapInsideZoom") then
                Minimap:SetZoom(zoom < 2 and zoom + 1 or zoom - 1)
            end
            indoors = GetCVar("minimapZoom")+0 == Minimap:GetZoom() and "outdoor" or "indoor"
            Minimap:SetZoom(zoom)
        end)
        f:RegisterEvent("MINIMAP_UPDATE_ZOOM")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")

        local minimap_size = {
            indoor = {
                [0] = 300, -- scale
                [1] = 240, -- 1.25
                [2] = 180, -- 5/3
                [3] = 120, -- 2.5
                [4] = 80,  -- 3.75
                [5] = 50,  -- 6
            },
            outdoor = {
                [0] = 466 + 2/3, -- scale
                [1] = 400,       -- 7/6
                [2] = 333 + 1/3, -- 1.4
                [3] = 266 + 2/6, -- 1.75
                [4] = 200,       -- 7/3
                [5] = 133 + 1/3, -- 3.5
            },
        }
        GetViewRadius = function()
            local zoom = Minimap:GetZoom()
            return minimap_size[indoors][zoom] / 2
        end
    end
    if C_Map and C_Map.GetMapWorldSize then
        GetZoneSize = function(uiMapID) return C_Map.GetMapWorldSize(uiMapID) end
    else
        -- classic and mists again
        local vector00, vector05 = CreateVector2D(0, 0), CreateVector2D(0.5, 0.5)
        GetZoneSize = function(uiMapID)
            local instance, center = C_Map.GetWorldPosFromMapPos(uiMapID, vector05)
            local width, height

            local _, topleft = C_Map.GetWorldPosFromMapPos(uiMapID, vector00)
            if center and topleft then
                local top, left = topleft:GetXY()
                local bottom, right = center:GetXY()
                width = (left - right) * 2
                height = (top - bottom) * 2
            end

            return width, height
        end
    end

    local function MinimapPosition(x, y)
        -- x and y are offsets from the center of the minimap at its current
        -- zoom level, between -0.5 and 0.5. They're this because that's what
        -- the arguments to MINIMAP_PING are.
        local mapRadius = GetViewRadius()
        local uiMapID = C_Map.GetBestMapForUnit('player')
        if not uiMapID then return end
        local position = C_Map.GetPlayerMapPosition(uiMapID, 'player')
        if not position then return end
        local px, py = position:GetXY()
        if not (px and py) then return end
        local zoneWidth, zoneHeight = GetZoneSize(uiMapID)
        if not zoneWidth and zoneHeight then return end
        -- Now we work out the yard-offset for the minimap
        local minimapWidth = mapRadius / zoneWidth
        local minimapHeight = mapRadius / zoneHeight
        return uiMapID, px + (2 * x * minimapWidth), py - (2 * y * minimapHeight)
    end
    local cursorPosition = CreateVector2D(0, 0)
    function ns.GetCursorPositionOnMinimap()
        local scale, cx, cy = UIParent:GetEffectiveScale(), GetCursorPosition()
        local mWidth, mHeight = Minimap:GetSize()
        local left, bottom = Minimap:GetLeft(), Minimap:GetBottom()
        local ix, iy = (cx / scale) - left, (cy / scale) - bottom
        local uiMapID, mx, my = MinimapPosition((ix / mWidth) - 0.5, (iy / mHeight) - 0.5)
        if uiMapID then
            cursorPosition:SetXY(mx, my)
            return cursorPosition
        end
    end
end
