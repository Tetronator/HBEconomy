Inspector = {}

--converts c# PropertyType class to uiType name
Inspector.PropertyTypeConversion = {
  [1] = "boolProperty",
  [2] = "intProperty",
  [3] = "floatProperty",
  [4] = "stringProperty",
  [5] = "stringProperty",
  [6] = "stringProperty",
  [7] = "dialogProperty",
  [8] = "sliderProperty",
  [9] = "inputProperty",
  [10] = "outputProperty",
  [11] = "buttonProperty",
  [12] = "enumProperty",
  [13] = "keyProperty",
  [14] = "enumProperty"
}

function Inspector:OnDestroy()
  --if self.ui and not Slua.IsNull(self.ui) then GameObject.Destroy(self.ui) end
  if self.wizzard then
    self.wizzard:Destroy()
  end
end

function Inspector:SetTarget(target)
  --store last target
  self.lastTarget = target
  --refresh( will use last target)
  self:Refresh()
  --refresh UI indicators
  HBBuilder.Builder.TriggerCallback(HBBuilder.BuilderCallback.RefreshUIIndicators)
  --inspector target changed
  HBBuilder.Builder.TriggerCallback(HBBuilder.BuilderCallback.InspectorTargetChanged)
end

function Inspector:Refresh()
  if not self then
    return
  end
  --get wizzard config from target
  self.wizzardConfig = self:GetWizzardConfigFromTarget(self.lastTarget)
  --handle wizzard UI
  self:CreateProperties(self.wizzardConfig)
end

function Inspector:CreateProperties(config)
  --creates / updates the wizzard ui
  --destroy wizzard if no config
  local panelColor1 = Color(BUI.colors.black.r, BUI.colors.black.g, BUI.colors.black.b, 0.98)
  local panelColor2 = Color(0, 0, 0, 0)
  local propertyColor1 = Color(BUI.colors.dark.r, BUI.colors.dark.g, BUI.colors.dark.b, 0.5)
  local propertyColor2 = Color(BUI.colors.dark.r, BUI.colors.dark.g, BUI.colors.dark.b, 0)
  local headerPropertyColor = Color.Lerp(BUI.colors.normal, BUI.colors.altColor, 0.50)

  if config == nil or not type(config) == "table" or #config == 0 then
    if self.wizzard then
      self.wizzard:Destroy()
      self.wizzard = false
    end
    return
  end

  if not self.wizzard then
    --create wizzard

    self.wizzard =
      BUI.Wizzard:Create(
      {
        layout1 = {"min", Vector2(330, 0), "color", panelColor1},
        layout2 = {"color", panelColor2},
        groupLayout = {"color", panelColor2}
      },
      HBBuilder.Builder.builderUI.transform:Find("Vertical/Horizontal").gameObject
    )
  else
    --clear wizzard
    self.wizzard:ClearProperties()
  end

  --setup flip flop colors
  local col = propertyColor1 -- local col1 = Color(0,0,0,0); local col2 = Color(BUI.colors.dark.r,BUI.colors.dark.g,BUI.colors.dark.b,0.2); local col3 = Color.Lerp(BUI.colors.normal,BUI.colors.altColor,0.50)

  --populate wizzard properties
  if config then
    for i, propertyConfig in ipairs(config) do
      --apply color to layout
      if propertyConfig.uiType == "headerProperty" then
        if not propertyConfig.layout then
          propertyConfig.layout = {}
        end
        table.insert(propertyConfig.layout, "color")
        table.insert(propertyConfig.layout, headerPropertyColor)
      else
        --flip flop color
        if i % 2 == 1 then
          col = propertyColor1
        else
          col = propertyColor2
        end

        if not propertyConfig.layout then
          propertyConfig.layout = {}
        end
        table.insert(propertyConfig.layout, "color")
        table.insert(propertyConfig.layout, col)
      end

      --add the property field
      self.wizzard:AddProperty(propertyConfig)
    end
  end

  --update folding
  self.wizzard:UpdateFold()
end

function Inspector:GetPartContainerPropertiesSumName(partContainer)
  if not self then
    return
  end
  if not partContainer or Slua.IsNull(partContainer) then
    return
  end
  local sumName = ""
  for part in Slua.iter(partContainer.parts) do
    if not Slua.IsNull(part.properties) and #iter(part.properties) > 0 then
      sumName = sumName .. part:GetPropertiesSumName()
    end
  end
  return sumName
