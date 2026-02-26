local myname, ns = ...

local db
local defaults = {
    worldmap_position = "below-inside", -- below-outside / below-inside / title
    worldmap_player = true,
    worldmap_cursor = true,
    -- minimap = false,
    mapID = true,
    precision = 2,
}

local issecretvalue = _G.issecretvalue or function() return false end
local isanyvaluesecret = function(...)
    for i=1, select("#", ...) do
        if issecretvalue((select(i, ...))) then
            return true
        end
    end
    return false
end

EventUtil.ContinueOnAddOnLoaded(myname, function()
    local dbname = myname.."DB"
    -- _G[dbname] = setmetatable(_G[dbname] or {}, {__index=defaults})
    _G[dbname] = _G[dbname] or {}
    db = _G[dbname]
    ns.db = db

    EventRegistry:RegisterCallback("MapCanvas.MapSet", function(_, mapID) ns:RefreshWorldMap() end)
    EventRegistry:RegisterCallback("WorldMapOnShow", function() ns:RefreshWorldMap() end)

    ns:SetUpConfig()
end)

function ns:GetWorldMapContainer()
    if not WorldMapFrame.SimpleMapCoordinatesContainer then
        local container = CreateFrame("Frame", "SimpleMapCoordinatesMapFrame", WorldMapFrame.ScrollContainer)
        container.player = container:CreateFontString("$parentPlayer", "OVERLAY", "NumberFontNormal")
        container.cursor = container:CreateFontString("$parentCursor", "OVERLAY", "NumberFontNormal")
        container.map = container:CreateFontString("$parentMap", "OVERLAY", "NumberFontNormal")

        container.player:SetJustifyH("CENTER")
        container.cursor:SetJustifyH("CENTER")
        container.map:SetJustifyH("CENTER")

        container:SetHeight(14)

        local t, WAIT_TIME = 0, 0.1
        container:SetScript("OnUpdate", function(_, elapsed)
            t = t + elapsed
            if t < WAIT_TIME then return end

            t = 0
            local mapID = WorldMapFrame:GetMapID()
            if container.player:IsVisible() then
                local position = C_Map.GetPlayerMapPosition(mapID, "player")
                container.player:SetFormattedText("Player: %s", ns.FormatPositionAsCoords(position, db.precision))
            end
            if container.cursor:IsVisible() then
                local position = ns.GetCursorPositionOnFrame(WorldMapFrame.ScrollContainer.Child)
                container.cursor:SetFormattedText("Cursor: %s", ns.FormatPositionAsCoords(position, db.precision))
            end
            if container.map:IsVisible() then
                container.map:SetFormattedText("MapID: %d", mapID)
            end
        end)

        WorldMapFrame.SimpleMapCoordinatesContainer = container
    end
    return WorldMapFrame.SimpleMapCoordinatesContainer
end

function ns:Refresh()
    if WorldMapFrame:IsVisible() then
        self:RefreshWorldMap()
    end
end

function ns:RefreshWorldMap()
    local container = self:GetWorldMapContainer()
    if not container then return end
    print("laying out coordinates", self.db.worldmap_player, self.db.worldmap_cursor, self.db.mapID)
    if not (self.db.worldmap_player or self.db.worldmap_cursor or self.db.mapID) then
        return container:Hide()
    end
    container:ClearAllPoints()
    if self.db.worldmap_position == "below-outside" then
        container:SetPoint("TOPLEFT", WorldMapFrame.ScrollContainer, "BOTTOMLEFT", 30, -5)
        container:SetPoint("TOPRIGHT", WorldMapFrame.ScrollContainer, "BOTTOMRIGHT", -30, -5)
        container:SetFrameStrata("MEDIUM")
    elseif self.db.worldmap_position == "below-inside" then
        container:SetPoint("BOTTOMLEFT", WorldMapFrame.ScrollContainer, "BOTTOMLEFT", 30, 5)
        container:SetPoint("BOTTOMRIGHT", WorldMapFrame.ScrollContainer, "BOTTOMRIGHT", -30, 5)
        container:SetFrameStrata("MEDIUM")
    elseif self.db.worldmap_position == "title" then
        container:SetPoint("TOPLEFT", WorldMapFrame.BorderFrame.TitleContainer, "TOPLEFT", 10, -3)
        container:SetPoint("BOTTOMRIGHT", WorldMapFrame.BorderFrame.TitleContainer, "BOTTOMRIGHT", -10, -0)
        container:SetFrameStrata("HIGH")
    end
    container.player:ClearAllPoints()
    if self.db.worldmap_player then
        container.player:SetPoint("LEFT")
        container.player:SetPoint("RIGHT", container, "CENTER", -20, 0)
        container.player:Show()
    else
        container.player:Hide()
    end
    container.cursor:ClearAllPoints()
    if self.db.worldmap_cursor then
        container.cursor:SetPoint("RIGHT")
        container.cursor:SetPoint("LEFT", container, "CENTER", 20, 0)
        container.cursor:Show()
    else
        container.cursor:Hide()
    end
    container.map:ClearAllPoints()
    if self.db.mapID then
        if self.db.worldmap_position == "title" then
            container.map:SetPoint("LEFT", 24, 0)
        else
            container.map:SetPoint("CENTER", 0, self.db.worldmap_position == "title" and 16 or 0)
        end
        container.map:Show()
    else
        container.map:Hide()
    end

    container:Show()
end

do
    local cursorPosition = CreateVector2D(0, 0)
    function ns.GetCursorPositionOnFrame(frame)
        -- I looked at how Mapster does this
        local left, top = frame:GetLeft() or 0, frame:GetTop() or 0
        local width, height = frame:GetSize()
        local scale = frame:GetEffectiveScale()

        -- before we compare anything...
        if not (
            not isanyvaluesecret(left, top, width, height, scale) and
            left and top and width and height and scale and
            width > 0 and height > 0
        ) then
            return
        end
        local x, y = GetCursorPosition()
        if isanyvaluesecret(x, y) then return end
        local cursorX = (x / scale - left) / width
        local cursorY = (top - y / scale) / height

        if cursorX < 0 or cursorX > 1 or cursorY < 0 or cursorY > 1 then
            return
        end

        cursorPosition:SetXY(cursorX, cursorY)
        return cursorPosition
    end
end

function ns.FormatPositionAsCoords(position, precision)
    if not position then return "?, ?" end
    local x, y = position:GetXY()
    if not (x and y) then return "?, ?" end
    return (("%%.%df, %%.%df"):format(precision or 2, precision or 2)):format(x * 100, y * 100)
end
