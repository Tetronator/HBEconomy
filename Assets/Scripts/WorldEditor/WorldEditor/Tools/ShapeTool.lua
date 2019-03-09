ShapeTool = {}

-----------------------------------------------
--Tool Settings And UI Declaration
-----------------------------------------------

ShapeTool.ToolButton = {
  name = "Shape Tool",
  icon = "lua/icons/worldeditor/shapetool.png",
  tooltip = "Shape Tool",
  bigTooltip = [[Big Tool Discription]],
  hoversound = "click_blip",
  clicksound = "affirm_blip_1",
  imageLayout = {"dualcolor", true},
  layout = {
    "shortcut",
    {
      key1 = KeyCode.Alpha0,
      useShift = false,
      func = function()
        WorldEditor.SelectTool(ShapeTool)
      end
    }
  },
  shortcut = nil
}

ShapeTool.Inspector = {
  {
    name = "Shape Tool",
    tooltip = "Shows you how to use the Inspector window",
    uiType = "headerProperty"
  },
  {
    name = "Boolean Property",
    tooltip = "This returns a True or False value",
    uiType = "boolProperty",
    value = function()
      return ShapeTool.Settings.boolean
    end,
    func = function(v)
      ShapeTool.Settings.boolean = v
    end
  }
}

ShapeTool.Settings = {
  boolean = true
}

function ShapeTool:OnEnableTool()
end

function ShapeTool:OnDisableTool()
end

function ShapeTool:Awake()
end

function ShapeTool:Start()
  --register the tool with WorldEditor
  if WorldEditor and WorldEditor.RegisterTool then
    WorldEditor.RegisterTool(self)
  end
end

function ShapeTool:Update()
end

function ShapeTool:OnDestroy()
  --unregister the tool
  if WorldEditor and WorldEditor.UnRegisterTool then
    WorldEditor.UnRegisterTool(self)
  end
end

function ShapeTool:ShiftKey()
  return (Input.GetKey(KeyCode.LeftShift) or Input.GetKey(KeyCode.RightShift))
end

function ShapeTool:AltKey()
  return (Input.GetKey(KeyCode.LeftAlt) or Input.GetKey(KeyCode.RightAlt))
end

function ShapeTool:ControlKey()
  return (Input.GetKey(KeyCode.LeftControl) or Input.GetKey(KeyCode.RightControl))
end

function ShapeTool:DeleteKey()
  return Input.GetKeyDown(KeyCode.Delete)
end

function ShapeTool:Mouse()
  return Input.GetMouseButton(0)
end

function ShapeTool:MouseDown()
  return Input.GetMouseButtonDown(0)
end

function ShapeTool:MouseUp()
  return Input.GetMouseButtonUp(0)
end

function ShapeTool:RightMouse()
  return Input.GetMouseButton(1)
end

function ShapeTool:MouseUp()
  return Input.GetMouseButtonUp(0)
end

return ShapeTool
