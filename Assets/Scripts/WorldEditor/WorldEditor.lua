--[[
for obj in Slua.iter(HBBuilder.Builder.selection) do

local rb = obj.gameObject:GetComponent("Rigidbody")
if not rb and  Slua.IsNull(rb) then
rb = obj.gameObject:AddComponent("Rigidbody")
end

rb.mass = 15000
rb.angularDrag = 0
rb.drag = 0
rb.isKinematic=true
print(rb)
end

for obj in Slua.iter(HBBuilder.Builder.selection) do
    local rb = obj.gameObject:GetComponent("HBSupply")
    if not rb and Slua.IsNull(rb) then
        rb = obj.gameObject:AddComponent("HBSupply")
    end
    print(rb)
end
]]
WorldEditor = {}

-----------------------------------------------------------------
--  Settings and UI Declaration
-----------------------------------------------------------------
WorldEditor.builderType = "World"
WorldEditor.isOpen = false
WorldEditor.Saving = false
WorldEditor.Loading = false
WorldEditor.Pinning = false
WorldEditor.ExportedObject = nil

WorldEditor.Settings = {
    settingsVersion = "0.2",
    rebuildWorld = false,
    MoveAll = false,
    CustomTerrain = {}
}

WorldEditor.Scripts = {
    {official = true, path = "ModLua/WorldEditor/Tools/BuilderCamera.lua"},
    {official = true, path = "ModLua/WorldEditor/Tools/Inspector.lua"},
    {official = true, path = "ModLua/WorldEditor/Tools/BuilderGrid.lua"},
    {official = true, path = "ModLua/WorldEditor/Tools/BuilderCompass.lua"},
    {official = true, path = "ModLua/WorldEditor/Tools/AssetBaker.lua"},
    {official = true, path = "ModLua/WorldEditor/Tools/Grid.lua"},
    {official = true, path = "ModLua/WorldEditor/Tools/AddTool.lua"},
    {official = true, path = "ModLua/WorldEditor/Tools/SelectTool.lua"},
    {official = true, path = "ModLua/WorldEditor/Tools/MoveTool.lua"},
    {official = true, path = "ModLua/WorldEditor/Tools/RotateTool.lua"},
    {official = true, path = "ModLua/WorldEditor/Tools/ScaleTool.lua"},
    {official = true, path = "ModLua/WorldEditor/Tools/TerrainTool.lua"},
    {official = true, path = "ModLua/WorldEditor/Tools/PaintTool.lua"},
    {official = true, path = "ModLua/WorldEditor/Tools/WorldController.lua"},
    {official = true, path = "ModLua/WorldEditor/Tools/ChangeMaterialTool.lua"},
    {official = true, path = "ModLua/WorldEditor/Tools/AdjustTool.lua"}
    --    {official = true, path = "ModLua/WorldEditor/Tools/ComponentTool.lua"}
    --{official = true, path = "ModLua/WorldEditor/Tools/RaceTrackBuilder.lua"},
    --{official = true, path = "ModLua/WorldEditor/Tools/TrackBuilder.lua"},
}

WorldEditor.UtilityButtons = {
    {
        name = "New",
        icon = "lua/icons/builder/new.png",
        func = function()
            WorldEditor.New()
        end,
        layout = {},
        imageLayout = {"dualcolor", true},
        tooltip = "New Project",
        hoversound = "click_blip",
        clicksound = "affirm_blip_1",
        shortcut = false
    },
    {
        name = "Open",
        icon = "lua/icons/builder/open.png",
        func = function()
            WorldEditor.Open()
        end,
        layout = {},
        imageLayout = {"dualcolor", true},
        tooltip = "Open Project",
        hoversound = "click_blip",
        clicksound = "affirm_blip_1",
        shortcut = false
    },
    {
        name = "Save",
        icon = "lua/icons/builder/save.png",
        func = function()
            WorldEditor.Save()
        end,
        layout = {},
        imageLayout = {"dualcolor", true},
        tooltip = "Save Project",
        hoversound = "click_blip",
        clicksound = "affirm_blip_1",
        shortcut = false,
        groupID = "Save"
    },
    {
        name = "Save As",
        icon = "lua/icons/builder/save.png",
        func = function()
            WorldEditor.SaveAs()
        end,
        layout = {},
        imageLayout = {"dualcolor", true},
        tooltip = "Save Project As...",
        hoversound = "click_blip",
        clicksound = "affirm_blip_1",
        shortcut = false,
        groupID = "Save"
    },
    {
        name = "Move Builder",
        --uiType = "toggle",
        icon = "lua/icons/builder/movebuilder.png",
        func = function()
            WorldEditor.MoveBuilder()
        end,
        imageLayout = {"dualcolor", true},
        tooltip = "Moves the builder",
        hoversound = "click_blip",
        clicksound = "affirm_blip_1",
        shortcut = false
    },
    {
        name = "Pin",
        icon = "lua/icons/builder/addtool.png",
        func = function()
            WorldEditor.Pin()
        end,
        layout = {},
        imageLayout = {"dualcolor", true},
        tooltip = "Pin Project",
        hoversound = "click_blip",
        clicksound = "affirm_blip_1",
        shortcut = false,
        groupID = "pin"
    },
    {
        name = "Un Pin",
        icon = "lua/icons/builder/remove.png",
        func = function()
            WorldEditor.UnPin()
        end,
        layout = {},
        imageLayout = {"dualcolor", true},
        tooltip = "Un Pin Project",
        hoversound = "click_blip",
        clicksound = "affirm_blip_1",
        shortcut = false,
        groupID = "pin"
    },
    {
        name = "Rebuild World",
        icon = "lua/icons/builder/redo.png",
        func = function()
            WorldEditor.ReloadWorld()
        end,
        layout = {},
        imageLayout = {"dualcolor", true},
        tooltip = "Un Pin Project",
        hoversound = "click_blip",
        clicksound = "affirm_blip_1",
        shortcut = false,
        groupID = "pin"
    },
    {
        name = "Update Pin",
        icon = "lua/icons/builder/addtool.png",
        func = function()
            WorldEditor.UpdatePin()
        end,
        layout = {},
        imageLayout = {"dualcolor", true},
        tooltip = "Update Pin Project",
        hoversound = "click_blip",
        clicksound = "affirm_blip_1",
        shortcut = false,
        groupID = "pin"
    },
    {
        name = "Exit",
        icon = "lua/icons/builder/exit.png",
        func = function()
            if WorldEditor.Settings.rebuildWorld then
                WorldEditor.ReloadWorld()
            end
            if WorldEditor.hasChanged then
                local anwser =
                    HBU.QuestionBox(
                    "Would you like to save?",
                    "Save project",
                    Slua.GetClass("System.Windows.Forms.MessageBoxButtons").YesNoCancel
                )
                if anwser == "Yes" then
                    WorldEditor.Save()
                end
                if anwser == "Cancel" then
                    return
                end
            end
            Weather.gameObject:SetActive(true)
            HBBuilder.Builder.CloseBuilder()
        end,
        layout = {},
        imageLayout = {"dualcolor", true},
        tooltip = "Exit builder",
        hoversound = "click_blip",
        clicksound = "affirm_blip_1",
        shortcut = false
    }
}

