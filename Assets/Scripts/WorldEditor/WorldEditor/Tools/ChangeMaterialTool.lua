ChangeMaterialTool = {}

-----------------------------------------------
--Tool Settings And UI Declaration
-----------------------------------------------

ChangeMaterialTool.ToolButton = {
  name = "Material Changer",
  icon = "lua/icons/worldeditor/ToolTemplate.png",
  tooltip = "Used to change the material of an object [7]",
  bigTooltip = [[Big Tool Discription]],
  hoversound = "click_blip",
  clicksound = "affirm_blip_1",
  imageLayout = {"dualcolor", true},
  layout = {
    "shortcut",
    {
      key1 = KeyCode.Alpha7,
      useShift = false,
      func = function()
        WorldEditor.SelectTool(ChangeMaterialTool)
      end
    }
  },
  shortcut = nil
  --groupID = "Tut"
}

ChangeMaterialTool.Inspector = {
  {
    name = "Material Changer",
    tooltip = "Used to change the material of an object",
    uiType = "headerProperty"
  } --[[ ,
  {
    name = "Material name",
    tooltip = "The name of the material",
    uiType = "stringProperty",
    value = function()
      return ChangeMaterialTool.Settings.name
    end,
    func = function(v)
      print(v)
      ChangeMaterialTool.Settings.name = v
    end
  } ]]
}

ChangeMaterialTool.Settings = {
  name = "colorScheme",
  allMaterials = {}
}

ChangeMaterialTool.enabled = false

function ChangeMaterialTool:OnEnableTool()
  self.appliedCustomInspector = false
end

function ChangeMaterialTool:OnDisableTool()
  if SelectTool then
    SelectTool.selectionEnabled = true
  end
end

function ChangeMaterialTool:OnInspectorReady()
  if not self then
    return false
  end
  if not Inspector or not Inspector.wizzard then
    return false
  end

  local altColor = Color.Lerp(BUI.colors.normal, BUI.colors.dark, 0.5)
  for k, v in pairs(ChangeMaterialTool.Settings.allMaterials) do
    local materialPanel = self:CreateUIElement(v)

    if materialPanel then
      if k % 2 == 1 then
        BUI.Apply(materialPanel, "color", altColor)
      end

      Inspector.wizzard:AddCustomProperty(
        materialPanel,
        function()
        end
      )
    end
  end

  return true
end

function ChangeMaterialTool:Awake()
end

function ChangeMaterialTool:Start()
  --register the tool with WorldEditor
  if WorldEditor and WorldEditor.RegisterTool then
    WorldEditor.RegisterTool(self)
  end
  ChangeMaterialTool.Settings.allMaterials = ChangeMaterialTool.GetValideMaterials()
end

function ChangeMaterialTool:Update()
  if not self then
    return
  end

  if not self.enabled then
    return
  end

  if SelectTool then
    SelectTool.selectionEnabled = false
  end

  if not self.appliedCustomInspector then
    self.appliedCustomInspector = self:OnInspectorReady()
  end

  local ray = HBBuilder.BuilderUtils.MouseRay()
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

  if ok and hit.overCollider then
    local renderer = hit.collider.gameObject:GetComponent("MeshRenderer")
    if not renderer and Slua.IsNull(renderer) then
      return
    end
    if self:MouseDown() and not HBU.OverGUI() and not HBU.OverUI() and not HBU.Typing() then
      if not self:ControlKey() then
        renderer.materials = {
          GetTableValue(ChangeMaterialTool.Settings.allMaterials, ChangeMaterialTool.Settings.name)
        }
      else
        renderer.materials = {Resources.Load("1HomebrewMaterials/colorScheme")}
      end
    end
  end
end

function ChangeMaterialTool:OnDestroy()
  --unregister the tool
  if WorldEditor and WorldEditor.UnRegisterTool then
    WorldEditor.UnRegisterTool(self)
  end
end

function ChangeMaterialTool.GetValideMaterials()
  ret = {}
  local allMaterials = iter(Resources.LoadAll("", "UnityEngine.Material"))

  for i, v in ipairs(allMaterials) do
    if not TableHasValue(ret, v) and v.name ~= "" and (string.find(v.name, "G_")or string.find(v.name, "colorScheme")) then
      table.insert(ret, v)
    end
  end

  return ret
end

function ChangeMaterialTool:CreateUIElement(material)
  if not material.name then
    return nil
  end
  local panel =
    BUI.Panel(
    Inspector.wizzard.contentParent,
    "name",
    "MaterialProperty",
    "min",
    Vector2(0, 25),
    "tooltip",
    material.name,
    "onmouseup",
    function()
      self.Settings.name = material.name
    end
  )

  BUI.Text(
    panel,
    "text",
    material.name,
    "offsetmin",
    Vector2(10, 0),
    "textalign",
    TextAnchor.MiddleLeft,
    "fontsize",
    12
  )
  return panel
end

function ChangeMaterialTool:ControlKey()
  return (Input.GetKey(KeyCode.LeftControl) or Input.GetKey(KeyCode.RightControl))
end

function ChangeMaterialTool:MouseDown()
  return Input.GetMouseButtonDown(0)
end

function ChangeMaterialTool:RightMouse()
  return Input.GetMouseButton(1)
end

function TableHasValue( table,material )
  for k,v in pairs(table) do
    if v.name == material.name then
      return true
    end
  end
  return false 
end

return ChangeMaterialTool
