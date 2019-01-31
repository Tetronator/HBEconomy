RaceTrackBuilder = {}

-----------------------------------------------
--Tool Settings And UI Declaration
-----------------------------------------------
RaceTrackBuilder.ToolButton = {
    name = "Race Track Builder",
    icon = "lua/icons/worldeditor/ToolTemplate.png",
    tooltip = "Race Track Builder",
    bigTooltip = [[Big Tool Discription]],
    hoversound = "click_blip",
    clicksound = "affirm_blip_1",
    imageLayout = {"dualcolor", true},
    layout = {
        "shortcut",
        {
            key1 = KeyCode.Alpha9,
            useShift = false,
            func = function()
                WorldEditor.SelectTool(RaceTrackBuilder)
            end
        }
    },
    shortcut = nil
}

RaceTrackBuilder.Inspector = {
    {
        name = "Race Track Builder",
        tooltip = "Used to make a race track",
        uiType = "headerProperty"
    }
}

RaceTrackBuilder.Settings = {hasRace = false}
RaceTrackBuilder.appliedInspectorColorPicker = true

function RaceTrackBuilder.MakeTrigger()
    local triggerObj = GameObject.CreatePrimitive(PrimitiveType.Cube)
    local coll = triggerObj:GetComponent("BoxCollider")
    coll.isTrigger = true
    triggerObj.name = "Trigger Object"
    local hbt = triggerObj:AddComponent("HBTrigger")
    hbt.triggerOnVehicle = true
    hbt.triggerOnPlayer = true
    hbt.triggerOnSelf = true
    hbt.triggerOnOther = true
    hbt.onTrigger = function(obj)
        print("TRIGGERED!!!! REEEEEEEEEEEEEEEEEE : ", obj)
    end
    HBBuilder.BuilderUtils.SetLayer(triggerObj, 0, true)
    triggerObj.transform.parent = HBBuilder.Builder.currentAssembly.bodyContainer.transform
    triggerObj.transform.position = Camera.main.transform.position + Camera.main.transform.forward
end

function RaceTrackBuilder.MakeRace()
    RaceTrackBuilder.Settings.hasRace = true
    RaceTrackBuilder.appliedInspectorColorPicker = false
    Inspector.wizzard:SetProperties(RaceTrackBuilder.Inspector)
    RaceTrackBuilder.Track = HBBuilder.Builder.currentAssembly.bodyContainer.gameObject:AddComponent("HBRaceTrack")
end

function RaceTrackBuilder.DeleteRace()
    RaceTrackBuilder.Settings.hasRace = false
    RaceTrackBuilder.appliedInspectorColorPicker = false
    Inspector.wizzard:SetProperties(RaceTrackBuilder.Inspector)
    GameObject.Destroy(RaceTrackBuilder.Track.start)
    GameObject.Destroy(RaceTrackBuilder.Track.finish)
    for k, trigger in pairs(iter(RaceTrackBuilder.Track.checkpoints)) do
        GameObject.Destroy(trigger)
        print(k)
    end
    GameObject.Destroy(RaceTrackBuilder.Track)
end

function RaceTrackBuilder:OnInspectorReady()
    if not self then
        return false
    end
    if not Inspector or not Inspector.wizzard then
        return false
    end
    local prop = {}
    if not RaceTrackBuilder.Settings.hasRace then
        prop = {
            name = "Make Race",
            tooltip = "Add a race Manager to this project",
            uiType = "buttonProperty",
            value = nil,
            func = function(v)
                RaceTrackBuilder.MakeRace()
            end
        }
        Inspector.wizzard:AddProperty(prop)
    else
        Inspector.wizzard:AddProperty(
            {
                name = "Delete Race",
                tooltip = "Add a race Manager to this project",
                uiType = "buttonProperty",
                value = nil,
                func = function(v)
                    RaceTrackBuilder.DeleteRace()
                end
            }
        )
        Inspector.wizzard:AddProperty(
            {
                name = "Set as Start",
                tooltip = "Sets the selected object as a Start",
                uiType = "buttonProperty",
                value = nil,
                func = function(v)
                    GameObject.Destroy(RaceTrackBuilder.Track.start)
                    RaceTrackBuilder.Track.start = RaceTrackBuilder.SetTriggers()
                end
            }
        )
        Inspector.wizzard:AddProperty(
            {
                name = "Set as checkpoint",
                tooltip = "Sets the selected object as a checkpoint",
                uiType = "buttonProperty",
                value = nil,
                func = function(v)
                    table.insert(RaceTrackBuilder.Track.checkpoint, RaceTrackBuilder.SetTriggers())
                end
            }
        )
        Inspector.wizzard:AddProperty(
            {
                name = "Set as Finish",
                tooltip = "Sets the selected object as a Finish",
                uiType = "buttonProperty",
                value = nil,
                func = function(v)
                    GameObject.Destroy(RaceTrackBuilder.Track.finish)
                    RaceTrackBuilder.Track.finish = RaceTrackBuilder.SetTriggers()
                end
            }
        )
    end
    return true
