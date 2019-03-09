AdjustTool = {}

-----------------------------------------------
--Tool Settings And UI Declaration
-----------------------------------------------

AdjustTool.ToolButton = {
  name = "Adjust Tool",
  icon = "lua/icons/worldeditor/adjusttool.png",
  tooltip = "Adjust Tool",
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
        WorldEditor.SelectTool(AdjustTool)
      end
    }
  },
  shortcut = nil
}

AdjustTool.settings = {
  isBoxCollider = false
}

AdjustTool.Inspector = {
  {
    name = "Adjust Tool",
    tooltip = "Shows you how to use the Inspector window",
    uiType = "headerProperty"
  },
  {
    name = "isBoxCollider",
    tooltip = "isBoxCollider",
    uiType = "boolProperty",
    value = function()
      return AdjustTool.settings.isBoxCollider
    end,
    func = function(v)
      AdjustTool.ChangeCollider(v)
    end
  }
}

function AdjustTool:OnEnableTool()
  if SelectTool then
    SelectTool.updateInspectorEnabled = false
    SelectTool.selectionEnabled = true
    SelectTool.rectSelectionEnabled = true
    SelectTool.clickSelectionEnabled = true
    SelectTool.copyPasteEnabled = true
  end
  self.enabeld = true
end

function AdjustTool:OnDisableTool()
  self.enabeld = false
end

function AdjustTool:Awake()
  self.enabeld = false
end

function AdjustTool:Start()
  --register the tool with WorldEditor
  if WorldEditor and WorldEditor.RegisterTool then
    WorldEditor.RegisterTool(self)
  end
end

function AdjustTool:Update()
  --[[   if
      self.enabeld == true and not HBU.OverGUI() and not HBU.OverUI() and not self:ControlKey() and not self:AltKey() and
        self:MouseDown()
    then
      self:ChangeUI()
    end ]]
end

function AdjustTool:OnDestroy()
  --unregister the tool
  if WorldEditor and WorldEditor.UnRegisterTool then
    WorldEditor.UnRegisterTool(self)
  end
end

function AdjustTool.ChangeCollider(hasBoxCollider)
  if Inspector then
    for obj in Slua.iter(HBBuilder.Builder.selection) do
      local partContainter = obj:GetComponent("PartContainer")
      if hasBoxCollider then
        partContainter.stringData =
          HBBuilder.BuilderUtils.SetStringData(partContainter.stringData, "isBoxCollider", "true")
      else
        partContainter.stringData =
          HBBuilder.BuilderUtils.SetStringData(partContainter.stringData, "isBoxCollider", "false")
      end
    end
  end
end

function AdjustTool:ShiftKey()
  return (Input.GetKey(KeyCode.LeftShift) or Input.GetKey(KeyCode.RightShift))
end

function AdjustTool:AltKey()
  return (Input.GetKey(KeyCode.LeftAlt) or Input.GetKey(KeyCode.RightAlt))
end

function AdjustTool:ControlKey()
  return (Input.GetKey(KeyCode.LeftControl) or Input.GetKey(KeyCode.RightControl))
end

function AdjustTool:DeleteKey()
  return Input.GetKeyDown(KeyCode.Delete)
end

function AdjustTool:Mouse()
  return Input.GetMouseButton(0)
end

function AdjustTool:MouseDown()
  return Input.GetMouseButtonDown(0)
end

function AdjustTool:MouseUp()
  return Input.GetMouseButtonUp(0)
end

function AdjustTool:RightMouse()
  return Input.GetMouseButton(1)
end

function AdjustTool:MouseUp()
  return Input.GetMouseButtonUp(0)
end

return AdjustTool
