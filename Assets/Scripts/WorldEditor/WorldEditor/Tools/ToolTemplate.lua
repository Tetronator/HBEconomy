ToolTemplate = {}

-----------------------------------------------
--Tool Settings And UI Declaration
-----------------------------------------------

ToolTemplate.ToolButton = {
  name = "Tool Name",
  icon = "lua/icons/worldeditor/ToolTemplate.png",
  tooltip = "Small Tool Discription",
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
        WorldEditor.SelectTool(ToolTemplate)
      end
    }
  },
  shortcut = nil
  --groupID = "Tut"
}

ToolTemplate.Inspector = {
  {
    name = "Tool Template",
    tooltip = "Shows you how to use the Inspector window",
    uiType = "headerProperty"
  },
  {
    name = "Boolean Property",
    tooltip = "This returns a True or False value",
    uiType = "boolProperty",
    value = function()
      return ToolTemplate.Settings.boolean
    end,
    func = function(v)
      ToolTemplate.Settings.boolean = v
    end
  }
}

ToolTemplate.Settings = {
  boolean = true
}

function ToolTemplate:OnEnableTool()
end

function ToolTemplate:OnDisableTool()
end

function ToolTemplate:Awake()
end

function ToolTemplate:Start()
  --register the tool with WorldEditor
  if WorldEditor and WorldEditor.RegisterTool then
    WorldEditor.RegisterTool(self)
  end
end

function ToolTemplate:Update()
end

function ToolTemplate:OnDestroy()
  --unregister the tool
  if WorldEditor and WorldEditor.UnRegisterTool then
    WorldEditor.UnRegisterTool(self)
  end
end

function ToolTemplate:ShiftKey()
  return (Input.GetKey(KeyCode.LeftShift) or Input.GetKey(KeyCode.RightShift))
end

function ToolTemplate:AltKey()
  return (Input.GetKey(KeyCode.LeftAlt) or Input.GetKey(KeyCode.RightAlt))
end

function ToolTemplate:ControlKey()
  return (Input.GetKey(KeyCode.LeftControl) or Input.GetKey(KeyCode.RightControl))
end

function ToolTemplate:DeleteKey()
  return Input.GetKeyDown(KeyCode.Delete)
end

function ToolTemplate:Mouse()
  return Input.GetMouseButton(0)
end

function ToolTemplate:MouseDown()
  return Input.GetMouseButtonDown(0)
end

function ToolTemplate:MouseUp()
  return Input.GetMouseButtonUp(0)
end

function ToolTemplate:RightMouse()
  return Input.GetMouseButton(1)
end

function ToolTemplate:MouseUp()
  return Input.GetMouseButtonUp(0)
end


return ToolTemplate
