SelectTool = {}

-----------------------------------------------
--config
-----------------------------------------------

SelectTool.selectionEnabled = true
SelectTool.rectSelectionEnabled = true
SelectTool.clickSelectionEnabled = true
SelectTool.updateInspectorEnabled = true
SelectTool.copyPasteEnabled = true

SelectTool.ToolButton = {
  name = "SelectTool",
  icon = "lua/icons/builder/selecttool.png",
  tooltip = "Select Tool: use to select parts [2]",
  bigTooltip = [[Select tool: use to select parts
  drag to rectangle select
  [shift] to add to your selection
  [ctrl] to remove from your selection
  [ctrl] + [c] to copy selection
  [ctlr] + [v] to paste
  [delete] to delete selection]],
  hoversound = "click_blip",
  clicksound = "affirm_blip_1",
  imageLayout = {"dualcolor", true},
  layout = {
    "shortcut",
    {
      key1 = KeyCode.Alpha2,
      useShift = false,
      func = function()
        WorldEditor.SelectTool(SelectTool)
      end
    }
  },
  shortcut = nil
}

-----------------------------------------------
--main logic
-----------------------------------------------

function SelectTool:Start()
  --register the tool with WorldEditor
  if WorldEditor and WorldEditor.RegisterTool then
    WorldEditor.RegisterTool(self)
  end
  self.lastSelectClickTime = 0
end

function SelectTool:OnDestroy()
  --unregister the tool
  if WorldEditor and WorldEditor.UnRegisterTool then
    WorldEditor.UnRegisterTool(self)
  end
end

function SelectTool:Update()
  if not self or not self.selectionEnabled then
    HBBuilder.Builder.Highlight(nil, "")
    return
  end

  -----------------------------------------------

  -----------------------------------------------
  --handle selection
  -----------------------------------------------
  if self.rectSelectionEnabled then
    self:HandleRectSelect()
  end

  self:HandlePartSelection()

  -----------------------------------------------

  --reset stopped dragging this frame
  self.stoppedDraggingThisFrame = false
end

-----------------------------------------------

-----------------------------------------------
--part selection
-----------------------------------------------

function SelectTool:OnSelectionChanged()
  --set selection as target in inspector
  if self.updateInspectorEnabled and Inspector then
    Inspector:SetTarget(HBBuilder.Builder.selection)
  end
end

function SelectTool:HandleRectSelect()
  --start looking for drag
  if not HBU.OverUI() and not HBU.OverGUI() and not HBBuilder.Builder.OverAxis() and self:MouseDown() then
    self.rectMousePositionStart = Input.mousePosition
    self.lookForRectDrag = true
  end

  --stop looking for drag
  if self.lookForRectDrag and self:MouseUp() then
    self.lookForRectDrag = false
  end

  --start dragging
  if self.lookForRectDrag and self:Mouse() then
    if Vector3.Distance(self.rectMousePositionStart, Input.mousePosition) > 5 then
      self.rectDragging = true
    end
  end

  --handle rect dragging
  if self.rectDragging and self:Mouse() then
    --simplify start / end point
    local s = self.rectMousePositionStart
    local e = Input.mousePosition
    --calc rect
    self.dragRect =
      Rect(
      Mathf.Min(s.x, e.x),
      Mathf.Min(s.y, e.y),
      Mathf.Max(s.x, e.x) - Mathf.Min(s.x, e.x),
      Mathf.Max(s.y, e.y) - Mathf.Min(s.y, e.y)
    )
    --draw rect
    self:DrawRect(self.dragRect)
  end
end