end

function RaceTrackBuilder.SetTriggers()
    local obj = HBBuilder.Builder.selection[1]
    local boxTrigger = obj:AddComponent("UnityEngine.BoxCollider")
    print(boxTrigger)
    boxTrigger.isTrigger = true
    local HBTrigger = obj:AddComponent("HBTrigger")
    HBTrigger.collider = boxTrigger
    HBTrigger.triggerOnVehicle = true
    HBTrigger.triggerOnPlayer = true
    HBTrigger.triggerOnSelf = true
    HBTrigger.triggerOnOther = true
    HBTrigger.onTrigger = function(obj)
        print(HBTrigger, "TRIGGERED!!!! REEEEEEEEEEEEEEEEEE : ", obj)
    end
    print(HBTrigger)
    return HBTrigger
end

function RaceTrackBuilder:OnEnableTool()
    RaceTrackBuilder.appliedInspectorColorPicker = false
end

function RaceTrackBuilder:OnDisableTool()
end

function RaceTrackBuilder:Awake()
end

function RaceTrackBuilder:Start()
    --register the tool with WorldEditor
    if WorldEditor and WorldEditor.RegisterTool then
        WorldEditor.RegisterTool(self)
    end
end

function RaceTrackBuilder:Update()
    if not RaceTrackBuilder.appliedInspectorColorPicker then
        RaceTrackBuilder.appliedInspectorColorPicker = self:OnInspectorReady()
    end
    self:Gizmo()
end

function RaceTrackBuilder:Gizmo()
    if RaceTrackBuilder.Track and not Slua.IsNull(RaceTrackBuilder.Track) then
        if RaceTrackBuilder.Track.start and not Slua.IsNull(RaceTrackBuilder.Track.start) then
            HBBuilder.GGizmo.DrawCube(
                RaceTrackBuilder.Track.start.transform.position,
                Vector3(5, 5, 5),
                Color(1, 0, 0, 1)
            )
        end
        if RaceTrackBuilder.Track.finish and not Slua.IsNull(RaceTrackBuilder.Track.finish) then
            HBBuilder.GGizmo.DrawCube(
                RaceTrackBuilder.Track.finish.transform.position,
                Vector3(5, 5, 5),
                Color(0, 0, 1, 1)
            )
        end

        for k, trigger in pairs(iter(RaceTrackBuilder.Track.checkpoints)) do
            HBBuilder.GGizmo.DrawCube(trigger.transform.position, Vector3(5, 5, 5), Color(0, 1, 0, 1))
        end
    end
end

function RaceTrackBuilder:OnDestroy()
    --unregister the tool
    if WorldEditor and WorldEditor.UnRegisterTool then
        WorldEditor.UnRegisterTool(self)
    end
end

function RaceTrackBuilder:ShiftKey()
    return (Input.GetKey(KeyCode.LeftShift) or Input.GetKey(KeyCode.RightShift))
end

function RaceTrackBuilder:AltKey()
    return (Input.GetKey(KeyCode.LeftAlt) or Input.GetKey(KeyCode.RightAlt))
end

function RaceTrackBuilder:ControlKey()
    return (Input.GetKey(KeyCode.LeftControl) or Input.GetKey(KeyCode.RightControl))
end

function RaceTrackBuilder:DeleteKey()
    return Input.GetKeyDown(KeyCode.Delete)
end

function RaceTrackBuilder:Mouse()
    return Input.GetMouseButton(0)
end

function RaceTrackBuilder:MouseDown()
    return Input.GetMouseButtonDown(0)
end

function RaceTrackBuilder:MouseUp()
    return Input.GetMouseButtonUp(0)
end

function RaceTrackBuilder:RightMouse()
    return Input.GetMouseButton(1)
end

function RaceTrackBuilder:MouseUp()
    return Input.GetMouseButtonUp(0)
end

return RaceTrackBuilder
