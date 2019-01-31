Grid = {}

Grid.InspectorProperties = {
  {
    name = "Grid Settings",
    tooltip = "Grid Settings",
    uiType = "headerProperty",
    layout = {"color", Color(0, 0, 0, 0)}
  },
  --[[  {
    name = "Show Grid",
    tooltip = "Shows the grid",
    uiType = "boolProperty",
    value = function()
      return Grid.Settings.showGrid
    end,
    func = function(v)
      Grid.Settings.showGrid = v
      if BuilderGrid and BuilderGrid.SetEnabled then
        BuilderGrid:SetEnabled(v)
      end
    end,
    layout = {"color", Color(0, 0, 0, 0)}
  },
  {
    name = "Show Compass",
    tooltip = "Shows the compass",
    uiType = "boolProperty",
    value = function()
      return Grid.Settings.showCompass
    end,
    func = function(v)
      Grid.Settings.showCompass = v
    end,
    layout = {"color", Color(0, 0, 0, 0)}
  }, ]]
  {
    name = "Snap Selection",
    tooltip = "Snaps selected parts on the grid",
    uiType = "buttonProperty",
    buttonText = "Snap",
    func = function(v)
      Grid:SnapSelection()
    end,
    layout = {"color", Color(0, 0, 0, 0)}
  }
}

Grid.Settings = {
  showCompass = false,
  showGrid = false
}

function Grid:Update()
  if BuilderCompass and BuilderCompass.UpdateCompass then
    BuilderCompass:UpdateCompass(HBBuilder.Builder.root, self.Settings.showCompass)
  end ---pffff rly goto spend an update here, how convenient

  --[[
if self.Settings.showGrid then
if BuilderGrid and BuilderGrid.SetEnabled then
BuilderGrid:SetEnabled(v)
end --yep, and another one.
end ]]
end

-------------------
-----INTERFACE-----
-------------------
function Grid:SnapSelection()
  self:DoSnapSelectionPosition()
  self:DoSnapSelectionRotation()

  --play sap sound
  WorldEditor.Play("reset")
  --Audio:Play("alert_click",true,true)
  --fix floating floats
  Grid:FixAllFloatingFloats()
end

function Grid:SnapSelectionPosition()
  self:DoSnapSelectionPosition()

  --play sap sound
  WorldEditor.Play("reset")
  --Audio:Play("alert_click",true,true)
end

function Grid:SnapSelectionRotation()
  self:DoSnapSelectionRotation()

  --play sap sound
  WorldEditor.Play("reset")
  --Audio:Play("alert_click",true,true)
end

function Grid:FixAllFloatingFloats()
  --for bodyContainer in Slua.iter(HBBuilder.Builder.currentAssembly.bodyContainers) do
  --  for partContainer in Slua.iter(bodyContainer.partContainers) do
  --    partContainer.transform.localPosition    = self:Snap(partContainer.transform.localPosition   ,0.001)
  --    partContainer.transform.localEulerAngles = self:Snap(partContainer.transform.localEulerAngles,0.001)
  --    partContainer.transform.localScale       = self:Snap(partContainer.transform.localScale      ,0.001)
  --  end
  --end
end

------------------
------UTILS-------
------------------
function Grid:DoSnapSelectionPosition()
  --foreach selected >>
  if not Slua.IsNull(HBBuilder.Builder.selection) then
    for sel in Slua.iter(HBBuilder.Builder.selection) do
      if sel and not Slua.IsNull(sel) then
        self:DoSnapPosition(sel)
      end
    end
  end
end

function Grid:DoSnapSelectionRotation()
  --foreach selected >>
  if not Slua.IsNull(HBBuilder.Builder.selection) then
    for sel in Slua.iter(HBBuilder.Builder.selection) do
      if sel and not Slua.IsNull(sel) then
        self:DoSnapRotation(sel)
      end
    end
  end
end

function Grid:DoSnapPosition(sel)
  if not self then
    return
  end
  if not sel or Slua.IsNull(sel) then
    return
  end

  sel.transform.position =
    HBBuilder.BuilderUtils.Snap(
    sel.transform.position,
    HBBuilder.Builder.grid,
    sel:GetComponentInParent("HBBuilder.BodyContainer").gameObject
  )

  --do it difrent for pipes/plates
  --  if string.match(sel.gameObject.name, "AdjustablePipe") or string.match(sel.gameObject.name, "AdjustablePlate") then
  --    sel.transform.position = HBBuilder.BuilderUtils.Snap( sel.transform.position, HBBuilder.Builder.grid, sel:GetComponentInParent("HBBuilder.BodyContainer").gameObject )
  --  else
  --    --fetch partContainer
  --    local partContainer = sel:GetComponent("PartContainer")
  --
  --    --calc grab position
  --    local grabPosition = sel.transform.position
  --
  --    grabPosition = sel.transform:TransformPoint(Vector3(partContainer.cog.x, partContainer.cog.y, partContainer.cog.z))
  --
  --    --calc offset between grab position and gamobject position
  --    local grabPositionOffset = sel.transform.position - grabPosition
  --
  --    --snap grab position
  --    grabPosition =
  --      HBBuilder.BuilderUtils.Snap(
  --      grabPosition,
  --      HBBuilder.Builder.grid,
  --      sel:GetComponentInParent("HBBuilder.BodyContainer").gameObject
  --    )
  --    --apply final position
  --    sel.transform.position = grabPosition + grabPositionOffset
  --  end
