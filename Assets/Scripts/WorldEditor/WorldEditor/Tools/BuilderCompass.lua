
----------------------
-- Builders BuilderCompass --
----------------------

-- In Update:

--self.BuilderCompass:Update(self.Settings.enable_compass)

-- To change grid height:

--self.BuilderCompass:ChangeGridHeight( grid_height )



BuilderCompass = {
  
      Settings      = {
        grid_height = 0,
        grid_scale  = 1,
        images_dir  = Application.streamingAssetsPath.."/Lua/main/BuilderTools/CompassImages",
        enabled     = false,
      },
  
      isCompassRoot = true,
  
      reset         = false,
  
      iter          =  function(...) --[[ v4 ]]  local  ret,rc = {},0;  for k = 1,select("#",...) do local obj = (select(k,...));    if      type(obj) == "userdata" then  rc = #ret ; pcall( function() for v in Slua.iter(obj) do rc = rc + 1 ; ret[rc] = v ; end ; end );    elseif  type(obj) == "table"    then  rc = #ret ; pcall( function() local k,v = next(obj) ; while k ~= nil do rc = rc + 1 ; ret[rc] = v ; k,v = next(obj,k) ; end ; end );    elseif  type(obj) == "function" and obj ~= iter then  rc = #ret ; pcall( function() for v in obj do rc = rc + 1 ; ret[rc] = v ; end ; end );    end;  end;  return ret;end,
  
      Destroyables  = {},
  
      Objects       = {},
  
      ImageURLs     = {},
  
      GetImageURLs  = 
      function(self) 
        if not self then return ; end ; 
        return pcall( function(self) 
          for v in Slua.iter(HBU.GetFiles(self.Settings.images_dir,"compass*.png")) do 
            self.ImageURLs[#self.ImageURLs+1] = v ;
          end ; 
        end, self ) ; 
      end,
  
      GetImages     =
        function(self)
          for k,v in pairs(self.ImageURLs) do
              local name = tostring(v):gsub(".*/","");
              local tex = HBU.LoadTexture2D((v:gsub("^file[:][/][/]*","")));
              if tex then self.Destroyables[#self.Destroyables+1] = name; self.Destroyables[name] = tex; end;
          end;
        end,
  
  
      Shaders       = {
        "Legacy Shaders/Transparent/Diffuse",
        "Particles/Additive",
        "Particles/Alpha Blended",
        "Particles/Multiply",
        "Legacy Shaders/Transparent/Cutout/VertexLit",
        "Convex Games/HeatHaze Animated Texture",
      },
  
      ChangeGridHeight =
        function(self, newHeight)
          if type(self) ~= "table" or not self.isCompassRoot then return false ; end;
          if not newHeight then return self:AutoSetGridHeight() ; end
          newHeight = ( tonumber(newHeight) and tonumber(newHeight) ) or self.Settings.grid_height or -0.72;
          if    self.Objects and #self.Objects > 0
          then
                for k,v in pairs(self.Objects) do
                  if v and v.transform and not Slua.IsNull(v.transform) then
                    local curPosition         = v.transform.localPosition;
                    local newPosition         = Vector3(curPosition.x,newHeight,curPosition.z);
                    v.transform.localPosition = newPosition;
                  end;
                end;
          end;
        end,
  
      ChangeGridScale =
        function(self, newScale)
          newScale = ( tonumber(newHeight) and tonumber(newHeight) ) or self.Settings.grid_scale or -0.72
        end,
  
      AutoSetGridHeight =
        function(self)
          return pcall(
            function()
              local ret = false
              if not self.compass1 then --[[print("BuilderCompass:AutoSetGridHeight() - No compass exists to set height on.");]] return ret; end;
              local positionCompass = ( self.compass1 and self.compass1.transform.position ) or false
              local positionFrom    = Camera.main.transform.position
              local terrainHeight = -1000000
              for x = -20,20,5 do
              for z = -20,20,5 do
              for k,v in pairs(self:RaycastAll(positionFrom+Vector3(x,10,z),Vector3(0,-1,0))) do if tostring(v.transform.root):match("Terrain") then terrainHeight = math.max(terrainHeight,v.point.y) ; end ; end
              end
              end
              if    terrainHeight > -1000000
              then
                    if      ( positionCompass and positionCompass.y < terrainHeight + 0.3 )
                    then
                            ret = ((terrainHeight+0.3)-positionCompass.y)
                            self.Settings.grid_height = self.Settings.grid_height + ret
                            self:ChangeGridHeight()
                            print("BuilderCompass/Grid below terrain, so lifting grid up to new offset.")
                    end
                    return ret
              else
                    return false
              end
            end
          )
        end,
  
      RaycastAll =
        function(self,fromPosition,forwardDirection,castDistance,searchString,doNotSortResults)
            fromPosition     = fromPosition     or Camera.main.transform.position
            forwardDirection = forwardDirection or Camera.main.transform.forward
            castDistance     = castDistance     or 10000000
            searchString     = ( type(searchString) == "string" and searchString or "" )
            local rt = {}
            local rtAll = {}
            for v in Slua.iter(Physics.RaycastAll(fromPosition, forwardDirection, castDistance)) do local goString = tostring(v.transform.gameObject) ; if ( not searchString or searchString == "" or string.find(string.lower(tostring(goString)),searchString) )  and  not tostring(v.transform.parent):find("Container")  then rt[#rt+1] = v ; end ; end
            if    not doNotSortResults
            then  self.sortbysubkey(rt,"distance")
            end
            return rt
        end,
  
      Awake =
        function(self)
            if not self then return false ; end
            if self.awakeComplete then return ; end
            self.awakeComplete = true
            pcall( function() HBU.CreateDirectory(self.Settings.images_dir) ; end )
            if self.GetImageURLs then self:GetImageURLs() ; end
            if self.GetImages then self:GetImages() ; end
        end,
  
      UpdateCompass =
        function(self,parent,enabled)
          if type(self)    ~= "table" or not self.isCompassRoot or not HBU then return ; end
          if type(parent)  == "boolean" or type(enabled) == "userdata" then enabled,parent = parent,enabled; end
          if type(parent)  == "userdata" and not Slua.IsNull(parent) and ( not self.parent or self.parent ~= parent ) and self.Objects and pcall( function() return parent.transform ; end ) then self.parent = parent; for k,v in pairs(self.Objects) do if v.SetParent then v:SetParent(self.parent); end; end; end;
          if type(enabled) ~= "boolean" then enabled = self.Settings.enabled ; else self.Settings.enabled = enabled ; end
          if type(self.parent) ~= "userdata" or Slua.IsNull(self.parent) then if self.Objects and next(self.Objects) then self:OnDestroy(); end; self.parent = nil; return; end;
          if not self.Settings.enabled then  if self.awakeComplete then self:OnDestroy(); end; return; end;
          self:Awake()
          if      self.reset   then    self.reset = false; self:OnDestroy(); return; end
          if      not select(2,next(self.Objects))
          then
                  self.compass1 = self:New("009",self.parent,96,Color.red  ,"Particles/Alpha Blended",Vector3( 0, (self.Settings.grid_height or 0),0)     , self:GetCameraRotation(), false )
                  self.compass2 = self:New("004",self.parent,75,Color.white,"Particles/Alpha Blended",Vector3( 0, (self.Settings.grid_height or 0)+0.01,0), Vector3(90,0,0)         , true  )
                  --self.compass3 = self:New("004",self.parent,75,Color(1.0,1.0,1.0,1.0), "Particles/Additive",       Vector3( 0, (self.Settings.grid_height or 0)+0.01,0), Vector3(90,0,0),          false )
                --self.compass4 = self:New("colour_picker_sm",nil,75,Color(1.0,1.0,1.0,1.0), "Particles/Alpha Blended",     Vector3( 0, (self.Settings.grid_height or 0)+0.01,0), Vector3(90,0,0),          false )
                  self:AutoSetGridHeight()
  
          elseif  self.compass1 and ( not self.compass1.transform or Slua.IsNull(self.compass1.transform) )
          then    self:OnDestroy() ; return
  
          elseif  self.compass1 and not self.compass1.disposed
          then    self.compass1:SetRotation(self:GetCameraRotation())
          end
        end,
  
      SetParent =
        function(self,parent,keepWorldPosition)
            keepWorldPosition = ( keepWorldPosition and true or false )
            local res,ret = pcall( function() self.transform:SetParent(parent.transform,keepWorldPosition); end)
            if res then self.parent = parent ; return true ; else return false ; end
        end,
  
      SetScale =
        function(self,scale)
          scale = ( type(scale) == "number" and scale >= 0 and scale ) or 10
          return pcall( function() self.gameObject.transform.localScale = Vector3( 1/(self.texture.width+self.texture.height)*self.texture.width*scale, 1/(self.texture.width+self.texture.height)*self.texture.height*scale,1/(self.texture.width+self.texture.height)*self.texture.height*scale ) ; end )
        end,
  
      SetShader =
        function(self,shaderName)
            return pcall(
              function()
                shaderName = ( type(shaderName) == "string" and shaderName ) or (select(2,next(self.Shaders))) or false
                local s = self.Shaders[shaderName]
                self.renderer.sharedMaterial.shader = s
                shaderName = tostring(s)
                return shaderName
              end
            )
        end,
  
      FindShader =
        function(self,search)
            if not self or not self.iter then return {} ; end
            search = ( type(search) == "string" and search or "UnityEngine.Shader" ):lower()
            if search == "" then return self.iter(Resources.FindObjectsOfTypeAll(Shader)) ; end
            local rt = {}
            for v in Slua.iter(Resources.FindObjectsOfTypeAll("UnityEngine.Shader")) do if tostring(v):lower():match(search) then rt[#rt+1] = v ; end ; end
            return rt
        end,
  
      Rotate = 
        function(self,rotModEuler,rotationIsRelativeToParent)
            rotModEuler = ( tostring(rotModEuler):match("Vector3") and rotModEuler ) or Vector3(90,0,0)
            if    self.parent and rotationIsRelativeToParent
            then  return pcall( function() self.gameObject.transform.localRotation = self.gameObject.transform.localRotation * Quaternion.Euler( rotModEuler ) ; end )
            else  return pcall( function() self.gameObject.transform.rotation      = self.gameObject.transform.rotation      * Quaternion.Euler( rotModEuler ) ; end )
            end
        end,
  
      GetCameraRotation = function(self) return Quaternion.Euler( -90, 180, Quaternion.LookRotation(Camera.main.transform.forward).eulerAngles.y ) ; end,
  
      SetRotation = 
        function(self,rotModEuler,rotationIsRelativeToParent)
            if not self then return ; end
            if      tostring(rotModEuler):match("Vector3")
            then    rotModEuler = Quaternion.Euler( rotModEuler )
            elseif  not tostring(rotModEuler):match("Quaternion")
            then    rotModEuler = Quaternion.Euler( Vector3(90,0,0) )
            end
            if    self.parent and rotationIsRelativeToParent
            then  return pcall( function() self.gameObject.transform.localRotation = rotModEuler ; end )
            else  return pcall( function() self.gameObject.transform.rotation = rotModEuler ; end )
            end
        end,
  
      SetColor =
        function(self,colorR,colorB,colorG,colorA)
            return pcall(
              function()
                  local color = false
                  if    tostring(colorR):match("Color")
                  then  color = colorR
                  else
                        color = Color(0,0,0,1)
                        if type(colorR) == "number" then color.r = colorR ; end
                        if type(colorG) == "number" then color.g = colorG ; end
                        if type(colorB) == "number" then color.b = colorB ; end
                        if type(colorR) == "number" then color.a = colorA ; end
                  end
                  self.renderer.sharedMaterial:SetColor("_TintColor",color)
                  return color
              end
            )
        end,
  
      OnDestroy =
        function(self)
          if not self then return ; end
          if  self.Objects and select(2,next(self.Objects)) then for k,v in pairs(self.Objects) do if v and v.OnDestroy then v:OnDestroy(); end; end; self.Objects = {}; end;
          if  self.Destroyables then if next(self.Destroyables) then for k,v in pairs(self.Destroyables) do pcall( function() GameObject.Destroy(v.texture) ; end ) ; pcall( function() GameObject.Destroy(v.gameObject) ; end ) ; pcall( function() GameObject.Destroy(v); end ); end; self.Destroyables = {}; end; end;
          if  self.isCompassRoot
          then
              self.awakeComplete = false
              self.compass1,self.compass2,self.compass3 = nil,nil,nil
              self.ImageURLs = {}
              self.Destroyables = {}
              return true
          end
          pcall( function() GameObject.Destroy(self.texture)    ; self.texture    = false ; end )
          pcall( function() GameObject.Destroy(self.gameObject) ; self.gameObject = false ; end )
          pcall( function() self.transform, self.renderer        = false,false ; end )
          pcall( function() BuilderCompass.Objects[self.objID]             = nil ;  end )
          pcall( function() BuilderCompass.Destroyables[self.textureID]    = nil ;  end )
          self.disposed = true
          return true
        end,
  
      New =
        function(self,compassType,parent,scale,color,shaderName,localPosition,localRotationEuler,rotationIsRelativeToParent)
  
          if not self then return false ; end
          if not self.awakeComplete then pcall( self.Awake, self ) ; end
          if not self.Destroyables or not self.Destroyables[1] or not self.Destroyables[self.Destroyables[1]] or Slua.IsNull(self.Destroyables[self.Destroyables[1]]) then return false ; end
  
          self.currentAssembly = GameObject.FindObjectOfType("AssemblyBuilder")
  
          if    self.currentAssembly and self.currentAssembly.curAssembly
          then  self.currentAssembly = self.currentAssembly.curAssembly
          else  self.currentAssembly = false
          end
  
          local texture = false
  
          if      ( type(compassType) == "number" or type(compassType) == "string" )
          and     self.Destroyables[compassType]
          then    texture = Texture2D.Instantiate(self.Destroyables[compassType])
          elseif  type(compassType) == "string"
          then    for k,v in pairs(self.Destroyables) do if tostring(k):lower():match(compassType) then texture = Texture2D.Instantiate(v) ; end ; end
          end
  
          if      not texture then texture = Texture2D.Instantiate(self.Destroyables[1]) ; end
  
          local gameObject = GameObject.CreatePrimitive(PrimitiveType.Quad)
          if not gameObject then return false ; end
          GameObject.Destroy(gameObject:GetComponentInChildren(Collider))
  
          local renderer = gameObject:GetComponentInChildren(Renderer)
  
          texture.name = "BuilderCompass"
  
          self.Destroyables[#self.Destroyables+1] = texture
  
          local textureID = #self.Destroyables
  
          renderer.material.mainTexture = texture
  
          self.Destroyables[#self.Destroyables+1] = renderer.material
  
          local objID = #self.Objects+1
  
          self.Objects[objID] = {
            isCompass   = true,
            gameObject  = gameObject,
            transform   = gameObject.transform,
            objID       = objID,
            texture     = texture,
            renderer    = renderer,
            textureID   = textureID,
            Shaders     = self.Shaders,
            Rotate      = self.Rotate,
            SetRotation = self.SetRotation,
            SetParent   = self.SetParent,
            SetScale    = self.SetScale,
            SetShader   = self.SetShader,
            SetColor    = self.SetColor,
            OnDestroy   = self.OnDestroy,
          }
  
          if parent then self.Objects[objID]:SetParent(parent,false) ; end
  
          gameObject.transform.localPosition = ( tostring(localPosition):match("Vector3") and localPosition or Vector3.zero )

          HBBuilder.BuilderUtils.SetLayer(gameObject,22,true)
  
          localRotationEuler = ( tostring(localRotationEuler):match("Vector3") and Quaternion.Euler(localRotationEuler) or Quaternion.Euler(Vector3.one) )
  
          self.Objects[objID]:SetRotation(localRotationEuler,rotationIsRelativeToParent)
  
          scale = ( type(scale) == "number" and scale or 10 )
  
          self.Objects[objID]:SetScale(scale)
  
          shaderName = (type(shaderName) == "string" and shaderName) or "Particles/Multiply"
  
          self.Objects[objID]:SetShader(shaderName)
  
          self.Objects[objID]:SetColor( ( tostring(color):match("Color") and color or Color(1,1,1,0.9) ) )
  
          return self.Objects[#self.Objects]
      end,

  }
  

setmetatable(BuilderCompass.Shaders,{__index = function(self,key) if type(key) ~= "string" then return false ; end ; for _,k in pairs(self) do if tostring(k):lower():match(key:lower()) then return Shader.Find(k) ; end ; end ; local r = Shader.Find(k) ; if r then return r ; end ; for _,v in pairs(iter(Resources.FindObjectsOfTypeAll(Shader))) do local k = tostring(v):gsub(" [(].*","") ; if tostring(k):lower():match(key:lower()) then return v ; end ; end  ; return Shader.Find(key) ; end,})


return BuilderCompass