end

function Inspector:GetWizzardConfigFromTarget(target)
  if not target then
    return
  end

  ------------------------------------------------
  --if target is table asume that this is the wizzard config
  ------------------------------------------------
  if type(target) == "table" then
    return target
  end

  ------------------------------------------------

  ------------------------------------------------
  --if target is UnityEngine.GameObject[] then convert to wizzard config
  ------------------------------------------------
  if type(target) == "userdata" and HBU.GetSystemType(target) == "UnityEngine.GameObject[]" then
    --init vars
    local ret = {}
    local groupedParts = {}

    ------------------------------------------------
    --build list of grouped parts
    ------------------------------------------------

    local partGroup = {}
    local sumNameCheck = false
    local canMultiEdit = true
    local gotPart = false
    local partName = "Inspector"

    for selected in Slua.iter(target) do
      if selected and not Slua.IsNull(selected:GetComponent("PartContainer")) then
        local partContainer = selected:GetComponent("PartContainer")

        --get unique name based on proeprties ( if property names and part name match then this name will be thesame )
        local sumName = self:GetPartContainerPropertiesSumName(partContainer)

        --set first sumName
        if not sumNameCheck then
          sumNameCheck = sumName
        end

        --if this part does not conform to sumNameCheck then cant set canMultiEdit to false and break
        if sumName ~= sumNameCheck then
          canMultiEdit = false
          break
        end

        --if parts conforms to sumNameCheck then add them to the list
        for part in Slua.iter(partContainer.parts) do
          if not Slua.IsNull(part.properties) and #iter(part.properties) > 0 then
            local haveInspectorWortyProperties = false
            for property in Slua.iter(part.properties) do
              if property and property.hidden == false then
                haveInspectorWortyProperties = true
              end
            end
            if haveInspectorWortyProperties then
              local propertySumName = part:GetPropertiesSumName()
              if not partGroup[propertySumName] then
                partGroup[propertySumName] = {}
              end
              table.insert(partGroup[propertySumName], part)
              gotPart = true
              partName = partContainer.gameObject.name
            end
          end
        end
      end
    end --end

    --dont go further if we dont have any parts in our group
    if not gotPart then
      return {}
    end

    ------------------------------------------------

    ------------------------------------------------
    --if we cantmulti edit, then add text property
    ------------------------------------------------

    if not canMultiEdit then
      local item = {
        name = "MultiEditFail",
        uiType = "text",
        layout = {
          "text",
          "Can't multi-edit unidentical parts, please select individual or identical parts.",
          "min",
          Vector2(0, 30),
          "textalign",
          TextAnchor.MiddleCenter
        }
      }
      table.insert(ret, item)
      return ret
    end

    ------------------------------------------------

    ------------------------------------------------
    --convert part group properties to full property ui config
    ------------------------------------------------

    --create header item
    local headerItem = {
      name = partName,
      tooltip = "Part Proprties",
      uiType = "headerProperty",
      layout = {"min", Vector2(0, 30)}
    }
    table.insert(ret, headerItem)

    --> foreach part in parts group
    for propertySumName, parts in pairs(partGroup) do
      local part = parts[1]
      --local part = partGroup[1]

      --> foreach property of the first part in this group
      for property in Slua.iter(part.properties) do
        --ignore hidden properties
        if property and property.hidden == false then
          ------------------------------------------------
          --conver property to property ui config
          ------------------------------------------------

          local groupID = part.gameObject.name
          --"properties"
          --if property.type == 13 then groupID = "Controls" end
          --if property.isInput    then groupID = "Inputs"   end
          --if property.isOutput   then groupID = "Outputs"  end

          local item = {
            name = property.descriptiveName,
            tooltip = property.descriptiveName,
            uiType = self.PropertyTypeConversion[property.type],
            minValue = tonumber(property.minValue) or 0,
            maxValue = tonumber(property.maxValue) or 0,
            options = iter(property:GetOptions()),
            groupID = groupID,
            matchingValue = self:GetPropertyMatchingValue(parts, property.pname),
            --setup callback when it asks value ( return the property value of first part )
            value = function()
              return self:PropertyValueConversion(property, "tovalue")
            end,
            --setup callback when we change value ( apply value on all parts in this group )
            func = function(v)
              --foreach part >>
              for i, gpart in ipairs(parts) do
                if gpart and not Slua.IsNull(gpart) then
                  --property in part that matches this property
                  for prop in Slua.iter(gpart.properties) do
                    if prop.pname == property.pname then
                      prop.value = self:PropertyValueConversion(prop, "tostring", v)
                    end
                  end

                  --read from properties
                  gpart:OnReadFromPropertiesNew()
                end
              end
            end
          }

          ------------------------------------------------

          ------------------------------------------------
          --setup array behaviour
          ------------------------------------------------

          self:SetupArrayBehaviour(part, property, parts, item)

          ------------------------------------------------

          --add to table
          table.insert(ret, item)
        end
      end
    end

    ------------------------------------------------

    return ret
  end

  if type(target) == "userdata" and HBU.GetSystemType(target) == "Part[]" then
    --init vars
    local ret = {}
    local groupedParts = {}

    ------------------------------------------------
    --build list of grouped parts
    ------------------------------------------------

    local partGroup = {}
    local sumNameCheck = false
    local canMultiEdit = true
    local gotPart = false
    local partName = "Inspector"
    local firstPropertySumName = false

    for part in Slua.iter(target) do
      --if parts conforms to sumNameCheck then add them to the list
      if part and not Slua.IsNull(part) and not Slua.IsNull(part.properties) and #iter(part.properties) > 0 then
        local haveInspectorWortyProperties = false
        for property in Slua.iter(part.properties) do
          if property and property.hidden == false then
            haveInspectorWortyProperties = true
          end
        end
        if haveInspectorWortyProperties then
          local propertySumName = part:GetPropertiesSumName()
          if not firstPropertySumName then
            firstPropertySumName = propertySumName
          end
          if propertySumName ~= firstPropertySumName then
            canMultiEdit = false
            break
          end
          if not partGroup[propertySumName] then
            partGroup[propertySumName] = {}
          end
          table.insert(partGroup[propertySumName], part)
          gotPart = true
          if not Slua.IsNull(part.gameObject:GetComponentInParent("PartContainer")) then
            partName = part.gameObject:GetComponentInParent("PartContainer").gameObject.name
          end
        end
      end
    end

    --dont go further if we dont have any parts in our group
    if not gotPart then
      return {}
    end

    ------------------------------------------------

    ------------------------------------------------
    --if we cantmulti edit, then add text property
    ------------------------------------------------

    if not canMultiEdit then
      local item = {
        name = "MultiEditFail",
        --info = "can not multi edit, refine your selection",
        uiType = "text",
        layout = {
          "text",
          "can not multi edit, refine your selection",
          "min",
          Vector2(0, 30),
          "textalign",
          TextAnchor.MiddleCenter
        }
      }
      table.insert(ret, item)
      return ret
    end

    ------------------------------------------------

    ------------------------------------------------
    --convert part group properties to full property ui config
    ------------------------------------------------

    --create header item
    local headerItem = {
      name = partName,
      tooltip = "Part Proprties",
      uiType = "headerProperty",
      layout = {"min", Vector2(0, 30)}
    }
    table.insert(ret, headerItem)

    --> foreach part in parts group
    for propertySumName, parts in pairs(partGroup) do
      local part = parts[1]

      --> foreach property of the first part in this group
      for property in Slua.iter(part.properties) do
        --ignore hidden properties
        if property and property.hidden == false then
          ------------------------------------------------
          --conver property to property ui config
          ------------------------------------------------

          local groupID = "properties"
          if property.type == 13 then
            groupID = "Controls"
          end
          if property.isInput then
            groupID = "Inputs"
          end
          if property.isOutput then
            groupID = "Outputs"
          end

          local item = {
            name = property.descriptiveName,
            tooltip = property.descriptiveName,
            uiType = self.PropertyTypeConversion[property.type],
            minValue = tonumber(property.minValue) or 0,
            maxValue = tonumber(property.maxValue) or 0,
            options = iter(property:GetOptions()),
            groupID = groupID,
            matchingValue = self:GetPropertyMatchingValue(parts, property.pname),
            --setup callback when it asks value ( return the property value of first part )
            value = function()
              return self:PropertyValueConversion(property, "tovalue")
            end,
            --setup callback when we change value ( apply value on all parts in this group )
            func = function(v)
              --foreach part >>
              for i, gpart in ipairs(parts) do
                if gpart and not Slua.IsNull(gpart) then
                  --property in part that matches this property
                  for prop in Slua.iter(gpart.properties) do
                    if prop.pname == property.pname then
                      prop.value = self:PropertyValueConversion(prop, "tostring", v)
                    end
                  end

                  --read from properties
                  gpart:OnReadFromPropertiesNew()
                end
              end
            end
          }

          ------------------------------------------------

          ------------------------------------------------
          --setup array behaviour
          ------------------------------------------------

          self:SetupArrayBehaviour(part, property, parts, item)

          ------------------------------------------------

          --add to table
          table.insert(ret, item)
        end
      end
    end
    return ret
  end
