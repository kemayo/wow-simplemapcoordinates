local myname, ns = ...

local db

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
    if WorldMapTitleButton then
        -- Classic!
        hooksecurefunc(WorldMapFrame, "OnMapChanged", function() ns:Refresh() end)
        WorldMapFrame:HookScript("OnShow", function() ns:Refresh() end)
    end

    ns:SetUpConfig()
end)

function ns:Refresh()
    self:RefreshWorldMap()
    self:RefreshFloating()
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