end

function Grid:DoSnapRotation(sel)
  if not self then
    return
  end
  if not sel or Slua.IsNull(sel) then
    return
  end

  --snap euler angles
  sel.transform.eulerAngles = HBBuilder.Builder.EulerSnap(sel.transform.eulerAngles, HBBuilder.Builder.rotationGrid)
end

function Grid:Snap(v, s)
  v.x = Mathf.Round(v.x / s) * s
  v.y = Mathf.Round(v.y / s) * s
  v.z = Mathf.Round(v.z / s) * s
  return v
end

function Grid:CreateUI()
  local backgroundColor = Color(BUI.colors.black.r, BUI.colors.black.g, BUI.colors.black.b, 0.7)
  self.wizzard =
    BUI.Wizzard:Create(
    {
      name = "Grid Settings",
      hidable = true,
      hideOnStart = true,
      layout1 = {"min", Vector2(300, (3 + #Grid.InspectorProperties) * 25), "color", backgroundColor},
      layout2 = {}
    },
    WorldEditor.persistantToolContainer
  )
  self.wizzard:SetProperties(self.InspectorProperties)

  local prop

  prop =
    self:CreateGridProperty(
    self.wizzard.contentParent,
    "Grid",
    "positional grid in meters",
    function()
      HBBuilder.Builder.grid = Mathf.Clamp(self:RoundNearestPowerOfTwo(HBBuilder.Builder.grid * 2 * 10) / 10, 0.01, 100)
      if BuilderGrid and BuilderGrid.OnGridChanged then
        BuilderGrid:OnGridChanged()
      end
    end,
    function()
      HBBuilder.Builder.grid =
        Mathf.Clamp(self:RoundNearestPowerOfTwo(HBBuilder.Builder.grid * 0.5 * 10) / 10, 0.01, 100)
      if BuilderGrid and BuilderGrid.OnGridChanged then
        BuilderGrid:OnGridChanged()
      end
    end,
    function(v)
      HBBuilder.Builder.grid = Mathf.Clamp(v, 0.01, 100)
      if BuilderGrid and BuilderGrid.OnGridChanged then
        BuilderGrid:OnGridChanged()
      end
    end,
    function()
      return tostring --[[self:RoundNearestPowerOfTwo(HBBuilder.Builder.grid*10)/10]](
        math.round(HBBuilder.Builder.grid * 1000) * (1 / 1000)
      ) .. "m"
    end
  )
  self.wizzard:AddCustomProperty(prop)

  prop =
    self:CreateGridProperty(
    self.wizzard.contentParent,
    "Angle Grid",
    "rotational grid in degrees",
    function()
      HBBuilder.Builder.rotationGrid =
        Mathf.Clamp(self:RoundNearestPowerOfTwo(HBBuilder.Builder.rotationGrid * 2 / 9) * 9, 1, 360)
    end,
    function()
      HBBuilder.Builder.rotationGrid =
        Mathf.Clamp(self:RoundNearestPowerOfTwo(HBBuilder.Builder.rotationGrid * 0.5 / 9) * 9, 1, 360)
    end,
    function(v)
      HBBuilder.Builder.rotationGrid = Mathf.Clamp(v, 1, 360)
    end,
    function()
      return tostring --[[self:RoundNearestPowerOfTwo(HBBuilder.Builder.rotationGrid/9)*9]](
        HBBuilder.Builder.rotationGrid
      ) .. "°"
    end
  )
  self.wizzard:AddCustomProperty(prop)
  --[[ 
  prop =
    self:CreateAlignGridProperty(
    self.wizzard.contentParent,
    "Align Grid",
    "Align grid along the X,Y,Z axis",
    function()
      if BuilderGrid and BuilderGrid.Align then
        BuilderGrid:Align("x")
      end
    end,
    function()
      if BuilderGrid and BuilderGrid.Align then
        BuilderGrid:Align("y")
      end
    end,
    function()
      if BuilderGrid and BuilderGrid.Align then
        BuilderGrid:Align("z")
      end
    end
  )
  self.wizzard:AddCustomProperty(prop) ]]
end

function Grid:CreateGridProperty(parent, name, tooltip, doubleFunc, halfFunc, setFunc, returnValueFunc)
  local panel = BUI.Container(parent, "name", "GridProperty", "min", Vector2(0, 30), "tooltip", tooltip)
  BUI.Text(panel, "text", name, "offsetmin", Vector2(10, 0), "textalign", TextAnchor.MiddleLeft, "fontsize", 12)
  --local numbertext = BUI.Text(panel,"text",name,"anchormin",Vector2(1,0.5),"anchormax",Vector2(1,0.5),"pivot",Vector2(1,0.5),"position",Vector2(-110,0),"size",Vector2(50,20),"textalign",TextAnchor.MiddleLeft,"fontsize",12)
  --BUI.Apply(numbertext,"text",tostring( eturnValueFunc()))
  local numberField = false
  if setFunc then
    numberField =
      BUI.FloatInput(
      panel,
      "name",
      "gridInput",
      "anchormin",
      Vector2(1, 0.5),
      "anchormax",
      Vector2(1, 0.5),
      "pivot",
      Vector2(1, 0.5),
      "position",
      Vector2(-87, 0),
      "size",
      Vector2(60, 20),
      "onendedit",
      function(v)
        v = self:ExtractNumber(v)
        setFunc(v)
        if numberField then
          BUI.Apply(numberField, "inputfieldtext", returnValueFunc())
        end
      end
    )
  end
  if doubleFunc then
    BUI.Button(
      panel,
      "name",
      "gridDouble",
      "text",
      "x2",
      "anchormin",
      Vector2(1, 0.5),
      "anchormax",
      Vector2(1, 0.5),
      "pivot",
      Vector2(1, 0.5),
      "position",
      Vector2(-5, 0),
      "size",
      Vector2(40, 20),
      "onclick",
      function()
        doubleFunc()
        if numberField then
          BUI.Apply(numberField, "inputfieldtext", returnValueFunc())
        end
      end
    )
  end
  if halfFunc then
    BUI.Button(
      panel,
      "name",
      "gridHalf",
      "text",
      "/2",
      "anchormin",
      Vector2(1, 0.5),
      "anchormax",
      Vector2(1, 0.5),
      "pivot",
      Vector2(1, 0.5),
      "position",
      Vector2(-46, 0),
      "size",
      Vector2(40, 20),
      "onclick",
      function()
        halfFunc()
        if numberField then
          BUI.Apply(numberField, "inputfieldtext", returnValueFunc())
        end
      end
    )
  end
  if numberField then
    BUI.Apply(numberField, "inputfieldtext", returnValueFunc())
  end
  return panel
end

function Grid:CreateAlignGridProperty(parent, name, tooltip, alignXFunc, alignYFunc, alignZFunc)
  local panel = BUI.Container(parent, "name", "GridAlignProperty", "min", Vector2(0, 30), "tooltip", tooltip)
  BUI.Text(panel, "text", name, "offsetmin", Vector2(10, 0), "textalign", TextAnchor.MiddleLeft, "fontsize", 12)
  if alignXFunc then
    BUI.Button(
      panel,
      "name",
      "gridAlignX",
      "text",
      "x",
      "anchormin",
      Vector2(1, 0.5),
      "anchormax",
      Vector2(1, 0.5),
      "pivot",
      Vector2(1, 0.5),
      "position",
      Vector2(-87, 0),
      "size",
      Vector2(40, 20),
      "onclick",
      function()
        alignXFunc()
      end
    )
  end
  if alignYFunc then
    BUI.Button(
      panel,
      "name",
      "gridAlignY",
      "text",
      "y",
      "anchormin",
      Vector2(1, 0.5),
      "anchormax",
      Vector2(1, 0.5),
      "pivot",
      Vector2(1, 0.5),
      "position",
      Vector2(-46, 0),
      "size",
      Vector2(40, 20),
      "onclick",
      function()
        alignYFunc()
      end
    )
  end
  if alignZFunc then
    BUI.Button(
      panel,
      "name",
      "gridAlignZ",
      "text",
      "z",
      "anchormin",
      Vector2(1, 0.5),
      "anchormax",
      Vector2(1, 0.5),
      "pivot",
      Vector2(1, 0.5),
      "position",
      Vector2(-5, 0),
      "size",
      Vector2(40, 20),
      "onclick",
      function()
        alignZFunc()
      end
    )
  end
end

function Grid:RoundNearestPowerOfTwo(x)
  return Mathf.Pow(2, Mathf.Round(Mathf.Log(x) / Mathf.Log(2)))
end

function Grid:Start()
  self:CreateUI()
end

function Grid:OnDestroy()
  if self.wizzard then
    self.wizzard:Destroy()
  end
end

function Grid:ExtractNumber(v)
  if not self then
    return
  end
  if not v then
    v = "0.1"
  end
  v = v:gsub("[,]", "."):match("[0-9][0-9.]*")
  v = tonumber(v)
  if not v or not type(v) == "number" then
    v = 0.1
  end
  return v
end

return Grid
