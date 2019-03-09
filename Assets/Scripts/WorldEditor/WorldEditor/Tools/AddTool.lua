local AddTool = {}

AddTool.ToolButton = {
  name = "AddTool",
  icon = "lua/icons/builder/addtool.png",
  tooltip = "Add tool: Place parts onto your craft [1]",
  bigTooltip = [[Add Tool: Place parts onto your craft
  [R] or [Scroll] to rotate
  hold [ctrl] to rotate around X-axis
  hold [alt] to rotate around Z-axis
  [ctrl] click welded part to pick it up]],
  hoversound = "click_blip",
  clicksound = "affirm_blip_1",
  imageLayout = {"dualcolor", true},
  layout = {
    "shortcut",
    {
      key1 = KeyCode.Alpha1,
      useShift = false,
      func = function()
        WorldEditor.SelectTool(AddTool)
      end
    }
  },
  shortcut = nil
}

AddTool.Inspector = {
  {
    name = "Add Tool",
    tooltip = "Add Tool Properties",
    uiType = "headerProperty"
  },
  {
    name = "Grid Snap",
    tooltip = "snaps the part to absolute grid",
    uiType = "boolProperty",
    value = function()
      return AddTool.Settings.gridSnap
    end,
    func = function(v)
      AddTool.Settings.gridSnap = v
    end
  },
  {
    name = "Relative To Other Part",
    tooltip = "places the part relative to the other part (this will make it inherit rotation and position)",
    uiType = "boolProperty",
    value = function()
      return AddTool.Settings.relativeToOtherPart
    end,
    func = function(v)
      AddTool.Settings.relativeToOtherPart = v
    end
  }
}

AddTool.Settings = {
  gridSnap = true,
  relativeToOtherPart = false
}

function AddTool:Start()
  --register the tool with builder
  if WorldEditor and WorldEditor.RegisterTool then
    WorldEditor.RegisterTool(self, self.ToolButtonConfig)
  end
  --hide builder browser/parts bar
  if WorldEditor and WorldEditor.browserBar then
    WorldEditor.browserBar:SetActive(false)
  end
  if WorldEditor and WorldEditor.partsBar then
    WorldEditor.partsBar:SetActive(false)
  end
  --hookup callback on spawn part
  HBBuilder.Builder.RegisterCallback(
    HBBuilder.BuilderCallback.SpawnPart,
    "AddToolOnSpawnPart",
    function()
      self:OnSpawnedPart(HBBuilder.Builder.GetLastSpawnedPart())
    end
  )
  --Builder.RegisterOnSpawnPartCallback( function(part) self:OnSpawnedPart(part) end )
end

function AddTool:OnDestroy()
  --unregister the tool
  if WorldEditor and WorldEditor.UnRegisterTool then
    WorldEditor.UnRegisterTool(self, self.ToolButtonConfig)
  end
  --unhide builder browser/parts bar
  if WorldEditor and WorldEditor.browserBar then
    WorldEditor.browserBar:SetActive(false)
  end
  self:DestroyPlaceIcon()
end

function AddTool:OnEnableTool()
  --unhide builder browser/parts bar ( make sothat browser bar is only active when we have this tool selected )
  if WorldEditor and WorldEditor.browserBar then
    WorldEditor.browserBar:SetActive(true)
    HBBuilder.Builder.TriggerCallback(HBBuilder.BuilderCallback.RefreshUIIndicators)
  end

  if SelectTool then
    SelectTool.updateInspectorEnabled = false
    SelectTool.selectionEnabled = false
    SelectTool.rectSelectionEnabled = false
    SelectTool.clickSelectionEnabled = false
    SelectTool.copyPasteEnabled = false
  end
end

function AddTool:OnDisableTool()
  --hide builder browser/parts bar ( make sothat browser bar is only active when we have this tool selected )
  if WorldEditor and WorldEditor.browserBar then
    WorldEditor.browserBar:SetActive(false)
  end
  if WorldEditor and WorldEditor.partsBar then
    WorldEditor.partsBar:SetActive(false)
  end
  if SelectTool then
    SelectTool.updateInspectorEnabled = true
    SelectTool.selectionEnabled = true
    SelectTool.rectSelectionEnabled = true
    SelectTool.clickSelectionEnabled = true
    SelectTool.copyPasteEnabled = true
  end
  self:DestroyPlaceIcon()
