local MoveTool = {}

MoveTool.ToolButton = {
    name = "Move Tool",
    icon = "lua/icons/builder/movetool.png",
    tooltip = "Move tool: use to move parts [3]",
    bigTooltip = [[Move tool: use to move parts
hold [shift] to move freely
[R] to snap to grid
[ctrl] + [c] to copy selection
[ctrl] + [v] to paste
[delete] to delete selection]]
    
    
    
    
    ,
    hoversound = "click_blip",
    clicksound = "affirm_blip_1",
    imageLayout = {"dualcolor", true},
    layout = {
        "shortcut",
        {
            key1 = KeyCode.Alpha3,
            useShift = false,
            func = function()
                WorldEditor.SelectTool(MoveTool)
            end
        }
    },
    shortcut = nil
--[[ groupID = "transform" ]]
}

MoveTool.Inspector = {
    {
        name = "Move Tool",
        tooltip = "Move Tool Properties",
        uiType = "headerProperty"
    },
    {
        name = "Move In Worldspace",
        tooltip = "Move the selection in worldspace or localspace",
        uiType = "boolProperty",
        value = function()
            return MoveTool.Settings.WorldSpace
        end,
        func = function(v)
            MoveTool.Settings.WorldSpace = v
        end
    }
}

MoveTool.Settings = {
    WorldSpace = true
}

MoveTool.enabled = false

function MoveTool:Start()
    --register the tool with builder
    if WorldEditor and WorldEditor.RegisterTool then
        WorldEditor.RegisterTool(self, self.ToolButtonConfig)
    end
end

function MoveTool:OnDestroy()
    --unregister the tool
    if WorldEditor and WorldEditor.UnRegisterTool then
        WorldEditor.UnRegisterTool(self, self.ToolButtonConfig)
    end
    HBBuilder.Builder.StopMoveAxis()
end

function MoveTool:OnDisableTool()
    HBBuilder.Builder.StopMoveAxis()
end

function MoveTool:Update()
    if self and self.enabled == false then
        return
    end
    
    if not self or not self.enabled then
        return
    end
    
    if WorldEditor.Settings.MoveAll then
        return
    end

    --handel snapping 
    if Input.GetKeyDown(KeyCode.R) and not HBU.OverGUI() and not HBU.OverUI() and not HBU.Typing() then 

        --disable the axis already
        HBBuilder.Builder.StopMoveAxis()

        --use Grid tool to snap 
        if Grid and Grid.SnapSelectionPosition then Grid:SnapSelectionPosition() end 
        
        --notify builder we changed current assembly
        HBBuilder.Builder.ChangedCurrentAssembly()

        return
    end 
    
    --part selection while doing this stuff
    if SelectTool then
        SelectTool.rectSelectionEnabled = true
        SelectTool.enabled = true
        SelectTool.updateInspectorEnabled = false
    end
    
    --init vars
    local gotSelection = false
    local pos = Vector3.zero
    local rot = Quaternion.identity
    
    --calc vars
    if not Slua.IsNull(HBBuilder.Builder.selection) then
        for sel in Slua.iter(HBBuilder.Builder.selection) do
            if sel and not Slua.IsNull(sel) then
                gotSelection = true
                
                pos = sel.transform.position
                if MoveTool.Settings.WorldSpace then
                    rot = Quaternion.identity
                else
                    rot = sel.transform.rotation
                end
                break
            end
        end
    end
    
    if self.prePos ~= pos then
        self.prePos = pos
        moved = true
    end
    
    --create/destroy axis
    if gotSelection then
        HBBuilder.Builder.StartMoveAxis(pos, rot, HBBuilder.Builder.selection, HBBuilder.Builder.root, true)
    else
        HBBuilder.Builder.StopMoveAxis()
    end
end

function MoveTool:MouseUp()
    return Input.GetMouseButtonUp(0)
end
function MoveTool:AltKey()
    return (Input.GetKey(KeyCode.LeftAlt) or Input.GetKey(KeyCode.RightAlt))
end

return MoveTool