function SelectTool:HandlePartSelection()
  if not self then
    return
  end

  -----------------------------------------------
  --highlight
  -----------------------------------------------

  HBBuilder.Builder.Highlight(nil, "")
  local s = HBBuilder.Builder.selection
  if not Slua.IsNull(s) then
    for selected in Slua.iter(s) do
      HBBuilder.Builder.Highlight(selected, "+")
    end
  end

  -----------------------------------------------

  -----------------------------------------------
  --delete
  -----------------------------------------------
  if HBU.OverUI() == false and HBU.OverGUI() == false then
    if self:DeleteKey() then
      --delete
      self:DeleteSelection()
      --unselect
      HBBuilder.Builder.Select(nil, "")
      WorldEditor.Play("cancel")
      --Audio:Play("affirm-techy-2-techy-2",true,true);
      self:OnSelectionChanged()
      return
    end
  end

  -----------------------------------------------

  -----------------------------------------------
  --copy
  -----------------------------------------------
  if self.copyPasteEnabled and self:CopyKey() and not HBU.Typing() and not HBU.OverUI() and not HBU.OverGUI() then
    self:Copy()
    return
  end

  -----------------------------------------------

  -----------------------------------------------
  --paste
  -----------------------------------------------
  if self.copyPasteEnabled and self:PasteKey() and not HBU.Typing() and not HBU.OverUI() and not HBU.OverGUI() then
    self:Paste()
    return
  end

  -----------------------------------------------
  --raycast
  -----------------------------------------------

  local ray = HBBuilder.Builder.MouseRay()
  local over, hit = Physics.Raycast(ray, Slua.out, 1 << 20)
  local hitObject = nil
  if over and (hit.collider and not Slua.IsNull(hit.collider)) then
    if hit.collider.transform:IsChildOf(HBBuilder.Builder.currentAssembly.transform) then
      hitObject = self:GetTopParent(hit.collider.gameObject)
      over = true
    else
      over = false
    end
  end

  -----------------------------------------------
  --use rect select
  -----------------------------------------------

  --stop rect drag
  if self.rectDragging and self.MouseUp() then
    self.rectDragging = false
    self.stoppedDraggingThisFrame = true
    self:SelectRect(self.dragRect)
  end

  --stop when we are dragging
  if self.rectDragging then
    return
  end

  -----------------------------------------------

  -----------------------------------------------
  --click select
  -----------------------------------------------
  if self.clickSelectionEnabled then
    if not HBU:OverUI() and not HBU.OverGUI() and not HBBuilder.Builder.OverAxis() and not self.stoppedDraggingThisFrame then
      if over then
        HBBuilder.GGizmo.DrawDot(hit.point, Color.white, Color.black)
        --HBBuilder.GGizmo.DrawArrow(hit.point,Quaternion.LookRotation(hit.normal),1,Color.red)
        --HBBuilder.GGizmo.DrawRotationArrow(hit.point,Quaternion.LookRotation(hit.normal),1,Color.red)
        if self:MouseUp() then
          if self.lastSelectClickObject == hitObject and Time.time < self.lastSelectClickTime + 0.2 then
            --doubleclick select
            HBBuilder.Builder.Select(nil, "")
            for i, sameO in ipairs(self:GetSimilarParts(hitObject)) do
              HBBuilder.Builder.Select(sameO, "+")
            end
            self:OnSelectionChanged()
          elseif self:ShiftKey() then
            --add select
            HBBuilder.Builder.Select(hitObject, "+")
            WorldEditor.Play("select")
            --Audio:Play("affirm-techy-2",true,true);
            self:OnSelectionChanged()
          else
            if self:ControlKey() then
              --toggle select
              HBBuilder.Builder.Select(hitObject, "?")
              WorldEditor.Play("select")
              --Audio:Play("affirm-techy-2",true,true);
              self:OnSelectionChanged()
            else
              --set select
              HBBuilder.Builder.Select(hitObject, "")
              WorldEditor.Play("select")
              --Audio:Play("affirm-techy-2",true,true);
              self:OnSelectionChanged()
            end
          end

          --cache last click time and object
          self.lastSelectClickTime = Time.time
          self.lastSelectClickObject = hitObject
        end
      else
        if self:MouseUp() and not self:ShiftKey() and not self:ControlKey() then
          --unselect all
          HBBuilder.Builder.Select(nil, "")
          WorldEditor.Play("cancel")
          --Audio:Play("affirm-techy-2",true,true);
          self:OnSelectionChanged()
        end
      end
    end
  end

  -----------------------------------------------
end

function SelectTool:Copy()
  if not self then
    return
  end
  --cache current selection
  self.copyGameObjects = iter(HBBuilder.Builder.selection)
  WorldEditor.Play("copy")
  --Audio:Play("affirm-melodic-4",true,true);
end

function SelectTool:Paste()
  if not self then
    return
  end
  if self.copyGameObjects and type(self.copyGameObjects) == "table" and #self.copyGameObjects > 0 then
    HBBuilder.Builder.Select(nil, "")
    for k, OriginalPart in pairs(self.copyGameObjects) do
      if not OriginalPart or Slua.IsNull(OriginalPart) then
        return
      end
      local copiedPart = HBBuilder.Builder.CloneGameObject(OriginalPart)
      copiedPart.transform.position = OriginalPart.transform.position
      copiedPart.transform.rotation = OriginalPart.transform.rotation
      copiedPart.transform.parent = HBBuilder.Builder.currentAssembly.bodyContainer.transform
      copiedPart.name = OriginalPart.name
      HBBuilder.Builder.Select(copiedPart, "+")
    end
    WorldEditor.Play("paste")
    self:OnSelectionChanged()
  end