end

function AddTool:OnSpawnedPart(part)
  if not self then
    return
  end
  if not self.enabled then
    return
  end
  if not part or Slua.IsNull(part) then
    return
  end
  --destroy current part if we are alreayd placing
  if self.placingPart then
    print("AddTool: OnSpawnedPart: destroying: " .. self.part.gameObject.name)
    GameObject.Destroy(self.part)
  end

  --destroy place icon if we had one ( this will make it pick the new image )
  self:DestroyPlaceIcon()

  --enable placing
  self.placingPart = true

  --cache part gameObject
  self.part = part

  --cach partPartcontainer
  self.partContainer = part:GetComponent("PartContainer")

  --if we have an adjustable gen it
  local adjustable = part:GetComponentInChildren("HBBuilder.Adjustable")
  if not Slua.IsNull(adjustable) then
    if Generator and Generator.Generate then
      Generator:Generate(adjustable)
    end
  end

  local meshCollider = part:GetComponentInChildren("UnityEngine.MeshCollider")

  WorldEditor.Play("new")
end

function AddTool:Update()
  --stop of tool is not selected
  if not self or not self.enabled then
    return
  end

  --check for grabbing a part
  if not self.placingPart then
    -----------------------------------
    -----------------------------------
    --not placing parts
    -----------------------------------

    self:DestroyPlaceIcon()

    --do raycast ( only racyast colliders )
    --GameObject root, Ray ray, int physicsRaycastLayer, out BuilderRaycastHit hit, bool ignoreColliders = false, bool ignoreFrames = false, bool ignoreHulls = false, bool ignoreBounds = true, bool ignoreInactive = true, bool ignoreVerts = false, bool ignoreLines = false, bool ignoreQuads = false, bool ignoreTris = false, float lineRadius = 0.03f, float vertRadius = 0.03f, bool snapBounds = true, float snapBoundsScale = 0.1f
    local ok, hit =
      HBBuilder.BuilderUtils.BuilderRaycast(
      HBBuilder.Builder.currentAssembly.gameObject,
      HBBuilder.Builder.MouseRay(),
      1 << 19,
      Slua.out,
      false,
      true,
      true,
      true,
      true,
      false,
      false,
      false,
      false,
      0.03,
      0.03,
      self.Settings.gridSnap or false,
      HBBuilder.Builder.grid
    )

    if ok then
      --draw pickup
      self:DrawPickupPoint(hit)

      --on mouse button down in wokspace
      if HBU.OverUI() == false and HBU.OverGUI() == false and self:MouseDown() and self:ControlKey() then
        --pickup part
        self:PickupPart(hit.gameObject)
        self.placingPart = true
      end
    end
  else
    -----------------------------------
    -----------------------------------
    --placing parts
    -----------------------------------

    --stop placing if part becomes null
    if not self.part or Slua.IsNull(self.part) then
      self.placingPart = false
      return
    end

    --do raycast ( only racyast hull , frame and bounds )
    --GameObject root, Ray ray, int physicsRaycastLayer, out BuilderRaycastHit hit, bool ignoreColliders = false, bool ignoreFrames = false, bool ignoreHulls = false, bool ignoreBounds = true, bool ignoreInactive = true, bool ignoreVerts = false, bool ignoreLines = false, bool ignoreQuads = false, bool ignoreTris = false, float lineRadius = 0.03f, float vertRadius = 0.03f, bool snapBounds = true, float snapBoundsScale = 0.1f
    local ok, hit =
      HBBuilder.BuilderUtils.BuilderRaycast(
      nil,
      HBBuilder.Builder.MouseRay(),
      1 << 19 | 1 << 0 | 1 << 11 | 1 << 10,
      Slua.out,
      false,
      false,
      false,
      true,
      true,
      false,
      false,
      false,
      false,
      0.05,
      0.05,
      self.Settings.gridSnap or false,
      HBBuilder.Builder.grid
    )

    if ok and not HBU.OverUI() and not HBU.OverGUI() and not HBU.Typing() then
      --destory place icon
      self:DestroyPlaceIcon()

      --apply part position/rotation
      local pos, rot = self:CalcWeld(hit, self.partContainer)
      if pos and rot then
        self.part.transform.position = pos
        self.part.transform.rotation = rot

        if self:MouseDown() then
          --place the part
          self.placingPart = false
          self:PlacePart(hit, self.partContainer)
        end
      else
        if self:MouseDown() then
          -----------------------------------
          --cancel placing parts
          -----------------------------------

          self.placingPart = false

          --cancel placing the part
          print("AddTool: Update: destroying: " .. self.part.gameObject.name)
          GameObject.Destroy(self.part)

          WorldEditor.Play("cancel")

        -----------------------------------
        end
      end
    else
      -----------------------------------
      -----------------------------------
      --cancel placing parts
      -----------------------------------

      --update place icon
      self:ShowPlaceIcon()

      --if we dont hit anything set part position wayy over yonder
      self.part.transform.position = Vector3(0, -100000, 0)
      self.part.transform.parent = HBBuilder.Builder.weldContainer.transform

      if (self:MouseDown() or self:DeleteKey()) and not HBU.OverGUI() and not HBU.OverUI() then
        self.placingPart = false

        --remove other part
        if Symmetry and Symmetry.RemovePart then
          Symmetry:RemovePart(self.part)
        end

        --cancel placing the part
        print("AddTool: Update: destroying: " .. self.part.gameObject.name)
        GameObject.Destroy(self.part)

        WorldEditor.Play("cancel")
      end
    end
  end
