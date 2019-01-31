WorldController = {}
--
WorldController.InspectorProperties = {
    {
        name = "World Settings",
        tooltip = "World Settings",
        uiType = "headerProperty",
        layout = {"color", Color(0, 0, 0, 0)}
    },
--[[     {
        name = "Override  Wheater",
        tooltip = "Overrides the wheater with the settings below",
        uiType = "boolProperty",
        value = function()
            return  Weather.gameObject.activeInHierarchy
        end,
        func = function(v)
            Weather.gameObject:SetActive(v)
        end,
        layout = {"color", Color(0, 0, 0, 0)}
    }, ]]
    {
        name = "Time",
        tooltip = "Set Time",
        uiType = "sliderProperty",
        minValue = 0,
        maxValue = 24,
        value = function()
            return HBU.GetTimeOfDay()
        end,
        func = function(v)
            HBU.SetTimeOfDay(v)
        end,
        layout = {"color", Color(0, 0, 0, 0)}
    }--[[ ,
    {
        name = "Foginess",
        tooltip = "Set Foginess",
        uiType = "sliderProperty",
        minValue = 0,
        maxValue = 1,
        value = function()
            return HBU.GetFoginess()
        end,
        func = function(v)
            HBU.SetFoginess(v)
        end,
        layout = {"color", Color(0, 0, 0, 0)}
    },
    {
        name = "Clouds",
        tooltip = "Set Clouds",
        uiType = "sliderProperty",
        minValue = 0,
        maxValue = 1,
        value = function()
            return HBU.GetClouds()
        end,
        func = function(v)
            HBU.SetClouds(v)
        end,
        layout = {"color", Color(0, 0, 0, 0)}
    },
    {
        name = "WaveStrength",
        tooltip = "Set WaveStrength",
        uiType = "sliderProperty",
        minValue = 0,
        maxValue = 1,
        value = function()
            return HBU.GetWaveStrength()
        end,
        func = function(v)
            HBU.SetWaveStrength(v)
        end,
        layout = {"color", Color(0, 0, 0, 0)}
    },
    {
        name = "Lightning",
        tooltip = "Set Lightning",
        uiType = "sliderProperty",
        minValue = 0,
        maxValue = 1,
        value = function()
            return HBU.GetLightning()
        end,
        func = function(v)
            HBU.SetLightning(v)
        end,
        layout = {"color", Color(0, 0, 0, 0)}
    },
    {
        name = "Rain",
        tooltip = "Set Rain",
        uiType = "sliderProperty",
        minValue = 0,
        maxValue = 1,
        value = function()
            return HBU.GetRain()
        end,
        func = function(v)
            HBU.SetRain(v)
        end,
        layout = {"color", Color(0, 0, 0, 0)}
    },
    {
        name = "Wetness",
        tooltip = "Set Wetness",
        uiType = "sliderProperty",
        minValue = 0,
        maxValue = 1,
        value = function()
            return HBU.GetWetness()
        end,
        func = function(v)
            HBU.SetWetness(v)
        end,
        layout = {"color", Color(0, 0, 0, 0)}
    },
    {
        name = "VisualTemperature",
        tooltip = "Set VisualTemperature",
        uiType = "sliderProperty",
        minValue = 0,
        maxValue = 1,
        value = function()
            return HBU.GetVisualTemperature()
        end,
        func = function(v)
            HBU.SetVisualTemperature(v)
        end,
        layout = {"color", Color(0, 0, 0, 0)}
    } ]]
}

WorldController.Settings = {
    WorldControllerEnabeld = true
}

function WorldController:Update()
    if self.timer ~= os.time() then
        self.timer = os.time()
        --HBBuilder.Builder.TriggerCallback(HBBuilder.BuilderCallback.RefreshUIIndicators)
        --self.wizzard:SetProperties(self.InspectorProperties)
    end
end

function WorldController:CreateUI()
    local backgroundColor = Color(BUI.colors.black.r, BUI.colors.black.g, BUI.colors.black.b, 0.7)
    self.wizzard =
        BUI.Wizzard:Create(
        {
            name = "WorldController Settings",
            hidable = true,
            hideOnStart = true,
            layout1 = {"min", Vector2(300, (3 + #WorldController.InspectorProperties) * 25), "color", backgroundColor},
            layout2 = {}
        },
        WorldEditor.persistantToolContainer
    )
    self.wizzard:SetProperties(self.InspectorProperties)
end

function WorldController:Start()
    self:CreateUI()
    self.timer = 0
end

function WorldController:OnDestroy()
    if self.wizzard then
        self.wizzard:Destroy()
    end
end

return WorldController
