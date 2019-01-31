local PaintTool = {}

------------------------------------------------
--config
------------------------------------------------

PaintTool.ToolButton = {
  name = "Paint Tool",
  icon = "lua/icons/builder/painttool.png",
  tooltip = "Paint tool: paint your craft [6]",
  bigTooltip = [[Paint tool: paint your craft
click your craft to paint it with the selected color 
[shift] click to pick a color from your craft]],
  hoversound = "click_blip",
  clicksound = "affirm_blip_1",
  imageLayout = {"dualcolor", true},
  layout = {
    "shortcut",
    {
      key1 = KeyCode.Alpha6,
      useShift = false,
      func = function()
        WorldEditor.SelectTool(PaintTool)
      end
    }
  },
  shortcut = nil
}

PaintTool.Inspector = {
  {
    name = "Paint Tool",
    tooltip = "Paint tool: paint your creation [shift] to pick color  [ctrl] to reset color",
    uiType = "headerProperty"
  }
}

PaintTool.Settings = {
  materialType = 0,
  hue = 0,
  saturation = 1,
  lightness = 1,
  smoothness = 0.5
}

PaintTool.ColorPresets = {
  {
    name = "Homebrew Orange",
    materialType = 0,
    hue = 0.08,
    saturation = 1,
    lightness = 1,
    smoothness = 0.2
  },
  {
    name = "Homebrew metal",
    materialType = 1,
    hue = 0.08,
    saturation = 0,
    lightness = 0.45,
    smoothness = 0.4
  },
  {
    name = "Homebrew dark metal",
    materialType = 1,
    hue = 0.08,
    saturation = 0,
    lightness = 0.2,
    smoothness = 0.1
  },
  {
    name = "Cherry",
    materialType = 0,
    hue = 0.95,
    saturation = 1,
    lightness = 0.8,
    smoothness = 0.3
  },
  {
    name = "Lime",
    materialType = 0,
    hue = 0.3,
    saturation = 1,
    lightness = 1,
    smoothness = 0.3
  },
  {
    name = "Matte black",
    materialType = 0,
    hue = 0,
    saturation = 0,
    lightness = 0.2,
    smoothness = 0.1
  },
  {
    name = "Luminess cyan",
    materialType = 4,
    hue = 0.5,
    saturation = 1,
    lightness = 1,
    smoothness = 0.3
  },
  {
    name = "Gold",
    materialType = 2,
    hue = 0.2,
    saturation = 1,
    lightness = 1,
    smoothness = 0.5
  },
  {
    name = "Platinum",
    materialType = 2,
    hue = 0.2,
    saturation = 0,
    lightness = 1,
    smoothness = 0.3
  },
  {
    name = "Chrome",
    materialType = 2,
    hue = 0.2,
    saturation = 0,
    lightness = 1,
    smoothness = 0.7
  },
  {
    name = "Dark wood",
    materialType = 5,
    hue = 0.1,
    saturation = 1,
    lightness = 0.2,
    smoothness = 0.5
  },
  {
    name = "Regular Wood",
    materialType = 5,
    hue = 0.2,
    saturation = 1,
    lightness = 0.6,
    smoothness = 0.5
  }
}

------------------------------------------------
--main logic
------------------------------------------------

PaintTool.enabled = false

function PaintTool:Start()
  --register the tool with builder
  if WorldEditor and WorldEditor.RegisterTool then
    WorldEditor.RegisterTool(self, self.ToolButtonConfig)
  end
end

function PaintTool:OnDestroy()
  --unregister the tool
  if WorldEditor and WorldEditor.UnRegisterTool then
    WorldEditor.UnRegisterTool(self, self.ToolButtonConfig)
  end

  --remove cloned mesh
  if self.preExtractedMesh and not Slua.IsNull(self.preExtractedMesh) then
    GameObject.Destroy(self.preExtractedMesh)
  end

  --close colorpicker
  if self.colorPicker then
    self.colorPicker:Destroy()
  end

  --remove indicator
  self:ResetIndicator()
end

function PaintTool:OnEnableTool()
  --when we enable tool set , applied inspector color false
  self.appliedInspectorColorPicker = false
end

function PaintTool:OnDisableTool()
  if SelectTool then
    SelectTool.selectionEnabled = true
  end
  --reset indicator vars
  self:ResetIndicator()
end