end

function AddTool:CalcWeld(hit, partContainer)
  if not self then
    return
  end
  if not partContainer or Slua.IsNull(partContainer) then
    return
  end
  if not hit or Slua.IsNull(hit) then
    return
  end

  -----------------------------------
  --handle rotation
  -----------------------------------

  if not self.offsetRotation then
    self.offsetRotation = Quaternion.identity
  end
  if Input.GetKeyDown(KeyCode.R) or self:Scroll() ~= 0 then
    local direction = 1
    if self:Scroll() < 0 then
      direction = -1
    end
    if self:AltKey() then
      self.offsetRotation = self.offsetRotation * Quaternion.Euler(0, 0, 90 * direction)
    elseif self:ControlKey() then
      self.offsetRotation = self.offsetRotation * Quaternion.Euler(90 * direction, 0, 0)
    else
      self.offsetRotation = self.offsetRotation * Quaternion.Euler(0, 90 * direction, 0)
    end
  end
  local rot = self.offsetRotation
  if self.Settings and self.Settings.relativeToOtherPart then
    rot = hit.gameObject.transform.rotation * self.offsetRotation
  end

  -----------------------------------

  -----------------------------------
  --handle position
  -----------------------------------

  local pos = hit.point
  local boundsOffset =
    -self:CalcBoundsFacePointFromDirection(partContainer.transform, partContainer.bounds, -hit.normal)
  local centerOffset = self:CalcCenterOffset(partContainer)

  pos = pos + boundsOffset

  local centerPoint = pos - centerOffset
  local preCenterPoint = pos - centerOffset

  if self.Settings and self.Settings.gridSnap then
    if self.Settings and self.Settings.relativeToOtherPart then
      centerPoint = HBBuilder.BuilderUtils.Snap(centerPoint, HBBuilder.Builder.grid, hit.gameObject)
    else
      centerPoint =
        HBBuilder.BuilderUtils.Snap(centerPoint, HBBuilder.Builder.grid, HBBuilder.Builder.currentAssembly.gameObject)
    end
  end

  pos = pos + (centerPoint - preCenterPoint)

  if pos.magnitude > 2000000 then
    pos = HBBuilder.Builder.root.gameObject.transform.position
    HBBuilder.GGizmo.DrawText(
      "addtool-fail",
      pos + (Camera.main.transform.right * -1),
      [[calculate position
  failed
  
  Use Place On Surface]],
      Color.red,
      2,
      22
    )
    return false
  end

  ------------------------------------

  ------------------------------------
  --draw indicators
  ------------------------------------

  local col = Color.green
  local dir = partContainer.transform.up
  if self:AltKey() then
    col = Color.blue
    dir = partContainer.transform.forward
  elseif self:ControlKey() then
    col = Color.red
    dir = partContainer.transform.right
  else
    col = Color.green
    dir = partContainer.transform.up
  end

  HBBuilder.GGizmo.DrawRotationArrow(pos - boundsOffset, Quaternion.LookRotation(dir), 1, col)
  HBBuilder.GGizmo.DrawText(
    "addtool-r-to-rotate",
    pos - boundsOffset + (Camera.main.transform.right * -0.05),
    "[R]",
    Color.white,
    1,
    22
  )

  --HBBuilder.GGizmo.DrawRotationArrow(hit.point,Quaternion.LookRotation(dir),1,col)
  --HBBuilder.GGizmo.DrawText("addtool-r-to-rotate",hit.point + (Camera.main.transform.right * -0.05),"[R]",Color.white,1,22)

  ------------------------------------

  return pos, rot
