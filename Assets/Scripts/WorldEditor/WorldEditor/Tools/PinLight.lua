PinLight = {}

function PinLight:Update()
  ----------------------------------------------------------------------------------------------
  --press [P] to pin a new light at camera
  --press [U] to unpin all lights
  ----------------------------------------------------------------------------------------------

 --[[  if not HBU.InSeat() and not HBU.InMenu and not HBU.InBuilder() then
    if Input.GetKeyDown(KeyCode.P) then
      self:PinIt()
      self:LogValidMaterials() --just to show you , it doesnt do anyting rly
    end
    if Input.GetKeyDown(KeyCode.U) then
      self:UnPinIt()
    end
  end ]]

  ----------------------------------------------------------------------------------------------
end

function PinLight:PinIt()
  print("PinLight:PinIt")

  ----------------------------------------------------------------------------------------------
  --create the gameobject we wish to pin
  ----------------------------------------------------------------------------------------------

  local g = GameObject.CreatePrimitive(PrimitiveType.Cube)
  local l = g:AddComponent("UnityEngine.Light")
  l.color = Color.red
  l.range = 500
  l.intensity = 2

  --the primitive cube will spawn with an invalid material
  --so lets assign a valid one ( otherwise itl load in as pink )
  local r = g:GetComponent("Renderer")
  r.sharedMaterial = Resources.Load("hex_floor_rim_UVFREE", "UnityEngine.Material")

  ----------------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------------
  --position it ( at our camera )
  ----------------------------------------------------------------------------------------------

  g.transform.position = Camera.main.transform.position
  g.transform.rotation = Camera.main.transform.rotation

  ----------------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------------
  --save asset
  ----------------------------------------------------------------------------------------------

  local path = Application.streamingAssetsPath .. "/MyWorld/Assets/PinTest/pinTestAsset.hbp"
  --make sure the directory exists
  HBU.CreateDirectory(HBU.GetDirectoryName(path))
  HBU.SaveAsset(path, "World", g, false) --this last bool means that we dont want to save a .hbm meta file with it

  ----------------------------------------------------------------------------------------------
  --pin the asset
  ----------------------------------------------------------------------------------------------

  --now that our asset is saved we can pin it
  --basicly register it for the world system to spawn it based on positon
  --we can pin thesame asset multiple times, like the blue flags in canyon is 1 hbp pinned 100 times
  --each pin action returns a pinID , wich can be used to unPin that specific ID
  --ppinID can be retreived from assets spawned via the world system
  --for example u can get the pinID of 1 of the hangers and unpin only that hanger
  HBU.PinAsset(path, g)

  ----------------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------------
  --rebuild sectors
  ----------------------------------------------------------------------------------------------

  --rebuild sectors to finalize your pin action ( you can pin a bunsh of stuff then rebuild )
  --rebuidlign takes a whle game will ahng for like 5 secs
  HBU.RebuildWorldSectors()

  ----------------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------------
  --destroy our object
  ----------------------------------------------------------------------------------------------

  --world system is gona spawn it now , so we dont need it anymore
  GameObject.Destroy(g)

  ----------------------------------------------------------------------------------------------
end

function PinLight:UnPinIt()
  ----------------------------------------------------------------------------------------------
  --unpin
  ----------------------------------------------------------------------------------------------

  local path = Application.streamingAssetsPath .. "/MyWorld/Assets/PinTest/pinTestAsset.hbp"
  if HBU.FileExists(path) then
    --we do not give a pinID as second argument so itl unpin all pin actions on this asset
    HBU.UnPinAsset(path)
  end

  ----------------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------------
  --rebuild sectors
  ----------------------------------------------------------------------------------------------

  HBU.RebuildWorldSectors()

  ----------------------------------------------------------------------------------------------
end

function PinLight:LogValidMaterials()
  ----------------------------------------------------------------------------------------------
  --How To Find Valid Materials
  ----------------------------------------------------------------------------------------------
  self.path = HBU.GetUserDataPath() .. "/Exports/"
  local allMaterials = iter(Resources.FindObjectsOfTypeAll("UnityEngine.Material"))
  for i, v in ipairs(allMaterials) do
    print(v.mainTexture.name)
    local textureMain = v.mainTexture
    local texture2d = new Texture2D(textureMain.width,textureMain.height, TextureFormat.RGBA32, false)
    HBU.SaveTexture2D(texture2d, self.path .. textureMain.name .. ".png")
  end

  ----------------------------------------------------------------------------------------------
end

return PinLight