function PaintTool:OnInspectorReady()
  if not self then
    return false
  end
  if not Inspector or not Inspector.wizzard then
    return false
  end

  --create color picker in inspector
  self.colorPicker =
    BUI.ColorPicker:Create(
    {
      verticalPanel = true, -- we want vertical panel in inspector
      draggable = false, --non draggalbe
      layout = {"min", Vector2(0, 300)}, --set minimum , bc inpsector has a vertical layout that will compress our panel
      useCloseButton = false, --dont use close button
      hue = self.Settings.hue,
      saturation = self.Settings.saturation,
      lightness = self.Settings.lightness,
      smoothness = self.Settings.smoothness,
      materialType = self.Settings.materialType,
      func = function(data)
        self:OnColorChanged(data)
      end
    },
    Inspector.wizzard.contentParent
  )

  --pass color picker root to inspector, and setup destroy func ( Custom properties have a destroy callback , wich is sometimes needed like in this case )
  Inspector.wizzard:AddCustomProperty(
    self.colorPicker.root,
    function()
      self.colorPicker:Destroy()
    end
  )

  --add color presets
  local altColor = Color.Lerp(BUI.colors.normal, BUI.colors.dark, 0.5)
  for i, colorPreset in ipairs(self.ColorPresets) do
    --createc color preset ui
    local ui, img = self:CreateColorPresetProperty(colorPreset, Inspector.wizzard.contentParent)
    --make the color flip flop
    if i % 2 == 1 then
      BUI.Apply(ui, "color", altColor)
    end
    --pass color preset ui to inspector, and setup destroy func , remove the img with it , bc it generates a new imagees per color preset property
    Inspector.wizzard:AddCustomProperty(
      ui,
      function()
        if img and not Slua.IsNull(img) then
          GameObject.Destroy(img)
        end
      end
    )
  end

  return true
end

function PaintTool:Update()
  --stop if tool is not enabled
  if not self or not self.enabled then
    return
  end

  --no selection while doing this stuff
  if SelectTool then
    SelectTool.selectionEnabled = false
  end

  --apply inspector properties as soon as we can
  if not self.appliedInspectorColorPicker then
    self.appliedInspectorColorPicker = self:OnInspectorReady()
  end

  --stop while right clicking
  if self:RightMouse() then
    --reset indicator vars
    self:ResetIndicator()

    return
  end

  ------------------------------------------------
  --raycast
  ------------------------------------------------

  --fetch mouse ray
  local ray = HBBuilder.BuilderUtils.MouseRay()

  --GameObject root, Ray ray, int physicsRaycastLayer, out BuilderRaycastHit hit, bool ignoreColliders = false, bool ignoreFrames = false, bool ignoreHulls = false, bool ignoreBounds = true, bool ignoreInactive = true, bool ignoreVerts = false, bool ignoreLines = false, bool ignoreQuads = false, bool ignoreTris = false, float lineRadius = 0.03f, float vertRadius = 0.03f, bool snapBounds = true, float snapBoundsScale = 0.1f
  --raycast colliders and frames only
  local ok, hit =
    HBBuilder.BuilderUtils.BuilderRaycast(
    HBBuilder.Builder.root.gameObject,
    ray,
    -1 << 19,
    Slua.out,
    false,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    0.03,
    0.03,
    true,
    0.1
  )

  ------------------------------------------------
  --check hit
  ------------------------------------------------
  --if we hit a mesh collider ( check vert 1,2,3 to know its meshcollider )
  if ok and hit.overCollider and hit.vertIndex1 and hit.vertIndex2 and hit.vertIndex3 then
    ------------------------------------------------
    --get uv island
    ------------------------------------------------

    --detect change
    if
      not self.preHoverCollider or self.preHoverCollider ~= hit.collider or not self.preHoverVertIndex1 or
        self.preHoverVertIndex1 ~= hit.vertIndex1 or
        not self.preHoverVertIndex2 or
        self.preHoverVertIndex2 ~= hit.vertIndex2 or
        not self.preHoverVertIndex3 or
        self.preHoverVertIndex3 ~= hit.vertIndex3
     then
      self.preHoverCollider = hit.collider
      self.preHoverVertIndex1 = hit.vertIndex1
      self.preHoverVertIndex2 = hit.vertIndex2
      self.preHoverVertIndex3 = hit.vertIndex3

      --get mesh from collider
      local meshFromCollider = self:GetMeshFromCollider(hit.collider)

      --check if mesh is acc valid
      if not meshFromCollider or Slua.IsNull(meshFromCollider) then
        print("no mesh found :" .. tostring(hit.collider))
        return
      end

      ----detect when mesh that we hit changed
      --if not self.mesh or self.mesh ~= meshFromCollider then
      --  self.mesh = meshFromCollider
      --end

      self.mesh = meshFromCollider

      --fetch color UV island
      local uvIsland =
        HBBuilder.BuilderUtils.GetMeshIslandUV(self.mesh, {hit.vertIndex1, hit.vertIndex2, hit.vertIndex3}, 0)

      --detect when uv island we hit has changed
      if not self.island or self.island ~= uvIsland then
        self.island = uvIsland
        --make indicator mesh of this island
        self.indicatorObj = self:CreateIndicatorObject(self.mesh, uvIsland)
      end
    end

    local island = self.island
    local mesh = self.mesh

    ------------------------------------------------

    ------------------------------------------------
    --update indicator
    ------------------------------------------------

    --no indicators when we gold down ctrl, or if no indicator exists
    if not self:ControlKey() and self.indicatorObj and not Slua.IsNull(self.indicatorObj) then
      --position the indicator ( we dont parent it inside the vheicle to make sure it is not saved on accident )
      self.indicatorObj.transform.position = hit.collider.transform.position
      self.indicatorObj.transform.rotation = hit.collider.transform.rotation
      self.indicatorObj.transform.localScale = hit.collider.transform.lossyScale
    end

    ------------------------------------------------

    --check mouse and see that we arnt over ui or typing
    if self:MouseDown() and not HBU.OverGUI() and not HBU.OverUI() and not HBU.Typing() then
      if self:ShiftKey() then
        --Audio:Play("click-analogue-1",true,true);
        ------------------------------------------------
        --pick color
        ------------------------------------------------

        --get color+smoothness from uv
        local colorSchemeColor = HBBuilder.ColorSchemeArchive.Find(mesh.uv[hit.vertIndex1 + 1])
        local color = colorSchemeColor.color
        local smoothness = colorSchemeColor.smoothness
        local materialType = colorSchemeColor.materialTypeIndex

        --apply color+smoothness to settings
        self.Settings.hue, self.Settings.saturation, self.Settings.lightness =
          Color.RGBToHSV(color, Slua.out, Slua.out, Slua.out)
        self.Settings.smoothness = smoothness
        self.Settings.materialType = materialType

        --refresh colorpicker
        if self.colorPicker then
          self.colorPicker:SetData(self.Settings)
        end

        WorldEditor.Play("altapply")
      else
        --Audio:Play("alert-flick-alert",true,true);
        ------------------------------------------------
        --paint
        ------------------------------------------------

        --setup colorSwatch
        local colorSwatch = HBBuilder.ColorSwatch(0)
        local color = Color.HSVToRGB(self.Settings.hue, self.Settings.saturation, self.Settings.lightness)
        local smoothness = self.Settings.smoothness
        local materialType = self.Settings.materialType

        colorSwatch:Add(1, materialType, color, smoothness, true)

        --apply color
        self:ApplyColor(hit.collider, island, colorSwatch)

        WorldEditor.Play("apply")
      end
    end
  else
    self.preHoverCollider = nil

    --remove indicator when we are not hovering over mesh
    self:ResetIndicator()
  end

  ------------------------------------------------