end

function AddTool:GetNormal(hit)
  --take normal from hit
  local normal = hit.normal

  --align the axis when over hull/frame local to bodycontainer
  if hit.overHull or hit.overFrame then
    normal = HBBuilder.BuilderUtils.AlignAxis(normal)
  end

  return normal
end

function AddTool:CalcCenterOffset(partContainer)
  return Vector3.zero
  --local centerOffset = Vector3.zero
  --if not self then return centerOffset end
  --if not partContainer or Slua.IsNull(partContainer) then return centerOffset end
  --if Grid and Grid.Settings then
  --  --calc grab position
  --  local grabPosition = pos
  --  if not Grid.Settings.useCogAsCenter then
  --    --center of bounds
  --    grabPosition = partContainer.transform:TransformPoint(partContainer.bounds.center)
  --  else
  --    --center of gravity
  --    grabPosition = partContainer.transform:TransformPoint(Vector3(partContainer.cog.x,partContainer.cog.y,partContainer.cog.z))
  --  end
  --  --calc offset between grab position and gamobject position
  --  centerOffset =  partContainer.transform.position - grabPosition
  --end
  --return centerOffset
end

function AddTool:CalcBoundsFacePointFromDirection(transform, bounds, direction)
  --get all face points of the bounds
  local faces = iter(HBBuilder.BuilderUtils.GetBoundsFaces(bounds))

  --make direction local to the transform of the bounds
  local weldAxis = transform:InverseTransformDirection(direction)
  local faceIndex = 1

  --calc Bounds face index from direction
  if weldAxis.x > 0.6 then
    faceIndex = 1
  end
  if weldAxis.x < -0.6 then
    faceIndex = 2
  end
  if weldAxis.y > 0.6 then
    faceIndex = 3
  end
  if weldAxis.y < -0.6 then
    faceIndex = 4
  end
  if weldAxis.z > 0.6 then
    faceIndex = 5
  end
  if weldAxis.z < -0.6 then
    faceIndex = 6
  end

  --create local offset to this bounds
  local localOffset = transform:TransformDirection(faces[faceIndex])

  --create world point of the offset on this bounds
  local worldPoint = transform:TransformPoint(faces[faceIndex])
  return localOffset, worldPoint
end

function AddTool:DrawPickupPoint(hit)
  HBBuilder.GGizmo.DrawDisc(hit.point, 0.05, Quaternion.LookRotation(hit.normal), Color.white)
end