WorldEditor.UtilitySpaces = {
    {after = "Save As", flexSpace = Vector2(0.02, 0)},
    {after = "Pin", flexSpace = Vector2(1, 0)}
}

WorldEditor.ToolOrder = {
    "AddTool",
    "Select Tool",
    "Move Tool",
    "Rotate Tool",
    "Scale Tool",
    "Paint Tool",
    "Material Changer",
    "Terrain Tool",
    "Race Track Builder"
}

WorldEditor.ToolSpaces = {
    {after = "Select Tool", flexSpace = Vector2(0.02, 0)},
    {after = "Scale Tool", flexSpace = Vector2(0.02, 0)},
    {after = "Material Changer", flexSpace = Vector2(0.02, 0)},
    {after = "Terrain Tool", flexSpace = Vector2(0.02, 0)},
    {after = "Adjust Tool", flexSpace = Vector2(1, 0)}
}

WorldEditor.AudioConfig = {
    ["select"] = "click-blip",
    ["change"] = "alert-triangle",
    ["new"] = "affirm-blip-1",
    ["start"] = "click-melodic-1",
    ["cancel"] = "deny-bass-4",
    ["stop"] = "click-melodic-2",
    ["apply"] = "affirm-melodic-1",
    ["altapply"] = "affirm-techy-1",
    ["reset"] = "alert-flick-alert",
    --["tick"]     = "click-footfall",
    ["error"] = "alert-triangle",
    ["copy"] = "affirm-melodic-3",
    ["paste"] = "affirm-melodic-4"
}

WorldEditor.hasChanged = false

-----------------------------------------------------------------
--  Static Function
-----------------------------------------------------------------
function WorldEditor.OnBuilderOpen()
    print("WorldEditor . OnBuilderOpen()")
    HBBuilder.Builder.grid = 0.1
    HBU.chatOffset = Vector2(360, 120)
    WorldEditor.MoveBuilder(false)
    HBBuilder.Builder.lastOpenedProjectPath = ""
    HBBuilder.Builder.root.transform.position =
        HBBuilder.BuilderUtils.Snap(Camera.main.transform.position, HBBuilder.Builder.grid, nil)

    WorldEditor.RunAllScripts()

    WorldEditor.CreateContentContainer()
    WorldEditor.CreatePersistantToolContainer()
    WorldEditor.CreateUtilityBar()
    WorldEditor.CreateToolBar()
    WorldEditor.CreateBrowserBar()
    WorldEditor.TerrainParent = HBBuilder.Builder.currentAssembly.transform:Find("TERRAIN")
    if not WorldEditor.TerrainParent or Slua.IsNull(WorldEditor.TerrainParent) then
        WorldEditor.TerrainParent = GameObject("TERRAIN")
        WorldEditor.TerrainParent.transform.parent = HBBuilder.Builder.currentAssembly.transform
        WorldEditor.TerrainParent.transform.localPosition = Vector3(0, 0, 0)
    end
    WorldEditor.Settings.rebuildWorld = false
end

function WorldEditor.OnBuilderClose()
    HBU.chatOffset = Vector2(10, 90)

    if WorldEditor.utilityBar then
        WorldEditor.utilityBar:Destroy()
    end
    if WorldEditor.testModeBar then
        WorldEditor.testModeBar:Destroy()
    end
    if WorldEditor.browserBar then
        WorldEditor.browserBar:Destroy()
    end
    if WorldEditor.partsBar then
        WorldEditor.partsBar:Destroy()
    end
    if WorldEditor.toolBar then
        WorldEditor.toolBar:Destroy()
    end
    if WorldEditor.partPreview and not Slua.IsNull(WorldEditor.partPreview) then
        GameObject.Destroy(WorldEditor.partPreview)
    end
    if WorldEditor.contentContainer and not Slua.IsNull(WorldEditor.contentContainer) then
        GameObject.Destroy(WorldEditor.contentContainer)
    end
    if WorldEditor.persistantToolContainer and not Slua.IsNull(WorldEditor.persistantToolContainer) then
        GameObject.Destroy(WorldEditor.persistantToolContainer)
    end
    if WorldEditor.Scripts then
        for i, v in ipairs(WorldEditor.Scripts) do
            if v and v.gameObject then
                GameObject.Destroy(v.gameObject)
            end
        end
    end
    if WorldEditor.rightClickOptionsPanel and not Slua.IsNull(WorldEditor.rightClickOptionsPanel) then
        GameObject.Destroy(WorldEditor.rightClickOptionsPanel)
    end
    if WorldEditor.TerrainParent then
        GameObject.Destroy(WorldEditor.TerrainParent)
    end
