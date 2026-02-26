local myname, ns = ...

function ns:GetWorldMapContainer()
    if not _G.SimpleMapCoordinatesWorldMapFrame then
        local container = CreateFrame("Frame", "SimpleMapCoordinatesWorldMapFrame", WorldMapFrame.ScrollContainer)
        container.player = container:CreateFontString("$parentPlayer", "OVERLAY", "NumberFontNormal")
        container.cursor = container:CreateFontString("$parentCursor", "OVERLAY", "NumberFontNormal")
        container.map = container:CreateFontString("$parentMap", "OVERLAY", "NumberFontNormal")

        container.player:SetJustifyH("CENTER")
        container.cursor:SetJustifyH("CENTER")
        container.map:SetJustifyH("CENTER")

        container:SetFrameStrata("HIGH")
        container:SetHeight(14)

        local t, WAIT_TIME = 0, 0.2
        container:SetScript("OnUpdate", function(_, elapsed)
            t = t + elapsed
            if t < WAIT_TIME then return end
            t = 0

            local mapID = WorldMapFrame:GetMapID()
            if container.player:IsVisible() then
                local position = C_Map.GetPlayerMapPosition(mapID, "player")
                container.player:SetFormattedText("Player: %s", ns.FormatPositionAsCoords(position, self.db.precision))
            end
            if container.cursor:IsVisible() then
                local position = ns.GetCursorPositionOnFrame(WorldMapFrame.ScrollContainer.Child)
                container.cursor:SetFormattedText("Cursor: %s", ns.FormatPositionAsCoords(position, self.db.precision))
            end
            if container.map:IsVisible() then
                container.map:SetFormattedText("MapID: %d", mapID)
            end
        end)
    end
    return _G.SimpleMapCoordinatesWorldMapFrame
end

function ns:RefreshWorldMap()
    if not WorldMapFrame:IsVisible() then return end
    local container = self:GetWorldMapContainer()
    if not container then return end
    -- print("laying out coordinates", self.db.worldmap_player, self.db.worldmap_cursor, self.db.mapID)
    if not (self.db.worldmap_player or self.db.worldmap_cursor or self.db.mapID) then
        return container:Hide()
    end
    container:ClearAllPoints()
    if WorldMapTitleButton then
        -- Classic!
        if self.db.worldmap_position == "below-outside" then
            container:SetPoint("TOPLEFT", WorldMapFrame, "BOTTOMLEFT", 30, 4)
            container:SetPoint("TOPRIGHT", WorldMapFrame, "BOTTOMRIGHT", -30, 4)
        elseif self.db.worldmap_position == "below-inside" then
            container:SetPoint("BOTTOMLEFT", WorldMapFrame, "BOTTOMLEFT", 30, 10)
            container:SetPoint("BOTTOMRIGHT", WorldMapFrame, "BOTTOMRIGHT", -30, 10)
        elseif self.db.worldmap_position == "title" then
            container:SetPoint("TOPLEFT", WorldMapTitleButton, 0, -4)
            container:SetPoint("RIGHT", WorldMapTitleButton, "RIGHT", 4, 0)
        end
    else
        if self.db.worldmap_position == "below-outside" then
            container:SetPoint("TOPLEFT", WorldMapFrame.ScrollContainer, "BOTTOMLEFT", 30, -5)
            container:SetPoint("TOPRIGHT", WorldMapFrame.ScrollContainer, "BOTTOMRIGHT", -30, -5)
        elseif self.db.worldmap_position == "below-inside" then
            container:SetPoint("BOTTOMLEFT", WorldMapFrame.ScrollContainer, "BOTTOMLEFT", 30, 5)
            container:SetPoint("BOTTOMRIGHT", WorldMapFrame.ScrollContainer, "BOTTOMRIGHT", -30, 5)
        elseif self.db.worldmap_position == "title" then
            container:SetPoint("TOPLEFT", WorldMapFrame.BorderFrame.TitleContainer, "TOPLEFT", 10, -3)
            container:SetPoint("BOTTOMRIGHT", WorldMapFrame.BorderFrame.TitleContainer, "BOTTOMRIGHT", -10, -0)
        end
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
            if WorldMapTitleButton then
                -- Classic!
                container.map:SetPoint("TOPLEFT", WorldMapTitleButton, "BOTTOMLEFT", 8, 0)
            else
                container.map:SetPoint("LEFT", 24, 0)
            end
        else
            container.map:SetPoint("CENTER")
        end
        container.map:Show()
    else
        container.map:Hide()
    end

    container:Show()
end

ns.refreshers["WorldMap"] = ns.RefreshWorldMap
EventRegistry:RegisterCallback("MapCanvas.MapSet", function(_, mapID) ns:RefreshWorldMap() end)
EventRegistry:RegisterCallback("WorldMapOnShow", function() ns:RefreshWorldMap() end)
if WorldMapTitleButton then
    -- Classic!
    hooksecurefunc(WorldMapFrame, "OnMapChanged", function() ns:RefreshWorldMap() end)
    WorldMapFrame:HookScript("OnShow", function() ns:RefreshWorldMap() end)
end