function AddTool:PlacePart(hit, partContainer)
  --get the parent for this part
  local parent = HBBuilder.Builder.currentAssembly.bodyContainer.gameObject
  -- hit.gameObject:GetComponentInParent("HBBuilder.BodyContainer").gameObject

  --apply parent
  HBBuilder.Builder.SetParent(partContainer.gameObject, parent)

  --set layer to welded
  HBBuilder.BuilderUtils.SetLayer(partContainer.gameObject, 19, true)

  WorldEditor.Play("apply")
  --Audio:Play("click_melodic_2")

  --reigster for symetry
  if Symmetry and Symmetry.RegisterPart then
    Symmetry:RegisterPart(partContainer)
  end --if Symmetry then Symmetry:SymmetryPart(partContainer.gameObject) end
  --update symetry
  --sym both ( we might pickedup a sym slave part , so getting the other partContainer should sym both again making original win)
  --local otherPartContainer = false if Symmetry and Symmetry.FindOtherPartContainer then otherPartContainer = Symmetry:FindOtherPartContainer(partContainer) end
  if Symmetry and Symmetry.MirrorParts then
    Symmetry:MirrorParts(partContainer)
  end

  --show message of wich parent we placed it on

  local container = partContainer.gameObject:GetComponentInParent("HBBuilder.BodyContainer")
  if Slua.IsNull(container.transform.parent:GetComponentInParent("HBBuilder.BodyContainer")) then
  else
    local text = "Placed part onto "
    if not Slua.IsNull(container:GetComponentInParent("HBRotator")) then
      text = text .. "Rotator"
    end
    if not Slua.IsNull(container:GetComponentInParent("HBHemiRotator")) then
      text = text .. "Hemi Rotator"
    end
    if not Slua.IsNull(container:GetComponentInParent("HBHinge")) then
      text = text .. "Hinge"
    end
    if not Slua.IsNull(container:GetComponentInParent("HBDetacher")) then
      text = text .. "Detacher"
    end
    self:ShowMessage(text)
  end

  --clone part when holding shift
  if self:ShiftKey() then
    --clone current part
    local clone = HBBuilder.Builder.ClonePartContainer(partContainer)

    --apply parent
    clone.transform.parent = HBBuilder.Builder.weldContainer.transform

    --set layer back to unwelded
    HBBuilder.BuilderUtils.SetLayer(clone.gameObject, 20, true)

    --retrigger spawn part
    self:OnSpawnedPart(clone.gameObject)
  end

  --notify builder we changed current assembly
  HBBuilder.Builder.ChangedCurrentAssembly()
end

function AddTool:PickupPart(hit)
  --if hit does not have gameObject return
  if not hit.gameObject or Slua.IsNull(hit.gameObject) then
    return
  end

  --fetch partContainer
  local partContainer = hit.gameObject:GetComponent("PartContainer")

  --stop if no aprt container on the gameObject we hit
  if not partContainer or Slua.IsNull(partContainer) then
    return
  end

  --stop if pattcontainer has parent lock
  if partContainer.parentLocked then
    return
  end

  local clone = partContainer

  --clone part when holding shift
  if self:ShiftKey() then
    --clone current part
    clone = HBBuilder.Builder.ClonePartContainer(partContainer)
  end

  --apply parent
  clone.transform.parent = HBBuilder.Builder.weldContainer.transform

  --set layer back to unwelded
  HBBuilder.BuilderUtils.SetLayer(clone.gameObject, 20, true)

  --retrigger spawn part
  self:OnSpawnedPart(clone.gameObject)
end

function AddTool:ShowPlaceIcon()
  if not self then
    return
  end
  if not self.placeIcon or Slua.IsNull(self.placeIcon) then
    if Slua.IsNull(HBBuilder.Builder.GetLastSpawnedIcon()) then
      return
    end
    self.placeIcon =
      BUI.Image(
      HBBuilder.Builder.builderUI,
      "name",
      "AddToolPlaceIcon",
      "pivot",
      Vector2(1, 1),
      "image",
      Resources.Load("100pxCircle", "UnityEngine.Sprite"),
      "mask",
      true,
      "size",
      Vector2(64, 64),
      "color",
      Color(0, 0, 0, 0.5)
    )
    BUI.RawImage(
      self.placeIcon,
      "rawimage",
      HBBuilder.Builder.GetLastSpawnedIcon(),
      "anchormin",
      Vector2(0, 0),
      "anchormax",
      Vector2(1, 1),
      "offsetmin",
      Vector2.zero,
      "offsetmax",
      Vector2.zero
    )
    BUI.Apply(self.placeIcon, "raycastrecursive", false)
  end
  if not self.placeIcon or Slua.IsNull(self.placeIcon) then
    return
  end
  BUI.Apply(self.placeIcon, "position", Input.mousePosition - (Vector3(Screen.width, Screen.height, 0) * 0.5))
end

function AddTool:DestroyPlaceIcon()
  if not self then
    return
  end
  if not self.placeIcon or Slua.IsNull(self.placeIcon) then
    return
  end
  GameObject.Destroy(self.placeIcon)
end