end

function WorldEditor.GetBuilderOpenLocation()
    return Camera.main.transform.position
end

function WorldEditor.CreateUtilityBar()
    WorldEditor.utilityBar =
        BUI.Bar:Create(
        {
            barHeight = 50,
            layout1 = {"name", "UtilityBar", "order", 0},
            layout2 = {"spacing", 1, "align", TextAnchor.MiddleLeft, "expand", "control"}
        },
        HBBuilder.Builder.builderUI.transform:Find("Vertical").gameObject
    )
    WorldEditor.utilityBar:SetButtonsAndSpaces(WorldEditor.UtilityButtons, WorldEditor.UtilitySpaces)
end

function WorldEditor.CreateContentContainer()
    WorldEditor.contentContainer =
        BUI.Vertical(
        HBBuilder.Builder.builderUI.transform:Find("Vertical").gameObject,
        "name",
        "ContentContainer",
        "order",
        5,
        "min",
        Vector2(0, 50),
        "align",
        TextAnchor.MiddleLeft,
        "expand",
        "control",
        "spacing",
        5,
        "padding",
        Vector4(5, 5, 5, 5)
    )
    WorldEditor.contentContainer:AddComponent("UnityEngine.UI.Image")
    BUI.Apply(WorldEditor.contentContainer, "color", BUI.colors.black)
end

function WorldEditor.CreatePersistantToolContainer()
    WorldEditor.persistantToolContainer =
        BUI.Vertical(
        HBBuilder.Builder.builderUI.transform:Find("Vertical/Horizontal").gameObject,
        "name",
        "PersistantToolContainer",
        "order",
        0,
        "padding",
        Vector4(10, 10, 0, 10),
        "spacing",
        10,
        "expand",
        "control",
        "ignorelayout",
        true
    )
end

function WorldEditor.CreateBrowserBar()
    print("WorldEditor . CreateBrowserBar()")
    WorldEditor.browserBar =
        BUI.BrowserBar:Create(
        {
            rootPaths = {
                HBU.GetLuaFolder() .. "/ModLua/WorldEditor/Spawnables/Default",
                HBU.GetLuaFolder() .. "/ModLua/WorldEditor/Spawnables/Custom",
                HBU.GetLuaFolder() .. "/ModLua/WorldEditor/Spawnables/Imports"
            },
            onClickFile = function(button, path)
                WorldEditor.SpawnPart(path)
            end,
            onHoverFile = nil,
            onBack = function(path)
                HBBuilder.Builder.TriggerCallback(HBBuilder.BuilderCallback.RefreshUIIndicators)
            end,
            onOpenDirectory = function(path)
                HBBuilder.Builder.TriggerCallback(HBBuilder.BuilderCallback.RefreshUIIndicators)
            end,
            onSearch = function()
                HBBuilder.Builder.TriggerCallback(HBBuilder.BuilderCallback.RefreshUIIndicators)
            end,
            --extension = "*.obj",
            layout1 = {"order", 0, "flexible", Vector2(1, 0), "color", Color(0, 0, 0, 0)},
            barConfig = {layout1 = {"color", BUI.colors.black}}
        },
        WorldEditor.contentContainer or HBBuilder.Builder.builderUI.transform:Find("Vertical").gameObject
    )
end

function WorldEditor.SpawnPartDeprecated(part)
    if not part then
        return
    end

    if HBBuilder.Builder.root and not Slua.IsNull(HBBuilder.Builder.root) then
        local object = HBBuilder.Builder.Instantiate(part)
        object.name = HBU.GetFileNameWithoutExtension(part)
        -- object.transform:SetParent(HBBuilder.Builder.weldContainer.transform)
        object.transform.position = Camera.main.transform.position + (Camera.main.transform.forward * 10)
        object.transform.localRotation = Quaternion.identity
        --[[ if HBBuilder.BuilderCallback.SpawnPart then
        for i, callback in ipairs(HBBuilder.BuilderCallback.SpawnPart) do
        if callback and type(callback) == "function" then
        pcall(callback(object))
        end
        end
        end ]]
        HBBuilder.BuilderUtils.SetLayer(object, 0, true)
        object.transform.parent = HBBuilder.Builder.currentAssembly.bodyContainer.transform
        WorldEditor.Play("new")
        WorldEditor.hasChanged = true
        return object
    end
end

function WorldEditor.SpawnPart(part)
    if not part then
        return
    end

    if HBBuilder.Builder.root and not Slua.IsNull(HBBuilder.Builder.root) then
        local object = HBBuilder.Builder.Spawn(part)
        object.transform.position = Camera.main.transform.position + Camera.main.transform.forward
        object.transform.localRotation = Quaternion.identity

        local partContainer = object:GetComponentInChildren("PartContainer")
        if Slua.IsNull(partContainer) then
            object:AddComponent("PartContainer")
        end

        if Builder.onSpawnPartCallbacks then
            for i, callback in ipairs(Builder.onSpawnPartCallbacks) do
                if callback and type(callback) == "function" then
                    pcall(callback(object))
                end
            end
        end
        return object
    end
end

function WorldEditor.RunAllScripts()
    if WorldEditor.Scripts then
        for i, v in ipairs(WorldEditor.Scripts) do
            WorldEditor.RunScript(v)
        end
    end
end

function WorldEditor.RunScript(v)
    if not v or not v.path then
        return
    end
    if v.official then
        if HBU.FileExists(HBU.GetLuaFolder() .. "/" .. v.path) == false then
            print("WorldEditor: failed to load script @ " .. v.path)
            return
        end
        v.gameObject = GameObject(HBU.GetFileNameWithoutExtension(v.path))
        v.gameObject.transform:SetParent(HBBuilder.Builder.root.transform)
        HBU.AddComponentLua(v.gameObject, v.path)
    else
        print("Unofficial tools not yet supported", v.official, v.path)
    end