end

function Inspector:SetupArrayBehaviour(part, property, parts, item)
  if not self then
    return
  end
  if not part or Slua.IsNull(part) then
    return
  end
  if not property or Slua.IsNull(property) then
    return
  end
  if not parts then
    return
  end
  if not item then
    return
  end

  if property.arrayBehavior then
    --add to config
    item.arrayBehavior = true

    item.arrayRenameFunc = function(config)
      --allocate new name
      local newName = self:AllocateNewName(part, property.pname)
      if newName then
        --foreach part >>
        for i, gpart in ipairs(parts) do
          if gpart and not Slua.IsNull(gpart) then
            theProperty = gpart:GetPropertyByName(property.pname)
            if theProperty and not Slua.IsNull(theProperty) then
              theProperty.pname = newName
              theProperty.descriptiveName = newName
              --if this property is a keybind , then also change keybind name
              if self.PropertyTypeConversion and self.PropertyTypeConversion[theProperty.type] == "keyProperty" then
                local key = HBU.CreateKey(property.value)
                key.curName = newName
                property.value = key:ToDataString()
              end
            end
            --read from properties
            gpart:OnReadFromPropertiesNew()
          end
        end
        --refresh inspector
        self:Refresh()
        --refresh tuner
        if TunerTool and TunerTool.Refresh then
          TunerTool:Refresh()
        end
      end
    end

    item.arrayAddFunc = function(config)
      --allocate new name
      local newName = self:AllocateNewName(part, property.pname)
      if newName then
        --foreach part >>
        for i, gpart in ipairs(parts) do
          if gpart and not Slua.IsNull(gpart) then
            --copy property
            local newProperty = Property(property)
            newProperty.pname = newName
            newProperty.descriptiveName = newProperty.pname
            gpart:AddProperty(newProperty)
            --read from properties
            gpart:OnReadFromPropertiesNew()
          end
        end
        --refresh inspector
        self:Refresh()
        --refresh tuner
        if TunerTool and TunerTool.Refresh then
          TunerTool:Refresh()
        end
      end
    end

    item.arrayRemoveFunc = function(config)
      --ask if sure
      if HBU.QuestionBox("Delete Property", "Delete " .. property.pname .. " property?") then
        --foreach part >>
        for i, gpart in ipairs(parts) do
          if gpart and not Slua.IsNull(gpart) then
            --remove property
            gpart:RemoveProperty(property.pname)
            --read from proeprties
            gpart:OnReadFromPropertiesNew()
          end
        end
        --refresh inspector
        self:Refresh()
        --refresh tuner
        if TunerTool and TunerTool.Refresh then
          TunerTool:Refresh()
        end
      end
    end
  end
