TrackBuilder = {}

-----------------------------------------------
--Tool Settings And UI Declaration
-----------------------------------------------
TrackBuilder.ToolButton = {
  name = "TrackBuilder",
  icon = "lua/icons/worldeditor/ToolTemplate.png",
  tooltip = "TrackBuilder",
  bigTooltip = [[Used to make roads and track]],
  hoversound = "click_blip",
  clicksound = "affirm_blip_1",
  imageLayout = {"dualcolor", true},
  layout = {
    "shortcut",
    {
      key1 = KeyCode.Alpha8,
      useShift = false,
      func = function()
        WorldEditor.SelectTool(TrackBuilder)
      end
    }
  },
  shortcut = nil
}

TrackBuilder.Settings = {
  Template = nil,
  TemplateName = "",
  addToPath = false,
  path = {}
}

TrackBuilder.Inspector = {
  {
    name = "TrackBuilder",
    tooltip = "settings for the TrackBuilder tool",
    uiType = "headerProperty"
  },
  {
    name = "Template",
    tooltip = "The name of the template to extrude",
    uiType = "text",
    value = TrackBuilder.Settings.TemplateName
  },
  {
    name = "Set Template",
    tooltip = "Set Track Template",
    uiType = "buttonProperty",
    value = nil,
    func = function(v)
      print("SET TRACK TEMPLATE")
    end
  },
  {
    name = "Path",
    tooltip = "The name of the template to extrude",
    uiType = "text",
    value = ""
    --TrackBuilder.PathToString(TrackBuilder.Settings.path)
  }
}

function TrackBuilder:OnEnableTool()
end

function TrackBuilder:OnDisableTool()
end

function TrackBuilder:Awake()
end

function TrackBuilder:Start()
  --register the tool with WorldEditor
  if WorldEditor and WorldEditor.RegisterTool then
    WorldEditor.RegisterTool(self)
  end
end

function TrackBuilder:Update()
  if TrackBuilder.Settings.Template == nil or Slua.IsNull(TrackBuilder.Settings.Template) then
    return
  end

  if TrackBuilder.Settings.addToPath then
    if self:MouseDown() and not HBU.OverGUI() and not HBU.OverUI() and not HBU.Typing() then
    end
  end
end

function TrackBuilder:OnDestroy()
  --unregister the tool
  if WorldEditor and WorldEditor.UnRegisterTool then
    WorldEditor.UnRegisterTool(self)
  end
end

function TrackBuilder.DrawNodes(nodePoints)
  if not nodePoints then
    return
  end
  for i, point in ipairs(nodePoints) do
    HBBuilder.GGizmo.DrawCircleFilled(point, 0.5, BUI.colors.color)
    HBBuilder.GGizmo.DrawCircle(point, 0.6, BUI.colors.altColor)
  end
end

function TrackBuilder:ShiftKey()
  return (Input.GetKey(KeyCode.LeftShift) or Input.GetKey(KeyCode.RightShift))
end

function TrackBuilder:AltKey()
  return (Input.GetKey(KeyCode.LeftAlt) or Input.GetKey(KeyCode.RightAlt))
end

function TrackBuilder:ControlKey()
  return (Input.GetKey(KeyCode.LeftControl) or Input.GetKey(KeyCode.RightControl))
end

function TrackBuilder:DeleteKey()
  return Input.GetKeyDown(KeyCode.Delete)
end

function TrackBuilder:Mouse()
  return Input.GetMouseButton(0)
end

function TrackBuilder:MouseDown()
  return Input.GetMouseButtonDown(0)
end

function TrackBuilder:MouseUp()
  return Input.GetMouseButtonUp(0)
end

function TrackBuilder:RightMouse()
  return Input.GetMouseButton(1)
end

function TrackBuilder:MouseUp()
  return Input.GetMouseButtonUp(0)
end

return TrackBuilder