function AddTool:ShowMessage(text)
  if not self then
    return
  end
  if not text or not type(text) == "string" or text == "" then
    return
  end
  GameObject.Destroy(
    BUI.Text(
      HBBuilder.Builder.builderUI,
      "text",
      text,
      "fontsize",
      25,
      "outline",
      true,
      "fadeout",
      1,
      "fadedelay",
      1,
      "textalign",
      TextAnchor.MiddleCenter,
      "rect",
      Rect(0, Screen.height * 0.7, Screen.width, 50)
    ),
    2
  )
end

function AddTool:Snap(v, s)
  v.x = Mathf.Round(v.x / s) * s
  v.y = Mathf.Round(v.y / s) * s
  v.z = Mathf.Round(v.z / s) * s
  return v
end

function AddTool:ShiftKey()
  return (Input.GetKey(KeyCode.LeftShift) or Input.GetKey(KeyCode.RightShift))
end

function AddTool:AltKey()
  return (Input.GetKey(KeyCode.LeftAlt) or Input.GetKey(KeyCode.RightAlt))
end

function AddTool:ControlKey()
  return (Input.GetKey(KeyCode.LeftControl) or Input.GetKey(KeyCode.RightControl))
end

function AddTool:DeleteKey()
  return Input.GetKeyDown(KeyCode.Delete)
end

function AddTool:Mouse()
  return Input.GetMouseButton(0)
end

function AddTool:MouseDown()
  return Input.GetMouseButtonDown(0)
end

function AddTool:MouseUp()
  return Input.GetMouseButtonUp(0)
end

function AddTool:RightMouseDown()
  return Input.GetMouseButtonDown(1)
end

function AddTool:RightMouseUp()
  return Input.GetMouseButtonUp(1)
end

function AddTool:RightMouse()
  return Input.GetMouseButton(1)
end

function AddTool:MiddleMouseDown()
  return Input.GetMouseButtonDown(2)
end

function AddTool:MousePosition()
  return Input.mousePosition
end

function AddTool:Scroll()
  local scroll = Input.GetAxis("Mouse ScrollWheel")
  if scroll > 0 and Time.time > (self.preScrollTime or 0) + 0.05 then
    self.preScrollTime = Time.time
    return 1
  end
  if scroll < 0 and Time.time > (self.preScrollTime or 0) + 0.05 then
    self.preScrollTime = Time.time
    return -1
  end
  return 0
end

return AddTool

