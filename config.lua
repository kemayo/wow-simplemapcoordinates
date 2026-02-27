local myname, ns = ...

ns.Settings = {}

-- the slider is ridiculously spammy
local bucket = CreateFrame("Frame")
bucket:SetScript("OnShow", function(self)
    self.elapsed = 0
end)
bucket:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed > 0.25 then
        ns:Refresh()
        self:Hide()
    end
end)

local function OnSettingChanged(setting, value)
    -- print("Setting changed:", setting:GetVariable(), value)
    bucket:Show()
end

local function MakeSetting(category, key, name, default, typeOverride)
    local setting = Settings.RegisterAddOnSetting(category, myname.."_"..key, key, _G[myname.."DB"], typeOverride or type(default), name, default)
    setting:SetValueChangedCallback(OnSettingChanged)
    ns.Settings[key] = setting
    return setting
end

function ns.SetUpConfig()
    -- This is extremely based on the examples in Blizzard_Settings_Shared/Blizzard_ImplementationReadme.lua and on https://warcraft.wiki.gg/wiki/Settings_API
    local category, layout = Settings.RegisterVerticalLayoutCategory(myname)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(WORLDMAP_BUTTON))

    Settings.CreateDropdown(category, MakeSetting(category, "worldmap_position", "Position", "below-inside"),
        function()
            local container = Settings.CreateControlTextContainer()
            container:Add("below-inside", "Below the map, inside the frame")
            container:Add("below-outside", "Below the map, outside the frame")
            container:Add("title", "In the map's title bar")
            return container:GetData()
        end,
        "Where to show the coordinates on the map frame"
    )
    Settings.CreateCheckbox(category, MakeSetting(category, "worldmap_player", "Player coordinates", true), "Show player coordinates if they're on the current map")
    Settings.CreateCheckbox(category, MakeSetting(category, "worldmap_cursor", "Cursor coordinates", true), "Show the mouse cursor's coordinates if it's over the map frame")
    Settings.CreateCheckbox(category, MakeSetting(category, "mapID", "Map ID", false), "Show the map's internal ID")

    local options = Settings.CreateSliderOptions(0, 4, 1) -- min, max, step
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    Settings.CreateSlider(category, MakeSetting(category, "precision", "Coordinate precision", 2),
        options,
        "Number of digits of precision to show in the coordinates"
    )

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(MINIMAP_LABEL))

    Settings.CreateCheckbox(category, MakeSetting(category, "minimap_player", "Player coordinates", true), "Show player coordinates")
    Settings.CreateCheckbox(category, MakeSetting(category, "minimap_cursor", "Cursor coordinates", true), "Show the mouse cursor's coordinates if it's over the minimap")
    Settings.CreateCheckbox(category, MakeSetting(category, "minimap_mapID", "Map ID", false), "Show the map's internal ID")

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Floating block"))

    Settings.CreateCheckbox(category, MakeSetting(category, "floating_player", "Player coordinates", false), "Show player coordinates")
    Settings.CreateCheckbox(category, MakeSetting(category, "floating_mapID", "Map ID", false), "Show the map's internal ID")
    Settings.CreateCheckbox(category, MakeSetting(category, "floating_backdrop", "Background", true), "Show a background for the block")
    Settings.CreateCheckbox(category, MakeSetting(category, "floating_combat", "Show in combat", true), "Show the block while you're in combat")

    Settings.RegisterAddOnCategory(category)

    do
        local slash = "/"..myname:lower()
        _G["SLASH_".. myname:upper().."1"] = slash
        _G["SLASH_".. myname:upper().."2"] = "/smcoords"
        SlashCmdList[myname:upper()] = function(msg)
            Settings.OpenToCategory(category:GetID())
        end
    end
end