end

function PaintTool:CreateIndicatorObject(mesh, uvIsland)
  if not self then
    return
  end

  --remove prev indicator mesh
  if self.indicatorMesh then
    GameObject.Destroy(self.indicatorMesh)
  end

  --create new indicator mesh and cache it
  self.indicatorMesh = HBBuilder.BuilderUtils.CutNewMesh(mesh, uvIsland.tris)

  --remove prev indicator obj
  if self.indicatorObj then
    GameObject.Destroy(self.indicatorObj)
  end

  --create new indicator obj and parent in weld container
  self.indicatorObj = GameObject("indicator obj")
  self.indicatorObj.transform.parent = HBBuilder.Builder.root.transform

  --add meshfilter and assign indicator mesh
  local meshFilter = self.indicatorObj:AddComponent("UnityEngine.MeshFilter")
  meshFilter.sharedMesh = self.indicatorMesh

  --add meshrenderer
  local meshRenderer = self.indicatorObj:AddComponent("UnityEngine.MeshRenderer")
  meshRenderer.sharedMaterial = Resources.Load("ScreenGridHighlight", "UnityEngine.Material")

  --set layer
  HBBuilder.BuilderUtils.SetLayer(self.indicatorObj, 22, true)

  --return obj
  return self.indicatorObj
end

function PaintTool:ResetIndicator()
  if not self then
    return
  end
  if self.indicatorObj and not Slua.IsNull(self.indicatorObj) then
    GameObject.Destroy(self.indicatorObj)
  end
  if self.indicatorMesh and not Slua.IsNull(self.indicatorMesh) then
    GameObject.Destroy(self.indicatorMesh)
  end
  self.mesh = false
  self.island = false
end