end

function WorldEditor.CreateToolBar()
    WorldEditor.toolBar =
        BUI.Bar:Create(
        {
            layout1 = {
                "name",
                "ToolBar",
                "min",
                Vector2(0, 50),
                "order",
                0,
                "flexible",
                Vector2(0.5, 0),
                "color",
                BUI.colors.dark
            },
            layout2 = {"spacing", 1, "align", TextAnchor.MiddleLeft, "expand", "control"}
        },
        WorldEditor.contentContainer or HBBuilder.Builder.builderUI.transform:Find("Vertical").gameObject
    )
end

function WorldEditor.RegisterTool(tool)
    if not WorldEditor.toolBar then
        Debug.LogError("WorldEditor.RegisterTool: toolBar is nil")
        return
    end
    if not tool or not type(tool) == "table" then
        Debug.LogError("WorldEditor.RegisterTool: wrong arg1: tool is nil")
        return
    end
    if not tool.ToolButton then
        Debug.LogError("WorldEditor.RegisterTool: tool needs table:ToolButton in order to register to the toolBar")
        return
    end
    if not tool.ToolButton.func then
        tool.ToolButton.func = function()
            WorldEditor.SelectTool(tool)
        end
    end

    --set this button as selectable
    tool.ToolButton.selectable = true

    --add the button
    WorldEditor.toolBar:AddButton(tool.ToolButton)

    --re-apply order
    WorldEditor.toolBar:ApplyOrder(WorldEditor.ToolOrder)

    --re-aaply spaces
    WorldEditor.toolBar:ApplySpaces(WorldEditor.ToolSpaces)

    --add to tool to Tools table
    if not WorldEditor.Tools then
        WorldEditor.Tools = {}
    end
    if not WorldEditor.Tools[tool.ToolButton.name] then
        WorldEditor.Tools[tool.ToolButton.name] = tool
    end
end

function WorldEditor.UnRegisterTool(tool)
    if not WorldEditor.toolBar then
        Debug.LogError("WorldEditor.UnRegisterTool: toolBar is nil")
        return
    end
    if not tool then
        Debug.LogError("WorldEditor.UnRegisterTool: wrong arg1: tool is nil")
        return
    end
    if not tool.ToolButton then
        Debug.LogError(
            "WorldEditor.UnRegisterTool: tool needs table:ToolButton in order to unregister from the toolBar"
        )
        return
    end

    --remove the button
    WorldEditor.toolBar:RemoveButton(WorldEditor.toolBar:Find(tool.ToolButton.Name))

    --re-apply order
    WorldEditor.toolBar:ApplyOrder(WorldEditor.ToolOrder)

    --remove tool from Tools table
    if not WorldEditor.Tools then
        WorldEditor.Tools = {}
    end
    if WorldEditor.Tools[tool.ToolButton.name] then
        WorldEditor.Tools[tool.ToolButton.name] = false
    end
end

function WorldEditor.New()
    print("WorldEditor . New()")
    HBBuilder.Builder.New()
    WorldEditor.MoveBuilder(false)
    HBBuilder.Builder.lastOpenedProjectPath = ""
    WorldEditor.TerrainParent = HBBuilder.Builder.currentAssembly.transform:Find("TERRAIN")
    if not WorldEditor.TerrainParent or Slua.IsNull(WorldEditor.TerrainParent) then
        WorldEditor.TerrainParent = GameObject("TERRAIN")
        WorldEditor.TerrainParent.transform.parent = HBBuilder.Builder.currentAssembly.transform
        WorldEditor.TerrainParent.transform.localPosition = Vector3(0, 0, 0)
    end
end

function WorldEditor.Open()
    print("WorldEditor . Open()")
    WorldEditor.Loading = true
    local str = HBU.GetLuaFolder() .. "/ModLua/WorldEditor/Saves"
    local path, cancel = HBBuilder.BuilderUtils.OpenFile(str, "hbp", Slua.out, Slua.out)
    if not cancel then
        WorldEditor.New()
        local FolderPath = Application.streamingAssetsPath .. "/MyWorld/Assets/WorldEditor/"
        local pinnedPath = FolderPath .. HBU.GetFileNameWithoutExtension(path) .. ".hbm"
        if HBU.FileExists(pinnedPath) then
            local xml = HBU.XmlElements(HBU.XmlLoad(pinnedPath), "World")
            local pos = Vector3.zero
            for v in Slua.iter(xml) do
                local x = HBU.StringToNumber(v:Attribute(Slua.GetClass("System.Xml.Linq.XName").Get("x")).Value)
                local y = HBU.StringToNumber(v:Attribute(Slua.GetClass("System.Xml.Linq.XName").Get("y")).Value)
                local z = HBU.StringToNumber(v:Attribute(Slua.GetClass("System.Xml.Linq.XName").Get("z")).Value)
                pos = Vector3(x, y, z)
            end
            HBBuilder.Builder.root.transform.position = HBU.GetLocalPosition(pos)
        end

        HBBuilder.Builder.lastOpenedProjectPath = path
        HBBuilder.Builder.UnSerialize(path)
        WorldEditor.TerrainParent = HBBuilder.Builder.currentAssembly.transform:Find("TERRAIN")
        if not WorldEditor.TerrainParent or Slua.IsNull(WorldEditor.TerrainParent) then
            WorldEditor.TerrainParent = GameObject("TERRAIN")
            WorldEditor.TerrainParent.transform.parent = HBBuilder.Builder.currentAssembly.transform
            WorldEditor.TerrainParent.transform.localPosition = Vector3(0, 0, 0)
        end
        WorldEditor.LoadTerrains(path)
    end
    WorldEditor.Loading = false
