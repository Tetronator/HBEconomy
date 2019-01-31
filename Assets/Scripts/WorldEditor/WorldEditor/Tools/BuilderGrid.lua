BuilderGrid = {}

BuilderGrid.Settings = {
  alignment = "y",
}

function BuilderGrid:Start()
  self.grid = self:CreateGrid()
  self:SetEnabled(false)
end 

function BuilderGrid:OnDestroy()
  if self.grid and not Slua.IsNull(self.grid) then GameObject.Destroy(self.grid) end 
end


function BuilderGrid:CreateGrid()
  local grid                   = GameObject.CreatePrimitive(PrimitiveType.Plane)
  grid.name                    = "BuilderGrid"
  grid.transform.parent        = HBBuilder.Builder.root.transform 
  grid.transform.localPosition = Vector3.zero
  grid.transform.localRotation = Quaternion.identity
  grid.transform.localScale    = Vector3(50,50,50) * 0.1 * (HBBuilder.Builder.grid*10)

  local renderer = grid:GetComponent("MeshRenderer")
  if renderer and not Slua.IsNull(renderer) then 
    renderer.sharedMaterial = Resources.Load("BuilderGridMat","UnityEngine.Material")
    if renderer.sharedMaterial and not Slua.IsNull(renderer.sharedMaterial) then 
      renderer.sharedMaterial.mainTextureScale = Vector2(50,50) 
    end 
  end 

  local gridForward                   = GameObject.CreatePrimitive(PrimitiveType.Plane)
  gridForward.name                    = "BuilderGridForward"
  gridForward.transform.parent        = grid.transform 
  gridForward.transform.localPosition = Vector3.zero
  gridForward.transform.localRotation = Quaternion.identity
  gridForward.transform.localScale    = Vector3(1,1,1) * 0.05

  local rendererForward = gridForward:GetComponent("MeshRenderer")
  if rendererForward and not Slua.IsNull(renderer) then 
    rendererForward.sharedMaterial = Resources.Load("BuilderGridForwardMat","UnityEngine.Material")
  end 

  HBBuilder.BuilderUtils.SetLayer(grid,22,true)

  return grid
end

function BuilderGrid:SetEnabled(bool)
  if not self then return end 
  if bool then 
    if self.grid and not Slua.IsNull(self.grid) then self.grid:SetActive(true) end 
    self:OnGridChanged()
  else 
    if self.grid and not Slua.IsNull(self.grid) then self.grid:SetActive(false) end 
  end 
end 

function BuilderGrid:Align(a)
  if not self then return end 
  if not self.grid or Slua.IsNull(self.grid) then return end 
  if not a then a = "y" end 
  if type(a) == "number" then if a == 0 then a = "x" elseif a == 1 then a = "y" else a = "z" end end 
  if not type(a) == "string" then a = "y" end 
  if self.Settings then self.Settings.alignment = a end 
  self:OnGridChanged()
end 

function BuilderGrid:OnGridChanged()
  if not self then return end 
  if self.grid and not Slua.IsNull(self.grid) then 
    self.grid.transform.localScale = Vector3(50,50,50) * 0.1 * (HBBuilder.Builder.grid*10)
    if self.Settings and self.Settings.alignment then 
      if self.Settings.alignment == "x" then 
        self.grid.transform.localRotation = Quaternion.Euler(0,0,90)
      elseif self.Settings.alignment == "y" then 
        self.grid.transform.localRotation = Quaternion.Euler(0,0,0)
      else 
        self.grid.transform.localRotation = Quaternion.Euler(-90,0,0)
      end 
    end 
    self.grid.transform:Find("BuilderGridForward").gameObject:SetActive(not (self.Settings.alignment == "z"))    
  end 
  
end 

return BuilderGrid