end

function SelectTool:DeleteSelection()
  --delete
  if not Slua.IsNull(HBBuilder.Builder.selection) then
    for selected in Slua.iter(HBBuilder.Builder.selection) do
      if selected and not Slua.IsNull(selected) then
        GameObject.Destroy(selected.gameObject)
      end
    end
  end
end

function SelectTool:GetSimilarParts(obj)
  local ret = {}
  for part in Slua.iter(HBBuilder.Builder.currentAssembly.bodyContainer.transform) do
    if obj.name == part.name then
      table.insert(ret, part.gameObject)
    end
  end
  return ret
end

function SelectTool:SelectRect(rect)
  if not rect or Slua.IsNull(rect) then
    return
  end
  if not self:ShiftKey() and not self:ControlKey() then
    HBBuilder.Builder.Select(nil, "")
  end
  for k, part in pairs(WorldEditor.GetAll()) do
    local screenPoint = Camera.main:WorldToScreenPoint(part.transform.position)
    if screenPoint.z > 0 and rect:Contains(screenPoint) then
      if self:ControlKey() then
        HBBuilder.Builder.Select(part, "?")
      else
        HBBuilder.Builder.Select(part, "+")
      end
    end
  end
  WorldEditor.Play("select")
  --Audio:Play("affirm-techy-2",true,true);
  self:OnSelectionChanged()
end

function SelectTool:DrawRect(rect)
  if not rect or Slua.IsNull(rect) then
    return
  end
  local p1 = Camera.main:ScreenToWorldPoint(Vector3(rect.x, rect.y, 1))
  local p2 = Camera.main:ScreenToWorldPoint(Vector3(rect.x + rect.width, rect.y, 1))
  local p3 = Camera.main:ScreenToWorldPoint(Vector3(rect.x + rect.width, rect.y + rect.height, 1))
  local p4 = Camera.main:ScreenToWorldPoint(Vector3(rect.x, rect.y + rect.height, 1))
  HBBuilder.GGizmo.DrawLine(Matrix4x4.identity, p1, p2, BUI.colors.color)
  HBBuilder.GGizmo.DrawLine(Matrix4x4.identity, p2, p3, BUI.colors.color)
  HBBuilder.GGizmo.DrawLine(Matrix4x4.identity, p3, p4, BUI.colors.color)
  HBBuilder.GGizmo.DrawLine(Matrix4x4.identity, p4, p1, BUI.colors.color)
end

function SelectTool:GetTopParent(object)
  if not self then
    return
  end
  for child in Slua.iter(HBBuilder.Builder.currentAssembly.bodyContainer.transform) do
    if object.transform == child.transform or self:AltKey() then
      return object.gameObject
    else
      if object.transform:IsChildOf(child.transform) then
        return child.gameObject
      end
    end
  end

  for child in Slua.iter(WorldEditor.TerrainParent.transform) do
    if object.transform == child.transform then
      return object.gameObject
    end
  end
end

-----------------------------------------------
--utils
-----------------------------------------------

function SelectTool:CopyKey()
  return ((Input.GetKey(KeyCode.LeftControl) or Input.GetKey(KeyCode.RightControl)) and Input.GetKeyDown(KeyCode.C))
end

function SelectTool:PasteKey()
  return ((Input.GetKey(KeyCode.LeftControl) or Input.GetKey(KeyCode.RightControl)) and Input.GetKeyDown(KeyCode.V))
end

function SelectTool:ShiftKey()
  return (Input.GetKey(KeyCode.LeftShift) or Input.GetKey(KeyCode.RightShift))
end

function SelectTool:AltKey()
  return (Input.GetKey(KeyCode.LeftAlt) or Input.GetKey(KeyCode.RightAlt))
end

function SelectTool:ControlKey()
  return (Input.GetKey(KeyCode.LeftControl) or Input.GetKey(KeyCode.RightControl))
end

function SelectTool:DeleteKey()
  return Input.GetKeyDown(KeyCode.Delete)
end

function SelectTool:Mouse()
  return Input.GetMouseButton(0)
end

function SelectTool:MouseDown()
  return Input.GetMouseButtonDown(0)
end

function SelectTool:MouseUp()
  return Input.GetMouseButtonUp(0)
end

function SelectTool:RightMouse()
  return Input.GetMouseButton(1)
end

function SelectTool:MousePosition()
  return Input.mousePosition
end

-----------------------------------------------

return SelectTool
