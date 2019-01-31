BuilderCamera = {}
BuilderCamera.zonedOut = false
BuilderCamera.smoothDeltaTime = 0.01

BuilderCamera.InspectorProperties = {
  {
    name = "Camera Settings",
    tooltip = "Camera Settings",
    uiType = "headerProperty",
    layout = {"color", Color(0, 0, 0, 0)}
  },
  {
    name = "Camera Speed",
    tooltip = "Sets the speed of the Camera",
    uiType = "sliderProperty",
    minValue = 0.1,
    maxValue = 10,
    value = function()
      return BuilderCamera.Settings.speedMultiplier
    end,
    func = function(v)
      BuilderCamera.Settings.speedMultiplier = v
    end,
    layout = {"color", Color(0, 0, 0, 0)}
  }
}

BuilderCamera.Settings = {
  acceleration = 10000,
  maxSpeed = 50,
  drag = 0.5,
  runMultiplier = 20,
  speedMultiplier = 1
}

-----------------------------------------------
--interface
-----------------------------------------------
function BuilderCamera:SetTarget(target, offset)
  if not self then
    return
  end
  if not target or Slua.IsNull(target) then
    self.target = nil
    if self.camBody and self.cam then
      self.camBody.transform.rotation = Quaternion.LookRotation(self.cam.transform.forward, Vector3.up)
    end
    for i, v in ipairs(self.cameraModes) do
      v.enabled = false
    end
  end
  self.target = target
  self.targetOffset = offset or Vector3.zero
end

function BuilderCamera:HandleMovement()
  if not self then
    return
  end
  if HBU.InMenu then
    return
  end

  if not self.target or Slua.IsNull(self.target) then
    -----------------------------------------------
    -----------------------------------------------
    --user control
    -----------------------------------------------
    --let user control camera if no target is assigned
    --lookaround
    if self:RightMouse() then
      local invertScale = 1
      if HBU.InvertY then
        invertScale = -1
      end
      local sensitivity = HomebrewManager.lookSensitivity
      local mouseDelta = Vector3(Input.GetAxis("Mouse X"), Input.GetAxis("Mouse Y"), 0) * sensitivity * 1
      self.camBody.transform:Rotate(-mouseDelta.y * invertScale, 0, 0, Space.Self)
      self.camBody.transform:Rotate(0, mouseDelta.x, 0, Space.World)
      HBU.SetLockState(CursorLockMode.Locked)
    else
      HBU.SetLockState(CursorLockMode.Confined)
    end

    --move camera
    if not HBU.Typing() and not HBBuilder.Builder.cameraLocked then
      local velocity = self.velocity or Vector3.zero
      local acceleration = self.Settings.acceleration or 1
      local runMultiplier = self.Settings.runMultiplier or 1
      local drag = self.Settings.drag or 1
      local maxSpeed = (self.Settings.maxSpeed or 1)
      if self:Run() > 0.5 and not self:AltKey() then
        maxSpeed = maxSpeed * runMultiplier
      elseif self.AltKey() then
        maxSpeed = maxSpeed / 10
      end
      velocity =
        velocity +
        self.camBody.transform:TransformDirection(Vector3(self:Strafe(), self:Elevate(), self:Move())) * acceleration *
          self.smoothDeltaTime
      velocity = velocity * (1 / (1 + drag))
      velocity = velocity.normalized * math.min(maxSpeed, velocity.magnitude)

      self.velocity = velocity

      self.camBody.transform:Translate(
        self.velocity * self.smoothDeltaTime * self.Settings.speedMultiplier,
        Space.World
      )
    end
  end
end

