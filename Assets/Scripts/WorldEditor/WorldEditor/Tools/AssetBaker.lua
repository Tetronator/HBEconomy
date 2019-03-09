AssetBaker = {}

-----------------------------------------------
--baking
-----------------------------------------------
function AssetBaker:Bake()
  -----------------------------------------------
  --clone current assembly
  -----------------------------------------------
  local assembly = self:CloneAssembly()
  if not assembly or Slua.IsNull(assembly) then
    return
  end
  --destroy fixed node (god block)
  self:DestroyFixedNode(assembly)
  -----------------------------------------------
  --remove all empty part containers
  self:RemoveAllEmptyPartContainers(assembly)
  self:FixColliders(assembly)

  self:FixRigidbodies(assembly)

  return assembly
end

function AssetBaker:DestroyFixedNode(assembly)
  if not self then
    return
  end
  if not assembly or Slua.IsNull(assembly) then
    return
  end

  local allPartContainers = iter(assembly:GetComponentsInChildren("PartContainer"))
  for i, partContainer in ipairs(allPartContainers) do
    if partContainer.gameObject.name == "FixedNode" then
      GameObject.DestroyImmediate(partContainer.gameObject, false)
    end
  end
end

function AssetBaker:RemoveAllEmptyPartContainers(assembly)
  if not self then
    return
  end
  if not assembly or Slua.IsNull(assembly) then
    return
  end

  local allPartContainers = iter(assembly:GetComponentsInChildren("PartContainer"))
  for i, partContainer in ipairs(allPartContainers) do
    --destroy part container if it doesnt have a Part nor a MeshFilter nor wing code no buoyancy code
    if
      Slua.IsNull(partContainer:GetComponentInChildren("Part")) and
        Slua.IsNull(partContainer:GetComponentInChildren("UnityEngine.BoxCollider")) and
        Slua.IsNull(partContainer:GetComponentInChildren("UnityEngine.SphereCollider")) and
        Slua.IsNull(partContainer:GetComponentInChildren("UnityEngine.CapsuleCollider")) and
        Slua.IsNull(partContainer:GetComponentInChildren("UnityEngine.MeshFilter"))
     then
      GameObject.DestroyImmediate(partContainer.gameObject)
    end
  end
end

function AssetBaker:RemoveAllMeshCombineTags(assembly)
  if not self then
    return
  end
  if not assembly or Slua.IsNull(assembly) then
    return
  end

  local allMeshCombineTags = iter(assembly:GetComponentsInChildren("MeshCombineTag"))
  for i, meshCombineTag in ipairs(allMeshCombineTags) do
    GameObject.DestroyImmediate(meshCombineTag, false)
  end
end

function AssetBaker:FixRigidbodies(assembly)
  local allRigidbodies = iter(assembly:GetComponentsInChildren("UnityEngine.Rigidbody"))
  for i, R in ipairs(allRigidbodies) do
    R.isKinematic = false
    print(R)
  end
end

function AssetBaker:RemoveAllIndicators(assembly)
  if not self then
    return
  end
  if not assembly or Slua.IsNull(assembly) then
    return
  end

  local allIndicatorTags = iter(assembly:GetComponentsInChildren("IndicatorTag"))
  for i, indicatorTag in ipairs(allIndicatorTags) do
    GameObject.DestroyImmediate(indicatorTag.gameObject, false)
  end
end

function AssetBaker:CloneAssembly()
  if not self then
    return
  end
  if not HBBuilder.Builder.currentAssembly or Slua.IsNull(HBBuilder.Builder.currentAssembly) then
    return
  end

  local assembly = HBBuilder.Builder.CloneGameObject(HBBuilder.Builder.currentAssembly.gameObject)
  assembly.transform.parent = nil
  assembly.transform.position = HBBuilder.Builder.currentAssembly.transform.position
  assembly.transform.rotation = HBBuilder.Builder.currentAssembly.transform.rotation
  assembly.transform.localScale = HBBuilder.Builder.currentAssembly.transform.localScale

  --remove assembly component
  GameObject.DestroyImmediate(assembly:GetComponent("HBBuilder.Assembly"), false)

  return assembly
end

function AssetBaker:FixColliders(assembly)
  if not self then
    return
  end
  if not assembly or Slua.IsNull(assembly) then
    return
  end

  local allPartContainers = iter(assembly:GetComponentsInChildren("PartContainer"))
  for i, partContainer in ipairs(allPartContainers) do
    local allMeshColliders = iter(partContainer:GetComponentsInChildren("UnityEngine.MeshCollider"))
    if HBBuilder.BuilderUtils.GetStringData(partContainer.stringData, "isBoxCollider") == "true" then
      --destroy mesh coliders
      for o, meshCollider in ipairs(allMeshColliders) do
        GameObject.Destroy(meshCollider)
      end

      --add one box collider
      local col = partContainer.gameObject:AddComponent("UnityEngine.BoxCollider")
      col.size = partContainer.bounds.size
      col.center = partContainer.bounds.center
    else
      --split mesh colliders
      for o, meshCollider in ipairs(allMeshColliders) do
        HBBuilder.BuilderUtils.SplitMeshCollider(meshCollider)
      end
    end
  end

  local allMeshColliders = iter(assembly:GetComponentsInChildren("UnityEngine.MeshCollider"))
  for i, meshCollider in ipairs(allMeshColliders) do
    if not Slua.IsNull(meshCollider:GetComponent("HBLensFlare")) then
      GameObject.Destroy(meshCollider)
    end
  end
end

function AssetBaker:AddComponents(assembly)
  if not self then
    return
  end
  if not assembly or Slua.IsNull(assembly) then
    return
  end

  local allPartContainers = iter(assembly:GetComponentsInChildren("PartContainer"))
  for i, partContainer in ipairs(allPartContainers) do
    print(i, partContainer.stringData)
    --print(i, HBBuilder.BuilderUtils.GetStringData(partContainer.stringData, "Component"))
  end
end

-----------------------------------------------
--unity calls
-----------------------------------------------

function AssetBaker:Start()
  --register export callback
  HBBuilder.Builder.RegisterCallback(
    HBBuilder.BuilderCallback.PrepareExport,
    "vehicle baker on prepare export",
    function()
      print("EXPORT START")
      if WorldEditor.isPinning() then
        local bakedVehicle = self:Bake()
        if not bakedVehicle or Slua.IsNull(bakedVehicle) then
          return
        end
        WorldEditor.ExportedObject = bakedVehicle
        GameObject.Destroy(bakedVehicle)
      else
        print("Not pinning so not exporting")
      end
      print("EXPORT DONE")
    end
  )
end

function AssetBaker:OnDestroy()
  if self.testing then
    self:TestVehicle()
  end
end

return AssetBaker