function PaintTool:GetMeshFromCollider(collider)
  if not self then
    return
  end
  --must get mesh from MeshFilter or SkinnedMeshRenderer, and not the mesh found in MeshCollider
  --this bc, MeshCollider create a clone if the mesh comes from SkinnedMeshRenderer, aka we would be painting the wrong mesh
  --when making this clone it also removes the skin data found on skinned meshes, so we cant paint the mesh found in the collider and feed that back to SkinnedMeshRenderer either

  --sanity check
  if not collider or Slua.IsNull(collider) then
    return
  end

  if self.preExtractedMesh and not Slua.IsNull(self.preExtractedMesh) then
    GameObject.Destroy(self.preExtractedMesh)
  end

  --look for SkinnedMeshRenderer
  local skinnedMeshRenderer = collider:GetComponent("SkinnedMeshRenderer")
  if not Slua.IsNull(skinnedMeshRenderer) and not Slua.IsNull(skinnedMeshRenderer.sharedMesh) then
    returnMesh = HBBuilder.BuilderUtils.GetSkinnedMesh(skinnedMeshRenderer)
    self.preExtractedMesh = returnMesh
    return returnMesh
  end

  --look for MeshFilter
  local meshFilter = collider:GetComponent("MeshFilter")
  if not Slua.IsNull(meshFilter) and not Slua.IsNull(meshFilter.sharedMesh) then
    returnMesh = GameObject.Instantiate(meshFilter.sharedMesh)
    self.preExtractedMesh = returnMesh
    return meshFilter.sharedMesh
  end
end

function PaintTool:ApplyColor(collider, island, colorSwatch)
  if not self then
    return
  end
  if not collider then
    return
  end
  if not island then
    return
  end
  if not colorSwatch then
    return
  end

  if Slua.IsNull(collider) then
    return
  end
  if Slua.IsNull(island) then
    return
  end
  if Slua.IsNull(colorSwatch) then
    return
  end

  local skinnedMeshRenderer = collider:GetComponent("SkinnedMeshRenderer")
  if not Slua.IsNull(skinnedMeshRenderer) and not Slua.IsNull(skinnedMeshRenderer.sharedMesh) then
    skinnedMeshRenderer.sharedMesh =
      HBBuilder.BuilderUtils.ApplyColor(skinnedMeshRenderer.sharedMesh, island.tris, colorSwatch)
  end

  local meshFilter = collider:GetComponent("MeshFilter")
  if not Slua.IsNull(meshFilter) and not Slua.IsNull(meshFilter.sharedMesh) then
    meshFilter.sharedMesh = HBBuilder.BuilderUtils.ApplyColor(meshFilter.sharedMesh, island.tris, colorSwatch)
  end
end

function PaintTool:CreateColorPresetProperty(colorPreset, parent)
  if not self then
    return
  end
  local img =
    BUI.CreateColorSchemePreviewImageHSV(
    colorPreset.materialType,
    colorPreset.hue,
    colorPreset.saturation,
    colorPreset.lightness,
    colorPreset.smoothness
  )
  local panel =
    BUI.Panel(
    parent,
    "name",
    "ColorPresetProperty",
    "min",
    Vector2(0, 50),
    "tooltip",
    colorPreset.name,
    "onmouseup",
    function()
      self:OnColorChanged(colorPreset)
      if self.colorPicker then
        self.colorPicker:SetData(colorPreset)
      end
    end
  )
  BUI.Text(
    panel,
    "text",
    colorPreset.name,
    "offsetmin",
    Vector2(10, 0),
    "textalign",
    TextAnchor.MiddleLeft,
    "fontsize",
    12
  )
  BUI.RawImage(
    panel,
    "rawimage",
    img,
    "pivot",
    Vector2(1, 1),
    "anchormin",
    Vector2(1, 1),
    "anchormax",
    Vector2(1, 1),
    "position",
    Vector2(0, 0),
    "size",
    Vector2(50, 50)
  )
  return panel, img -- return image aswel , we need to destoy it along with this ui
end

function PaintTool:OnColorChanged(data)
  if not self then
    return
  end
  if not data then
    return
  end
  self.Settings.materialType = data.materialType
  self.Settings.hue = data.hue
  self.Settings.saturation = data.saturation
  self.Settings.lightness = data.lightness
  self.Settings.smoothness = data.smoothness
end

------------------------------------------------

------------------------------------------------
--utils
------------------------------------------------

function PaintTool:ShiftKey()
  return (Input.GetKey(KeyCode.LeftShift) or Input.GetKey(KeyCode.RightShift))
end

function PaintTool:AltKey()
  return (Input.GetKey(KeyCode.LeftAlt) or Input.GetKey(KeyCode.RightAlt))
end

function PaintTool:ControlKey()
  return (Input.GetKey(KeyCode.LeftControl) or Input.GetKey(KeyCode.RightControl))
end

function PaintTool:DeleteKey()
  return Input.GetKeyDown(KeyCode.Delete)
end

function PaintTool:Mouse()
  return Input.GetMouseButton(0)
end

function PaintTool:MouseDown()
  return Input.GetMouseButtonDown(0)
end

function PaintTool:MouseUp()
  return Input.GetMouseButtonUp(0)
end

function PaintTool:RightMouse()
  return Input.GetMouseButton(1)
end

function PaintTool:MouseUp()
  return Input.GetMouseButtonUp(0)
end

------------------------------------------------

return PaintTool