function BuilderCamera:CreateUI()
  local backgroundColor = Color(BUI.colors.black.r, BUI.colors.black.g, BUI.colors.black.b, 0.7)
  self.wizzard =
    BUI.Wizzard:Create(
    {
      name = "BuilderCamera Settings",
      hidable = true,
      hideOnStart = true,
      layout1 = {"min", Vector2(300, (1 + #BuilderCamera.InspectorProperties) * 23.5), "color", backgroundColor},
      layout2 = {}
    },
    WorldEditor.persistantToolContainer
  )
  self.wizzard:SetProperties(self.InspectorProperties)
end

-----------------------------------------------
-----------------------------------------------
--utils
-----------------------------------------------
function BuilderCamera:ShiftKey()
  return (Input.GetKey(KeyCode.LeftShift) or Input.GetKey(KeyCode.RightShift))
end

function BuilderCamera:AltKey()
  return (Input.GetKey(KeyCode.LeftAlt) or Input.GetKey(KeyCode.RightAlt))
end

function BuilderCamera:ControlKey()
  return (Input.GetKey(KeyCode.LeftControl) or Input.GetKey(KeyCode.RightControl))
end

function BuilderCamera:DeleteKey()
  return Input.GetKeyDown(KeyCode.Delete)
end

function BuilderCamera:Mouse()
  return Input.GetMouseButton(0)
end

function BuilderCamera:MouseDown()
  return Input.GetMouseButtonDown(0)
end

function BuilderCamera:MouseUp()
  return Input.GetMouseButtonUp(0)
end

function BuilderCamera:RightMouse()
  return Input.GetMouseButton(1)
end

function BuilderCamera:MousePosition()
  return Input.mousePosition
end

function BuilderCamera:Move()
  if Input.GetKey(KeyCode.LeftControl) or Input.GetKey(KeyCode.RightControl) then
    return
  end
  if not self.moveKey then
    self.moveKey = HBU.GetKey("Move")
  end
  if not self.moveKey or Slua.IsNull(self.moveKey) then
    return
  end
  return self.moveKey:GetKey()
end

function BuilderCamera:Strafe()
  if Input.GetKey(KeyCode.LeftControl) or Input.GetKey(KeyCode.RightControl) then
    return
  end
  if not self.strafeKey then
    self.strafeKey = HBU.GetKey("Strafe")
  end
  if not self.strafeKey or Slua.IsNull(self.strafeKey) then
    return
  end
  return self.strafeKey:GetKey()
end

function BuilderCamera:Elevate()
  if Input.GetKey(KeyCode.LeftControl) or Input.GetKey(KeyCode.RightControl) then
    return
  end
  if not self.jumpKey then
    self.jumpKey = HBU.GetKey("Jump")
  end
  if not self.crouchKey then
    self.crouchKey = HBU.GetKey("Crouch")
  end
  if not self.jumpKey or Slua.IsNull(self.jumpKey) then
    return
  end
  if not self.crouchKey or Slua.IsNull(self.crouchKey) then
    return
  end
  return self.jumpKey:GetKey() - self.crouchKey:GetKey()
end

function BuilderCamera:Run()
  if not self.runKey then
    self.runKey = HBU.GetKey("Run")
  end
  if not self.runKey or Slua.IsNull(self.runKey) then
    return
  end
  return self.runKey:GetKey()
end

function BuilderCamera:PositionCameraOnAssembly()
  if not self then
    return
  end
  if not self.camBody or Slua.IsNull(self.camBody) then
    return
  end
  local bounds = HBBuilder.BuilderUtils.GetGameObjectBounds(HBBuilder.Builder.currentAssembly.gameObject)
  local size = math.max(3, math.max(bounds.size.x * 0.5, math.max(bounds.size.y * 0.5, bounds.size.z * 0.5)))
  self.camBody.transform.position = HBBuilder.Builder.currentAssembly.transform.position + Vector3(-1, 1.2, -1) * size
  self.camBody.transform.rotation = Quaternion.Euler(45, 45, 0)
end

-----------------------------------------------
--unity calls
-----------------------------------------------
function BuilderCamera:Awake()
  self.cam = Camera.main
  self.preCamClearFlags = self.cam.clearFlags
  self.preCamNearClipPlane = self.cam.nearClipPlane
  self.preCamFarClipPlane = self.cam.farClipPlane
  self.preCamCullingMask = self.cam.cullingMask
  self.cam2 = Camera.main.transform:Find("MainCamera Near"):GetComponent("Camera")
  self.preCam2NearClipPlane = self.cam2.nearClipPlane
  self.preCam2FarClipPlane = self.cam2.farClipPlane
  self.preCam2CullingMask = self.cam2.cullingMask
  self.preSkyboxMat = RenderSettings.skybox

  self.camBody = GameObject("CameraBody")
  self.camBody.transform.parent = HBBuilder.Builder.root.transform
  self.camBody.transform.position = Camera.main.transform.position
  self.camBody.transform.rotation = Camera.main.transform.rotation
  self.camBody.transform.localScale = Vector3.one
  self.camBody:AddComponent("WorldLooperListener")

  self.cam.transform.parent = self.camBody.transform
  self.cam.transform.localPosition = Vector3.zero
  self.cam.transform.localRotation = Quaternion.identity
  self.cam.transform.localScale = Vector3.one

  self.cam.nearClipPlane = 0.1
  self.cam.farClipPlane = 100000
  self.cam.cullingMask = 0

  self.cam2.nearClipPlane = 0.1
  self.cam2.farClipPlane = 100000
  self.cam2.cullingMask =
    1 << 22 | 1 << 20 | 1 << 19 | 1 << 18 | 1 << 17 | 1 << 16 | 1 << 15 | 1 << 14 | 1 << 12 | 1 << 11 | 1 << 10 | 1 << 5 |
    1 << 4 |
    1 << 2 |
    1 << 1 |
    1 << 0
  self:PositionCameraOnAssembly()
  HBBuilder.Builder.RegisterCallback(
    HBBuilder.BuilderCallback.OpenProject,
    "builder camera on open project",
    function()
      self:PositionCameraOnAssembly()
    end
  )
end

function BuilderCamera:Start()
  self:CreateUI()
end

function BuilderCamera:OnDestroy()
  self.cam.transform.parent = GameObject.FindWithTag("Player").transform:Find("playerPivot/headPivot")
  self.cam.transform.localPosition = Vector3.zero
  self.cam.transform.localRotation = Quaternion.identity
  self.cam.transform.localScale = Vector3.one

  self.cam.clearFlags = self.preCamClearFlags
  self.cam.nearClipPlane = self.preCamNearClipPlane
  self.cam.farClipPlane = self.preCamFarClipPlane
  self.cam.cullingMask = self.preCamCullingMask

  self.cam2.nearClipPlane = self.preCam2NearClipPlane
  self.cam2.farClipPlane = self.preCam2FarClipPlane
  self.cam2.cullingMask = self.preCam2CullingMask
  print("set cam near clip to ", self.preCamNearClipPlane)

  RenderSettings.skybox = self.preSkyboxMat

  self.cam:GetComponent("TOD_Camera").enabled = true
  self.cam:GetComponent("TOD_Scattering").enabled = true
  self.cam2:GetComponent("UnityEngine.Rendering.PostProcessing.PostProcessLayer").enabled = true

  GameObject.Destroy(self.camBody)

  HBBuilder.Builder.UnRegisterCallback("builder camera on open project")
end

function BuilderCamera:Update()
  self.cam.transform.parent = self.camBody.transform
  self.cam.transform.localPosition = Vector3.zero
  self.cam.transform.localRotation = Quaternion.identity
  self.cam.transform.localScale = Vector3.one

  self.cam.nearClipPlane = 0.1
  self.cam.farClipPlane = 100000

  self.cam2.nearClipPlane = 0.1
  self.cam2.farClipPlane = 100000

  self.smoothDeltaTime = Time.smoothDeltaTime

  self:HandleMovement()
end

-----------------------------------------------
return BuilderCamera