end

function Inspector:PropertyValueConversion(property, mode, v)
  if not self then
    Debug.LogError("Inspector:PropertyValueConversion: self is nil")
    return
  end

  local uiType = self.PropertyTypeConversion[property.type]

  --tostring the values
  if mode == "tostring" then
    if uiType == "keyProperty" then
      return v:ToDataString()
    end
    return tostring(v) or ""
  end

  --cast to correct value based on ui type
  if mode == "tovalue" then
    --booleans
    if uiType == "boolProperty" then
      if property.value == "true" then
        return true
      else
        return false
      end
    end

    --numbers
    if uiType == "intProperty" or uiType == "floatProperty" or uiType == "doubleProperty" or uiType == "sliderProperty" then
      return tonumber(property.value) or 0
    end

    --string
    if uiType == "textProperty" or uiType == "dialogeProperty" then
      return property.value or ""
    end

    --key
    if uiType == "keyProperty" then
      return HBU.CreateKey(property.value)
    end
  end

  --return if not converted
  return property.value
end

function Inspector:GetPropertyMatchingValue(parts, propertyName)
  if not self then
    return
  end
  if not parts then
    return
  end
  if not type(parts) == "table" then
    return
  end
  if #parts < 2 then
    return true
  end
  if not propertyName then
    return
  end
  if not type(propertyName) == "string" then
    return
  end
  local vv = parts[1]:GetPropertyByName(propertyName).value
  for i, v in ipairs(parts) do
    local vvv = v:GetPropertyByName(propertyName).value
    if vvv ~= vv then
      return false
    end
  end
  return true
