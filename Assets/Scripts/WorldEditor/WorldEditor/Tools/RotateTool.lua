local RotateTool = {}

RotateTool.ToolButton = {
  name = "Rotate Tool",
  icon = "lua/icons/builder/rotatetool.png",
  tooltip = "Rotate tool: use to rotate parts[4]",
  bigTooltip = [[Rotate tool: use to rotate parts
hold [shift] to rotate freely
[R] to snap to grid
hold [R] to snap to 90 degrees
[ctrl] + [c] to copy selection
[ctrl] + [v] to paste
[delete] to delete selection]],
  hoversound = "click_blip",
  clicksound = "affirm_blip_1",
  imageLayout = {"dualcolor", true},
  layout = {
    "shortcut",
    {
      key1 = KeyCode.Alpha4,
      useShift = false,
      func = function()
        WorldEditor.SelectTool(RotateTool)
      end
    }
  },
  shortcut = nil
  --[[ groupID = "transform" ]]
}

RotateTool.enabled = false

function RotateTool:Start()
  --register the tool with builder
  if WorldEditor and WorldEditor.RegisterTool then
    WorldEditor.RegisterTool(self, self.ToolButtonConfig)
  end
end

function RotateTool:OnDestroy()
  --unregister the tool
  if WorldEditor and WorldEditor.UnRegisterTool then
    WorldEditor.UnRegisterTool(self, self.ToolButtonConfig)
  end
end

function RotateTool:OnDisableTool()
  HBBuilder.Builder.StopRotationAxis()
end

function RotateTool:Update()
  if self and self.enabled == false then
    return
  end

  if not self or not self.enabled then
    return
  end

  if WorldEditor.Settings.MoveAll then
    return
  end

  --part selection while doing this stuff
  if SelectTool then
    SelectTool.rectSelectionEnabled = true
    SelectTool.enabled = true
    SelectTool.updateInspectorEnabled = false
  end

  if Input.GetKeyDown(KeyCode.R) then
    --stop the axis already
    HBBuilder.Builder.StopRotationAxis()

    --cache reset time
    self.resetPressTime = Time.time
    return
  end

  --hard reset ( will snap to 90 degrees )
  if Input.GetKey(KeyCode.R) and Time.time > self.resetPressTime + 1 then
    --cache reset time
    self.resetPressTime = Time.time

    --foreach selected>>
    if not Slua.IsNull(HBBuilder.Builder.selection) then
      for sel in Slua.iter(HBBuilder.Builder.selection) do
        if sel and not Slua.IsNull(sel) then
          --euler snap using 90 degrees
          sel.transform.eulerAngles = HBBuilder.Builder.EulerSnap(sel.transform.eulerAngles, 90)
        end
      end
    end

    --play hard reset sound
    WorldEditor.Play("reset")
    --Audio:Play("alert_flick",true,true)

    if Grid and Grid.SnapAllGridNodes then
      Grid:SnapAllGridNodes()
    end
    return
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
        rot = sel.transform.rotation

        break
      end
    end
  end

  --create/destroy axis
  if gotSelection then
    HBBuilder.Builder.StartRotationAxis(pos, rot, HBBuilder.Builder.selection, HBBuilder.Builder.root, true)
  else
    HBBuilder.Builder.StopRotationAxis()
  end
end

function RotateTool:MouseUp()
  return Input.GetMouseButtonUp(0)
end

return RotateTool
