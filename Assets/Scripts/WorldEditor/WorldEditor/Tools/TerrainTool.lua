TerrainTool = {}

-----------------------------------------------
--Tool Settings And UI Declaration
-----------------------------------------------
TerrainTool.ToolButton = {
  name = "Terrain Tool",
  icon = "lua/icons/worldeditor/Terrain.png",
  tooltip = "Terrain importer and editor [8]",
  bigTooltip = [[This tool is for the import and changing of terrains.]],
  hoversound = "click_blip",
  clicksound = "affirm_blip_1",
  imageLayout = {"dualcolor", true},
  layout = {
    "shortcut",
    {
      key1 = KeyCode.Alpha8,
      useShift = false,
      func = function()
        WorldEditor.SelectTool(TerrainTool)
      end
    }
  },
  shortcut = nil
  --groupID = "Terrain"
}

TerrainTool.Inspector = {
  {
    name = "Terrain Tool",
    tooltip = "Tool for making and editing terrain",
    uiType = "headerProperty"
  },
  {
    name = "Terrain Size",
    tooltip = "The square size of the terrain (default 4000 X 4000)",
    uiType = "floatProperty",
    value = function()
      return TerrainTool.Settings.terrainSize
    end,
    func = function(v)
      TerrainTool.Settings.terrainSize = v
      TerrainTool.EditSize(v)
    end
  },
  {
    name = "Terrain Height",
    tooltip = "The MAX height of the terrain (default 800m)",
    uiType = "floatProperty",
    value = function()
      return TerrainTool.Settings.terrainHeight
    end,
    func = function(v)
      TerrainTool.Settings.terrainHeight = v
      TerrainTool.EditHeight(v)
    end
  },
  {
    name = "Height Map Resolution",
    tooltip = "Needs to be the same resolution as the imported heightmap \n\r NOTE changing it will reset the terrain height (default 513)",
    uiType = "intProperty",
    value = function()
      return TerrainTool.Settings.heightmapResolution
    end,
    func = function(v)
      if v ~= TerrainTool.Settings.heightmapResolution then
        TerrainTool.Settings.heightmapResolution = v
        TerrainTool.EditResolution(v)
      end
    end
  },
  {
    name = "Make Terrain",
    tooltip = "Makes a terrain Object with the values above",
    uiType = "buttonProperty",
    value = "Apply",
    func = function(v)
      print("Make Terrain")
      TerrainTool.MakeTerrain()
    end
  },
  {
    name = "",
    tooltip = "",
    uiType = "headerProperty"
  },
  {
    name = "Apply RAW",
    tooltip = "Apply the RAW map to the terrain",
    uiType = "buttonProperty",
    value = "Apply",
    func = function(v)
      print("Apply RAW")
      TerrainTool.ApplyRAW()
    end
  },
  {
    name = "Apply Colour",
    tooltip = "Apply the Colour map to the terrain",
    uiType = "buttonProperty",
    value = "Apply",
    func = function(v)
      print("Apply Colour")
      TerrainTool.ApplyColour()
    end
  },
  {
    name = "Apply Splatmap",
    tooltip = "Apply the Splatmap map to the terrain",
    uiType = "buttonProperty",
    value = "Apply",
    func = function(v)
      print("Apply Splatmap")
      TerrainTool.ApplySplatmap()
    end
  },
  {
    name = "Apply Normalmap",
    tooltip = "Apply the Normalmap to the terrain",
    uiType = "buttonProperty",
    value = "Apply",
    func = function(v)
      print("Apply Normalmap")
      TerrainTool.ApplyNormal()
    end
  } --[[ ,
  {
    name = "Apply LOD Mesh",
    tooltip = "Apply the LOD mesh to the terrain",
    uiType = "buttonProperty",
    value = "Apply",
    func = function(v)
      print("Apply Normalmap")
      TerrainTool.ApplyLOD()
    end
  } ]]
}

TerrainTool.Settings = {
  name = "Terrain01",
  terrainSize = 4000,
  terrainHeight = 800,
  heightmapResolution = 513
}

function TerrainTool:OnEnableTool()
  if SelectTool then
    SelectTool.rectSelectionEnabled = true
    SelectTool.updateInspectorEnabled = false
  end
end

function TerrainTool:OnDisableTool()
  if SelectTool then
    SelectTool.rectSelectionEnabled = true
    SelectTool.updateInspectorEnabled = true
  end
end

function TerrainTool:Awake()
end

function TerrainTool:Start()
  --register the tool with WorldEditor
  if WorldEditor and WorldEditor.RegisterTool then
    WorldEditor.RegisterTool(self)
  end
end