end

function WorldEditor.Save()
    print("WorldEditor . Save()")
    WorldEditor.Saving = true
    print(HBBuilder.Builder.lastOpenedProjectPath)
    if HBBuilder.Builder.lastOpenedProjectPath ~= "" then
        HBBuilder.Builder.changed = false
        WorldEditor.SaveTerrains(HBBuilder.Builder.lastOpenedProjectPath)
        HBBuilder.BuilderUtils.SetLayer(HBBuilder.Builder.currentAssembly.bodyContainer.gameObject, 0, true)
        HBBuilder.Builder.Serialize(HBBuilder.Builder.lastOpenedProjectPath)
        local pic = Picture.Create(HBBuilder.Builder.currentAssembly.gameObject, 300, 300)
        HBU.SaveTexture2D(
            pic,
            HBU.GetDirectoryName(HBBuilder.Builder.lastOpenedProjectPath) ..
                "/" .. HBU.GetFileNameWithoutExtension(HBBuilder.Builder.lastOpenedProjectPath) .. "_img.png"
        )
        WorldEditor.hasChanged = false
    else
        WorldEditor.SaveAs()
    end
    WorldEditor.Saving = false
end

function WorldEditor.SaveAs()
    print("WorldEditor . SaveAs()")
    WorldEditor.Saving = true
    local str = HBU.GetLuaFolder() .. "/ModLua/WorldEditor/Saves"
    local path, cancel = HBBuilder.BuilderUtils.SaveFile(str, "hbp", Slua.out, Slua.out)
    if not cancel then
        HBBuilder.Builder.lastOpenedProjectPath = path
        HBBuilder.Builder.changed = false
        WorldEditor.SaveTerrains(HBBuilder.Builder.lastOpenedProjectPath)
        HBBuilder.BuilderUtils.SetLayer(HBBuilder.Builder.currentAssembly.bodyContainer.gameObject, 0, true)
        HBBuilder.Builder.Serialize(HBBuilder.Builder.lastOpenedProjectPath)
        local pic = Picture.Create(HBBuilder.Builder.currentAssembly.gameObject, 300, 300)
        HBU.SaveTexture2D(
            pic,
            HBU.GetDirectoryName(HBBuilder.Builder.lastOpenedProjectPath) ..
                "/" .. HBU.GetFileNameWithoutExtension(HBBuilder.Builder.lastOpenedProjectPath) .. "_img.png"
        )
        WorldEditor.hasChanged = false
    end
    WorldEditor.Saving = false
end

function WorldEditor.Pin()
    print("WorldEditor . Pin()")
    WorldEditor.Pinning = true
    local anwser =
        HBU.QuestionBox(
        "Would you like to delete all old pinned object?",
        "Delete Old Pinned",
        Slua.GetClass("System.Windows.Forms.MessageBoxButtons").YesNoCancel
    )
    if anwser ~= "Cancel" then
        local FolderPath = Application.streamingAssetsPath .. "/MyWorld/Assets/WorldEditor/"
        local path = FolderPath .. HBU.GetFileNameWithoutExtension(HBBuilder.Builder.lastOpenedProjectPath) .. ".hbp"
        if anwser == "Yes" and HBU.FileExists(path) then
            print("Unpin", path)
            HBU.UnPinAsset(path)
        end
        WorldEditor.Save()
        HBU.SaveAsset(path, "WorldProp", WorldEditor.ExportedObject, false)
        HBU.PinAsset(path, WorldEditor.ExportedObject)

        WorldEditor.Settings.rebuildWorld = true
    end
    WorldEditor.Pinning = false
end

function WorldEditor.UpdatePin()
    print("WorldEditor . UpdatePin()")
    WorldEditor.Pinning = true
    WorldEditor.Save()
    local FolderPath = Application.streamingAssetsPath .. "/MyWorld/Assets/WorldEditor/"
    local path = FolderPath .. HBU.GetFileNameWithoutExtension(HBBuilder.Builder.lastOpenedProjectPath) .. ".hbp"
    HBU.SaveAsset(path, "WorldProp", WorldEditor.ExportedObject, false)
    WorldEditor.Pinning = false
end

function WorldEditor.UnPin()
    print("WorldEditor . UnPin()")
    local FolderPath = Application.streamingAssetsPath .. "/MyWorld/Assets/WorldEditor/"
    local path, cancel = HBBuilder.BuilderUtils.OpenFile(FolderPath, "hbp", Slua.out, Slua.out)
    if not cancel and path ~= "" then
        local anwser =
            HBU.QuestionBox(
            "This will remove all copies of : ( " ..
                HBU.GetFileNameWithoutExtension(path) .. " ) from the world. Do you want to continue?",
            "UnPin",
            Slua.GetClass("System.Windows.Forms.MessageBoxButtons").YesNoCancel
        )
        if anwser == "Cancel" or anwser == "No" then
            return
        end
        HBU.UnPinAsset(path)
        HBU.DeleteAsset(HBU.GetDirectoryName(path) .. "/" .. HBU.GetFileNameWithoutExtension(path) .. ".hbm")
        print(path)
        WorldEditor.ReloadWorld()
    end
end

function WorldEditor.Play(name)
    if not name then
        return
    end
    if not WorldEditor.AudioConfig then
        return
    end
    if not WorldEditor.AudioConfig[name] then
        return
    end
    Audio:Play(WorldEditor.AudioConfig[name], true, true)
end

