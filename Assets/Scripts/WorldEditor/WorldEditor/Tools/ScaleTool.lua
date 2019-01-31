ScaleTool = {}

ScaleTool.ToolButton = {
    name = "Scale Tool",
    icon = "lua/icons/worldeditor/Resizer.png",
    tooltip = "Scale Tool [5]",
    bigTooltip = [[<b>Scale Tool:</b> for all you scaling needs.]],
    hoversound = "click_blip",
    clicksound = "affirm_blip_1",
    imageLayout = {"dualcolor", true},
    layout = {
        "shortcut",
        {
            key1 = KeyCode.Alpha5,
            useShift = false,
            func = function()
                WorldEditor.SelectTool(ScaleTool)
            end
        }
    },
    shortcut = nil
    --[[ groupID = "transform" ]]
}

ScaleTool.Inspector = {
    {
        name = "Tool Template",
        tooltip = "Shows you how to use the Inspector window",
        uiType = "headerProperty"
    },
    {
        name = "Scale X : ",
        tooltip = "This is the X value of the scale from the object",
        uiType = "floatProperty",
        value = function()
            return ScaleTool.Settings.scaleX
        end,
        func = function(v)
            ScaleTool.Settings.scaleX = v
            ScaleTool.ChangeScale()
        end
    },
    {
        name = "Scale Y : ",
        tooltip = "This is the Y value of the scale from the object",
        uiType = "floatProperty",
        value = function()
            return ScaleTool.Settings.scaleY
        end,
        func = function(v)
            ScaleTool.Settings.scaleY = v
            ScaleTool.ChangeScale()
        end
    },
    {
        name = "Scale Z : ",
        tooltip = "This is the Z value of the scale from the object",
        uiType = "floatProperty",
        value = function()
            return ScaleTool.Settings.scaleZ
        end,
        func = function(v)
            ScaleTool.Settings.scaleZ = v
            ScaleTool.ChangeScale()
        end
    }
}

ScaleTool.Settings = {
    scaleX = 1,
    scaleY = 1,
    scaleZ = 1
}

function ScaleTool:Start()
    print("ScaleTool:Start()")
    --register the tool with builder
    if WorldEditor and WorldEditor.RegisterTool then
        WorldEditor.RegisterTool(self, self.ToolButtonConfig)
    end
end

function ScaleTool:OnDestroy()
    --unregister the tool
    print("ScaleTool:OnDestroy()")
    if WorldEditor and WorldEditor.UnRegisterTool then
        WorldEditor.UnRegisterTool(self, self.ToolButtonConfig)
    end
    HBBuilder.Builder.StopScaleAxis()
end

function ScaleTool:OnDisableTool()
    HBBuilder.Builder.StopScaleAxis()
end

function ScaleTool:Update()
    --print(Builder)
    if self and self.enabled == false then
        HBBuilder.Builder.StopScaleAxis()
    end

    if not self or not self.enabled then
        return
    end

    local selection = false
    local selectionChanged = false
    local pos = Vector3.zero
    local rot = Quaternion.identity

    if SelectTool then
        SelectTool.updateInspectorEnabled = true
    end

    if not Slua.IsNull(HBBuilder.Builder.selection) then
        for part in Slua.iter(HBBuilder.Builder.selection) do
            if part and not Slua.IsNull(part) then
                selection = true

                if Input.GetKeyDown(KeyCode.R) then
                    part.transform.localScale = Vector3(1, 1, 1)
                    return
                end

                if self.partID ~= part:GetInstanceID() then
                    self.partID = part:GetInstanceID()
                    selectionChanged = true
                end
                pos = part.transform.position
                rot = part.transform.rotation
            end
            break
        end
    end

    if selection then
        HBBuilder.Builder.StartScaleAxis(pos, rot, HBBuilder.Builder.selection, HBBuilder.Builder.root, true)
    else
        HBBuilder.Builder.StopScaleAxis()
    end
end

function ScaleTool.ChangeScale()
    if not Slua.IsNull(HBBuilder.Builder.selection) then
        for part in Slua.iter(HBBuilder.Builder.selection) do
            if part and not Slua.IsNull(part) then
                part.transform.localScale =
                    Vector3(-ScaleTool.Settings.scaleX, ScaleTool.Settings.scaleY, ScaleTool.Settings.scaleZ)
            end
            break
        end
    end
end

return ScaleTool
