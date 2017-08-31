menuItemCache = {} 

function concatTables(t1, t2)
   for k,v in pairs(t2) do
      table.insert(t1, v)
   end
   return t1
end

function isValidMenuItem(menuItem)
   -- Currently affected by a bug in AXEnabled: disabled menus will still show.   
   return menuItem and menuItem.AXTitle and menuItem.AXTitle ~= "" 
   -- and menuItem.AXEnabled (doesn't work)
end

function computeMenuItemPath(menuItem, parentPath)
   if parentPath then 
      return parentPath .. "/" .. menuItem.AXTitle 
   else 
      return menuItem.AXTitle
   end   
end

function menuItemsToPaths(menu, parentPath)
  local result = {}  

  -- Ugh.  My lack of Lua knowledge hurts.  Surely this can be much better.
  for k,v in pairs(menu) do
    if isValidMenuItem(v) then
      local fullPath = computeMenuItemPath(v, parentPath)
      if v.AXChildren then
        local children = v.AXChildren[1]
        -- print(fullPath .. " has " .. #t .. " children")
        result = concatTables(result, menuItemsToPaths(children, fullPath))
      else
        -- print("  " .. fullPath)
        result = concatTables(result, {fullPath})
      end
    end
  end
  return result
end

function menuItemsToChoices(menuItems)
  local choices = hs.fnutils.map(menuItems, function(result)
    return {
      ["text"] = result
    }
  end)
  return choices  
end

function isInitialLetters(query)
  return string.match(query, "^[A-Z]+$") ~= nil
end

function matchesInitials(menuItem, queryAsInitials)
   regex, matchCount = string.gsub(queryAsInitials, "[A-Z]", "%1[^A-Z]+")
   return string.match(menuItem, regex) ~= nil
end

function matches(menuItem, query)
   if isInitialLetters(query) then
     return matchesInitials(menuItem, query)
   else  
     i, j = string.find(menuItem:lower(), query:lower())
     return i ~= nil
   end
end

function searchMenuItems(menuItems, query)
   if query == "" then
     query = "NotGonnaBeThere"
   end

   return hs.fnutils.filter(menuItems, function(item)
     local m = matches(item, query)
     return m
   end)
end

function init()
  local current = hs.application.frontmostApplication()
  local chooser = hs.chooser.new(function(chosen)
    current:activate()
    if chosen ~= nil then
       current:selectMenuItem(hs.fnutils.split(chosen["text"], "/"))
    end
  end)
  chooser:bgDark(false)
  chooser:searchSubText(false)
  chooser:show()

  chooser:queryChangedCallback(function(query)
    local menuItemPaths
    local title = current:title()
    if menuItemCache[title] == nil then
      local menuItems = current:getMenuItems(current)
      menuItemCache[title] = menuItemsToPaths(menuItems, nil)
    end
    menuItemPaths = menuItemCache[title]
    chooser:choices(menuItemsToChoices(searchMenuItems(menuItemPaths, query)))
  end)
end


hs.hotkey.bind({"cmd"}, "escape", function()
  init()
end)

-- hs.openConsole() Useful for debugging.
  