function WorldEditor.SelectTool(tool)
    if not WorldEditor.toolBar then
        Debug.LogError("WorldEditor.UnRegisterTool: toolBar is nil")
        return
    end

    --unselect all other tools
    for i, v in pairs(WorldEditor.Tools) do
        if v and v.enabled then
            v.enabled = false
            if v.OnDisableTool then
                v:OnDisableTool()
            end
            WorldEditor.toolBar:SetSelected(v.ToolButton, false)
        end
    end

    if not tool then
        return
    end
    if not tool.ToolButton then
        Debug.LogError("WorldEditor.SelectTool: tool needs table:ToolButton in order to select from the toolBar")
        return
    end

    --select this tool
    tool.enabled = true
    WorldEditor.toolBar:SetSelected(tool.ToolButton, true)
    if tool.OnEnableTool then
        tool:OnEnableTool()
    end
    --select tool in inspector
    if Inspector then
        Inspector:SetTarget(tool.Inspector)
    end
end

function WorldEditor.MoveBuilder(bool)
    if not Slua.IsNull(HBBuilder.Builder.root) then
        --[[ Old shit
        local camPrePos = Camera.main.transform.parent.position
        HBBuilder.Builder.root.transform.position = WorldEditor.GetBuilderOpenLocation()
        Camera.main.transform.parent.position = camPrePos
        ]]
        if bool ~= nil then
            WorldEditor.Settings.MoveAll = bool
        else
            WorldEditor.Settings.MoveAll = not WorldEditor.Settings.MoveAll
        end
        if not WorldEditor.Settings.MoveAll then
            HBBuilder.Builder.StopMoveAxis()
            HBBuilder.Builder.StopRotationAxis()
        end
    end
end

function WorldEditor.GetAll()
    local ret = {}
    for part in Slua.iter(HBBuilder.Builder.currentAssembly.bodyContainer.transform) do
        if not string.find(part.name, "Fixed") then
            table.insert(ret, part.gameObject)
        end
    end
    return ret
end

function WorldEditor.GetAllProp()
    local ret = {}
    for part in Slua.iter(HBBuilder.Builder.currentAssembly.bodyContainer.transform) do
        local terrain = part.gameObject:GetComponent("Terrain")
        if not terrain then
            table.insert(ret, part.gameObject)
        end
    end
    return ret
end