--local AddTool = {}
--
--AddTool.ToolButton = {
--    name = "Add Tool",
--    icon = "lua/icons/builder/addtool.png",
--    tooltip = "Add tool: Place parts onto your craft [1]",
--    bigTooltip = [[Add Tool: Place parts onto your craft
--[R] or [Scroll] to rotate
--hold [ctrl] to rotate around X-axis
--hold [alt] to rotate around Z-axis
--[ctrl] click welded part to pick it up]],
--    hoversound = "click_blip",
--    clicksound = "affirm_blip_1",
--    imageLayout = {"dualcolor", true},
--    layout = {
--        "shortcut",
--        {
--            key1 = KeyCode.Alpha1,
--            useShift = false,
--            func = function()
--                WorldEditor.SelectTool(AddTool)
--            end
--        }
--    },
--    shortcut = nil
--}
--
--function AddTool:OnDisableTool()
--    if WorldEditor and WorldEditor.browserBar then
--        WorldEditor.browserBar:SetActive(false)
--    end
--end
--
--function AddTool:Start()
--    --register the tool with WorldEditor
--    if WorldEditor and WorldEditor.RegisterTool then
--        WorldEditor.RegisterTool(self, self.ToolButtonConfig)
--    end
--    --hide WorldEditor browser/parts bar
--    if WorldEditor and WorldEditor.browserBar then
--        WorldEditor.browserBar:SetActive(false)
--    end
--    if WorldEditor and WorldEditor.partsBar then
--        WorldEditor.partsBar:SetActive(false)
--    end
--    --hookup callback on spawn part
--    HBBuilder.Builder.RegisterCallback(
--        HBBuilder.BuilderCallback.SpawnPart,
--        "AddToolOnSpawnPart",
--        function()
--            self:OnSpawnedPart(HBBuilder.Builder.GetLastSpawnedPart())
--        end
--    )
--end
--
--function AddTool:OnDestroy()
--    --unregister the tool
--    if WorldEditor and WorldEditor.UnRegisterTool then
--        WorldEditor.UnRegisterTool(self, self.ToolButtonConfig)
--    end
--    --unhide WorldEditor browser/parts bar
--    if WorldEditor and WorldEditor.browserBar then
--        WorldEditor.browserBar:SetActive(false)
--    end
--end
--
--function AddTool:OnEnableTool()
--    --unhide WorldEditor browser/parts bar ( make sothat browser bar is only active when we have this tool selected )
--    if WorldEditor and WorldEditor.browserBar then
--        WorldEditor.browserBar:SetActive(true)
--        HBBuilder.Builder.TriggerCallback(HBBuilder.BuilderCallback.RefreshUIIndicators)
--    end
--end
--
--function AddTool:OnDisableTool()
--    --hide WorldEditor browser/parts bar ( make sothat browser bar is only active when we have this tool selected )
--    if WorldEditor and WorldEditor.browserBar then
--        WorldEditor.browserBar:SetActive(false)
--    end
--    if WorldEditor and WorldEditor.partsBar then
--        WorldEditor.partsBar:SetActive(false)
--    end
--    if SelectTool then
--        SelectTool.selectionEnabled = true
--    end
--end
--
--function AddTool:OnSpawnedPart(part)
--    if not self then
--        return
--    end
--    if not self.enabled then
--        return
--    end
--    if not part or Slua.IsNull(part) then
--        return
--    end
--    print(part)
--    HBBuilder.BuilderUtils.SetLayer(part, 0, true)
--    part.transform.parent = HBBuilder.Builder.currentAssembly.bodyContainer.transform
--    WorldEditor.Play("new")
--    WorldEditor.hasChanged=true
--end
--
--function AddTool:Update()
--    --stop of tool is not selected
--    if not self or not self.enabled then
--        return
--    end
--
--    if SelectTool then
--        SelectTool.selectionEnabled = true
--    end
--end
--
--function AddTool:ShowMessage(text)
--    if not self then
--        return
--    end
--    if not text or not type(text) == "string" or text == "" then
--        return
--    end
--    GameObject.Destroy(
--        BUI.Text(
--            HBBuilder.Builder.builderUI,
--            "text",
--            text,
--            "fontsize",
--            25,
--            "outline",
--            true,
--            "fadeout",
--            1,
--            "fadedelay",
--            1,
--            "textalign",
--            TextAnchor.MiddleCenter,
--            "rect",
--            Rect(0, Screen.height * 0.7, Screen.width, 50)
--        ),
--        2
--    )
--end
--
--function AddTool:ShiftKey()
--    return (Input.GetKey(KeyCode.LeftShift) or Input.GetKey(KeyCode.RightShift))
--end
--
--function AddTool:AltKey()
--    return (Input.GetKey(KeyCode.LeftAlt) or Input.GetKey(KeyCode.RightAlt))
--end
--
--function AddTool:ControlKey()
--    return (Input.GetKey(KeyCode.LeftControl) or Input.GetKey(KeyCode.RightControl))
--end
--
--function AddTool:DeleteKey()
--    return Input.GetKeyDown(KeyCode.Delete)
--end
--
--function AddTool:Mouse()
--    return Input.GetMouseButton(0)
--end
--
--function AddTool:MouseDown()
--    return Input.GetMouseButtonDown(0)
--end
--
--function AddTool:MouseUp()
--    return Input.GetMouseButtonUp(0)
--end
--
--function AddTool:RightMouseDown()
--    return Input.GetMouseButtonDown(1)
--end
--
--function AddTool:RightMouseUp()
--    return Input.GetMouseButtonUp(1)
--end
--
--function AddTool:RightMouse()
--    return Input.GetMouseButton(1)
--end
--
--function AddTool:MiddleMouseDown()
--    return Input.GetMouseButtonDown(2)
--end
--
--function AddTool:MousePosition()
--    return Input.mousePosition
--end
--
--function AddTool:Scroll()
--    local scroll = Input.GetAxis("Mouse ScrollWheel")
--    if scroll > 0 and Time.time > (self.preScrollTime or 0) + 0.05 then
--        self.preScrollTime = Time.time
--        return 1
--    end
--    if scroll < 0 and Time.time > (self.preScrollTime or 0) + 0.05 then
--        self.preScrollTime = Time.time
--        return -1
--    end
--    return 0
--end
--
--return AddTool