end

function Inspector:AllocateNewName(part, pname)
  if not self then
    return "failed to make new property name"
  end
  if not part or Slua.IsNull(part) then
    return "failed to make new property name"
  end
  if not pname then
    return "failed to make new property name"
  end

  local newName = self:GetName(pname, 1)
  local nameExistsOrInvalid = true

  while (nameExistsOrInvalid) do
    ret, newName = HBU.InputBox("Enter property name", newName, Slua.out)

    if ret == "Cancel" then
      return false
    end

    nameExistsOrInvalid = false
    for property in Slua.iter(part.properties) do
      if property and property.pname == newName then
        nameExistsOrInvalid = true
        break
      end
    end
    if newName == "" then
      nameExistsOrInvalid = true
    end
    if newName ~= self:GetName(newName) then
      nameExistsOrInvalidOrInvalid = true
      newName = self:GetName(newName)
    end

    if not nameExistsOrInvalid then
      return newName
    end

    HBU.QuestionBox("Invalid name", "This name is invalid or already exists!", 0)
  end
  return newName
end

function Inspector:GetName(inp, offset, minVal, maxVal, nameFilter)
  local offsetProvided = (type(offset) == "number" and true or false)
  local name = ""
  if type(nameFilter) == "string" then
    if #nameFilter == 0 then
      nameFilter = false
    end
  else
    nameFilter = "[^a-zA-Z0-9_ -]"
  end
  offset = tonumber(offset or 0) or 0
  if type(inp) ~= "string" or #inp == 0 then
    inp = "name"
  end
  if offsetProvided and offset == 0 and not inp:match("[0-9]") then
    inp = inp .. "1"
  end
  local ret = inp:gsub(nameFilter, "")
  while offset ~= 0 do
    if offset < 0 then
      ret = self:PrevName(ret, minVal, maxVal)
    else
      ret = self:NextName(ret, minVal, maxVal)
    end
    offset = offset + (offset < 0 and 1 or -1)
  end
  return ret
end

function Inspector:PrevName(inp, minVal, maxVal)
  if type(inp) ~= "string" or #inp == 0 then
    return ""
  end
  minVal = tonumber(minVal or 1) or 1
  maxVal = tonumber(maxVal) or false
  local namePart, numPart = inp:match("^[a-zA-Z_ -][a-zA-Z_ -]*") or "", tonumber(inp:match("[0-9][0-9]*") or 0) or 0
  numPart = numPart - 1
  if numPart < minVal then
    numPart = maxVal or minVal
  elseif maxVal and numPart > maxVal then
    numPart = minVal
  end
  local prevname = namePart .. tostring(numPart)
  return prevname
end

function Inspector:NextName(inp, minVal, maxVal)
  if type(inp) ~= "string" or #inp == 0 then
    return ""
  end
  minVal = tonumber(minVal or 1) or 1
  maxVal = tonumber(maxVal) or false
  local namePart, numPart = inp:match("^[a-zA-Z_ -][a-zA-Z_ -]*") or "", tonumber(inp:match("[0-9][0-9]*") or 0) or 0
  numPart = numPart + 1
  if numPart < minVal then
    numPart = maxVal or minVal
  elseif maxVal and numPart > maxVal then
    numPart = minVal
  end
  local nextname = namePart .. tostring(numPart)
  return nextname
end

function Inspector:IsCurrentTarget(target)
  return self.lastTarget == target
end

return Inspector