function WorldEditor.Convert()
    local ImportPath = HBU.GetLuaFolder() .. "/ModLua/WorldEditor/Imports/"
    if HBU.DirectoryExists(ImportPath) then
        local allObj = HBU.GetFiles(ImportPath, "*.obj")
        local i = 1
        for obj in Slua.iter(allObj) do
            local name = HBU.GetFileNameWithoutExtension(obj)
            local object = GameObject(name)
            local filter = object:AddComponent("UnityEngine.MeshFilter")
            local renderer = object:AddComponent("UnityEngine.MeshRenderer")
            local collider = object:AddComponent("UnityEngine.MeshCollider")
            local partContainer = object:AddComponent("PartContainer")

            print(i .. "/" .. #allObj .. " : " .. name)
            i = i + 1

            filter.mesh = ObjImporter.Import(obj)
            collider.sharedMesh = filter.mesh
            renderer.materials = {Resources.Load("1HomebrewMaterials/colorScheme")}
            object.gameObject.layer = 0
            object.transform.localScale = Vector3(-1, 1, 1)
            local saveToPath = HBU.GetLuaFolder() .. "/ModLua/WorldEditor/Spawnables/Imports/" .. name .. ".hbp"
            local pic = Picture.Create(object, 256, 256, Color(0, 0, 0, 000.1))
            HBU.SaveAsset(saveToPath, "WorldProp", object, true)
            GameObject.DestroyImmediate(object, true)
            HBU.SaveTexture2D(
                pic,
                HBU.GetDirectoryName(saveToPath) .. "/" .. HBU.GetFileNameWithoutExtension(saveToPath) .. "_img.png"
            )
        end
    else
        HBU.CreateDirectory(ImportPath)
    end
end

function WorldEditor.GiveImages()
    local ImportPath = HBU.GetLuaFolder() .. "/ModLua/WorldEditor/Spawnables/Imports/"
    if HBU.DirectoryExists(ImportPath) then
        local allObj = HBU.GetFiles(ImportPath, "*.hbp")
        local i = 1
        for obj in Slua.iter(allObj) do
            local name = HBU.GetFileNameWithoutExtension(obj)
            print(i .. "/" .. #allObj .. " : " .. name)
            print("         Spawn : " .. name)
            local object = HBU.InstantiateAsset(obj)
            i = i + 1
            print("         Picture : " .. name)
            local pic = Picture.Create(object.gameObject, 256, 256, Color(0, 0, 0, 000.1))
            GameObject.Destroy(object)
            print("         Save : " .. name)
            HBU.SaveTexture2D(
                pic,
                HBU.GetLuaFolder() .. "/ModLua/WorldEditor/Spawnables/Imports/" .. name .. "_img.png"
            )
            print("         Done : " .. name)
        end
    else
        HBU.CreateDirectory(ImportPath)
    end
end

function WorldEditor.GetAllTerrain()
    local ret = {}
    if not WorldEditor.TerrainParent then
        return ret
    end
    for part in Slua.iter(WorldEditor.TerrainParent.transform) do
        local terrain = part.gameObject:GetComponent("Terrain")
        if terrain and not Slua.IsNull(terrain) then
            table.insert(ret, terrain)
        end
    end
    echo(ret)
    return ret
end

function WorldEditor.SaveTerrains(path)
    print("WorldEditor . SaveTerrains()")
    local folder = HBU.GetDirectoryName(path) .. "/" .. HBU.GetFileNameWithoutExtension(path)
    if HBU.DirectoryExists(folder) then
        HBU.DeleteDirectory(folder, folder)
    end
    local terrainTable = {}
    for k, terrain in pairs(WorldEditor.GetAllTerrain()) do
        table.insert(terrainTable, WorldEditor.SaveTerrain(path, terrain))
    end

    string2file(
        "local " .. dumptable(terrainTable, "TerrainData") .. " return TerrainData",
        HBU.GetDirectoryName(path) .. "/" .. HBU.GetFileNameWithoutExtension(path) .. ".wtn",
        "w"
    )
end

function WorldEditor.SaveTerrain(path, terrain)
    local mainPath = HBU.GetDirectoryName(path) .. "/" .. HBU.GetFileNameWithoutExtension(path) .. "/" .. terrain.name

    local RAWPath = mainPath .. "/RAW" .. ".raw"
    local ColourMapPath = mainPath .. "/ColourMap" .. ".png"
    local NormalMapPath = mainPath .. "/NormalMap" .. ".png"
    local SplatMapPath = mainPath .. "/SplatMap" .. ".png"

    if not HBU.DirectoryExists(mainPath) then
        HBU.CreateDirectory(mainPath)
    end

    --TerrainUtils.TerrainToRaw32(terrain, RAWPath)
    Terrains.TerrainToRaw16(terrain, string.gsub(RAWPath, ".raw", ""))
    TerrainUtils.TerrainToColor(terrain, ColourMapPath)
    TerrainUtils.TerrainToNormalMap(terrain, NormalMapPath)
    TerrainUtils.TerrainToSplat(terrain, SplatMapPath)
    local worldPosition = HBU.GetWorldPosition(terrain.transform)
    local terrainTable = {
        RAW = string.gsub(RAWPath, HBU.GetLuaFolder() .. "/ModLua/WorldEditor/", ""),
        ColourMap = string.gsub(ColourMapPath, HBU.GetLuaFolder() .. "/ModLua/WorldEditor/", ""),
        NormalMap = string.gsub(NormalMapPath, HBU.GetLuaFolder() .. "/ModLua/WorldEditor/", ""),
        SplatMap = string.gsub(SplatMapPath, HBU.GetLuaFolder() .. "/ModLua/WorldEditor/", ""),
        Size = (terrain.terrainData.size.x) ..
            " " .. (terrain.terrainData.size.y) .. " " .. (terrain.terrainData.size.z),
        Resolution = terrain.terrainData.heightmapResolution,
        Position = worldPosition.x .. " " .. worldPosition.y .. " " .. worldPosition.z,
        LocalPosition = terrain.transform.localPosition.x ..
            " " .. terrain.transform.localPosition.y .. " " .. terrain.transform.localPosition.z,
        Name = terrain.name
    }
    return terrainTable
end

function WorldEditor.LoadTerrains(f)
    print("WorldEditor . LoadTerrains()")
    WorldEditor.TerrainParent = HBBuilder.Builder.currentAssembly.transform:Find("TERRAIN")
    if not WorldEditor.TerrainParent or Slua.IsNull(WorldEditor.TerrainParent) then
        WorldEditor.TerrainParent = GameObject("TERRAIN")
        WorldEditor.TerrainParent.transform.parent = HBBuilder.Builder.currentAssembly.transform
        WorldEditor.TerrainParent.transform.localPosition = Vector3(0, 0, 0)
    end
    local path = HBU.GetDirectoryName(f) .. "/" .. HBU.GetFileNameWithoutExtension(f) .. ".wtn"
    if not HBU.FileExists(path) then
        print(path, "Does Not Exist")
        return
    end
    print(path)
    local terrainData = dofile(path)
    echo(terrainData)
    for k, data in pairs(terrainData) do
        ter = Terrains.Find("flat").Clone().gameObject:GetComponent("Terrain")
        ter.transform.parent = WorldEditor.TerrainParent.transform
        ter.transform.localPosition = parseVec3(data["LocalPosition"])
        ter.name = data["Name"]

        ter.terrainData.heightmapResolution = data["Resolution"]
        ter.terrainData.size = parseVec3(data["Size"])

        base = HBU.GetLuaFolder() .. "/ModLua/WorldEditor/"
        Terrains.Raw16ToTerrain(base .. data["RAW"], ter)
        TerrainUtils.ColorToTerrain(base .. data["ColourMap"], ter)
        TerrainUtils.SplatToTerrain(base .. data["SplatMap"], ter)
        TerrainUtils.NormalMapToTerrain(base .. data["NormalMap"], ter)
    end
end

function WorldEditor.LoadPinnedTerrains()
    local allFiles = HBU.GetFiles(HBU.GetWorldStreamerPath() .. "/Assets/WorldEditor", "*.hbp")

    for pinnedFile in Slua.iter(allFiles) do
        local terrainFile =
            HBU.GetLuaFolder() .. "/ModLua/WorldEditor/Saves/" .. HBU.GetFileNameWithoutExtension(pinnedFile) .. ".wtn"
        if HBU.FileExists(terrainFile) then
            WorldEditor.LoadPinnedTerrain(terrainFile)
        end
    end
end

function WorldEditor.LoadPinnedTerrain(path)
    if not HBU.FileExists(path) then
        print(path, "Does Not Exist")
        return
    end
    local terrainData = dofile(path)
    echo(terrainData)
    for k, data in pairs(terrainData) do
        ter = Terrains.Find("flat").Clone().gameObject:GetComponent("Terrain")
        ter.transform.position = HBU.GetLocalPosition(parseVec3(data["Position"]))
        ter.name = data["Name"]

        ter.terrainData.heightmapResolution = data["Resolution"]
        ter.terrainData.size = parseVec3(data["Size"])

        base = HBU.GetLuaFolder() .. "/ModLua/WorldEditor/"
        Terrains.Raw16ToTerrain(base .. data["RAW"], ter)
        TerrainUtils.ColorToTerrain(base .. data["ColourMap"], ter)
        TerrainUtils.SplatToTerrain(base .. data["SplatMap"], ter)
        TerrainUtils.NormalMapToTerrain(base .. data["NormalMap"], ter)
        HBBuilder.BuilderUtils.SetLayer(ter.gameObject, 11, true)
        table.insert(WorldEditor.Settings.CustomTerrain, ter)
    end
end

function WorldEditor.ReloadWorld()
    for k, ter in pairs(WorldEditor.Settings.CustomTerrain) do
        GameObject.Destroy(ter.gameObject)
    end

    HBU.RebuildWorldSectors()
    WorldEditor.LoadPinnedTerrains()
    WorldEditor.Settings.rebuildWorld = false
end

function WorldEditor.AddTool(toolPath)
    if WorldEditor.Scripts then
        table.insert(WorldEditor.Scripts, {official = false, path = toolPath})
    end
end

function WorldEditor.RemoveTool(toolPath)
    if WorldEditor.Scripts then
        for i, v in ipairs(WorldEditor.Scripts) do
            if not v.official and v.path == toolPath then
                table.remove(WorldEditor.Scripts, i)
            end
        end
    end
end

function WorldEditor.SetUpIcons()
    HBU.CreateDirectory(HBU.GetOfficialLuaFolder() .. "/icons/worldeditor")
    HBU.CopyDirectory(
        HBU.GetLuaFolder() .. "/ModLua/WorldEditor/Icons",
        HBU.GetOfficialLuaFolder() .. "/icons/worldeditor"
    )
end

function WorldEditor.isLoading()
    return WorldEditor.Loading
end

function WorldEditor.isSaving()
    return WorldEditor.Saving
end

function WorldEditor.isPinning()
    return WorldEditor.Pinning
end
-----------------------------------------------------------------
--  Self Function
-----------------------------------------------------------------

-----------------------------------------------------------------
--  Unity calls
-----------------------------------------------------------------
function WorldEditor:Awake()
    print("WorldEditor : Awake()")
    HBU.CreateDirectory(Application.streamingAssetsPath .. "/MyWorld/Assets/WorldEditor")
    WorldEditor.SetUpIcons()
end

function WorldEditor:Start()
    print("WorldEditor : Start()")
    GConsole.AddCommand(
        "WorldEditor",
        "Starts the World Editor",
        function()
            if not HBBuilder.Builder.isOpen then
                HBBuilder.Builder.OpenBuilder(WorldEditor.builderType, "")
            end
        end
    )
    GConsole.AddCommand(
        "WE_Convert",
        "",
        function()
            WorldEditor.Convert()
        end
    )
    WorldEditor.LoadPinnedTerrains()
end

function WorldEditor:Update()
    if not self.isOpen then
        --open builder
        if HBBuilder.Builder.builderType == self.builderType and HBBuilder.Builder.isOpen then
            self.isOpen = true
            print("OPEN WORLD EDITOR")
            WorldEditor.OnBuilderOpen()
        end
    else
        if WorldEditor.Settings.MoveAll then
            HBBuilder.Builder.StartMoveAxis(
                HBBuilder.Builder.currentAssembly.transform.position,
                HBBuilder.Builder.currentAssembly.transform.rotation,
                {HBBuilder.Builder.currentAssembly.gameObject},
                HBBuilder.Builder.root,
                true
            )
            HBBuilder.Builder.StartRotationAxis(
                HBBuilder.Builder.currentAssembly.transform.position,
                HBBuilder.Builder.currentAssembly.transform.rotation,
                {HBBuilder.Builder.currentAssembly.gameObject},
                HBBuilder.Builder.root,
                true
            )
        end

        if not HBBuilder.Builder.isOpen or not HBBuilder.Builder.builderType == self.builderType and self.isOpen then
            WorldEditor.OnBuilderClose()
            print("CLOSE WORLD EDITOR")
            self.isOpen = false
        end
    end
end

function WorldEditor:OnDestroy()
    print("WorldEditor : OnDestroy()")
    if not self then
        return
    end
    if self.utilityBar then
        self.utilityBar:Destroy()
    end
    if self.testModeBar then
        self.testModeBar:Destroy()
    end
    if self.browserBar then
        self.browserBar:Destroy()
    end
    if self.partsBar then
        self.partsBar:Destroy()
    end
    if self.toolBar then
        self.toolBar:Destroy()
    end
    if self.partPreview and not Slua.IsNull(self.partPreview) then
        GameObject.Destroy(self.partPreview)
    end
    if self.contentContainer and not Slua.IsNull(self.contentContainer) then
        GameObject.Destroy(self.contentContainer)
    end
    if self.persistantToolContainer and not Slua.IsNull(self.persistantToolContainer) then
        GameObject.Destroy(self.persistantToolContainer)
    end
    if self.Scripts then
        for i, v in ipairs(self.Scripts) do
            if v and v.gameObject then
                GameObject.Destroy(v.gameObject)
            end
        end
    end
    if self.rightClickOptionsPanel and not Slua.IsNull(self.rightClickOptionsPanel) then
        GameObject.Destroy(self.rightClickOptionsPanel)
    end
    if WorldEditor.Settings.CustomTerrain then
        for k, ter in pairs(WorldEditor.Settings.CustomTerrain) do
            GameObject.Destroy(ter)
        end
    end

    HBU.chatOffset = Vector2(10, 90)
end

-----------------------------------------------------------------
--  Util Functions
-----------------------------------------------------------------
function startsWith(str, start)
    return str:sub(1, start:len()) == start
end

function parseVec3(str)
    a = {}
    string.gsub(
        str,
        "%S+",
        function(s)
            table.insert(a, tonumber(s))
        end
    )
    return Vector3(a[1], a[2], a[3])
end

function parseVec2(str)
    a = {}
    string.gsub(
        str,
        "%S+",
        function(s)
            table.insert(a, tonumber(s))
        end
    )
    return Vector2(a[1], a[2])
end

function TableHasValue(table, value)
    for k, v in pairs(table) do
        if value == v then
            return true
        end
    end
    return false
end

function GetTableValue(tab, val)
    for index, value in ipairs(tab) do
        if string.find(value.name, val) then
            return value
        end
    end

    return nil
end

return WorldEditor