function TerrainTool:Update()
end

function TerrainTool:OnDestroy()
  --unregister the tool
  if WorldEditor and WorldEditor.UnRegisterTool then
    WorldEditor.UnRegisterTool(self)
  end
end

function TerrainTool.MakeTerrain()
  print("TerrainTool . MakeTerrain()")
  HBBuilder.Builder.Select(nil, "")
  ter = Terrains.Find("flat").Clone()
  ter.terrainData.size =
    Vector3(TerrainTool.Settings.terrainSize, TerrainTool.Settings.terrainHeight, TerrainTool.Settings.terrainSize)
  ter.terrainData.heightmapResolution = TerrainTool.Settings.heightmapResolution

  local terComp = ter.gameObject:GetComponent("Terrain")
  local baseColour = Application.persistentDataPath .. "/Lua/ModLua/WorldEditor/Base/BaseColour.png"
  local baseSplat = Application.persistentDataPath .. "/Lua/ModLua/WorldEditor/Base/BaseSplatMap.png"
  local baseNormal = Application.persistentDataPath .. "/Lua/ModLua/WorldEditor/Base/BaseNormalMap.png"

  TerrainUtils.ColorToTerrain(baseColour, terComp)
  TerrainUtils.SplatToTerrain(baseSplat, terComp)
  TerrainUtils.NormalMapToTerrain(baseNormal, terComp)

  ter.gameObject.name = "WE_TERRAIN_" .. ter.gameObject:GetInstanceID()
  ter.gameObject.transform.parent = WorldEditor.TerrainParent.transform
  ter.gameObject.transform.localPosition = Vector3(0, 0, 0)
  --HBBuilder.Builder.Select(ter.gameObject, "")
end

function TerrainTool.EditSize(size)
  local terrains = WorldEditor.GetAllTerrain()
  for k, ter in pairs(terrains) do
    ter.terrainData.size =
      Vector3(TerrainTool.Settings.terrainSize, ter.terrainData.size.y, TerrainTool.Settings.terrainSize)
  end
end

function TerrainTool.EditHeight(height)
  local terrains = WorldEditor.GetAllTerrain()
  for k, ter in pairs(terrains) do
    ter.terrainData.size = Vector3(ter.terrainData.size.x, height, ter.terrainData.size.z)
  end
end

function TerrainTool.EditResolution(res)
  local terrains = WorldEditor.GetAllTerrain()
  for k, ter in pairs(terrains) do
    ter.terrainData.heightmapResolution = res
  end
end

function TerrainTool.EditName(name)
  local terrains = WorldEditor.GetAllTerrain()
  for k, ter in pairs(terrains) do
    ter.gameObject.name = name
  end
end

function TerrainTool.ApplyRAW()
  local file = HBU.OpenFile(HBU.GetLuaFolder(), "", "Open RAW")
  if file == "" then
    print("No File Selected")
    return
  end
  local terrains = WorldEditor.GetAllTerrain()
  for k, v in pairs(terrains) do
    --TerrainUtils.Raw32ToTerrain(file, v)
    echo(Terrains.Raw16ToTerrain(file, v))
  end
end

function TerrainTool.ApplyColour()
  local file = HBU.OpenFile(HBU.GetLuaFolder(), "", "Open ColourMap")
  if file == "" then
    print("No File Selected")
    return
  end
  local terrains = WorldEditor.GetAllTerrain()
  for k, v in pairs(terrains) do
    TerrainUtils.ColorToTerrain(file, v)
  end
end

function TerrainTool.ApplySplatmap()
  local file = HBU.OpenFile(HBU.GetLuaFolder(), "", "Open SplatMap")
  if file == "" then
    print("No File Selected")
    return
  end
  local terrains = WorldEditor.GetAllTerrain()
  for k, v in pairs(terrains) do
    TerrainUtils.SplatToTerrain(file, v)
  end
end

function TerrainTool.ApplyNormal()
  local file = HBU.OpenFile(HBU.GetLuaFolder(), "", "Open NormalMap")
  if file == "" then
    print("No File Selected")
    return
  end
  local terrains = WorldEditor.GetAllTerrain()
  for k, v in pairs(terrains) do
    TerrainUtils.NormalMapToTerrain(file, v)
  end
end

function TerrainTool.ApplyLOD()
  local file = HBU.OpenFile(HBU.GetLuaFolder(), "obj", "Open Mesh")
  if file == "" then
    print("No File Selected")
    return
  end
  local terrains = WorldEditor.GetAllTerrain()
  for k, v in pairs(terrains) do
    TerrainUtils.LODMeshToTerrain(file, v)
  end
end

return TerrainTool
