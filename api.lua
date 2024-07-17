  --==[[        Safe        ]]==--
      --====================--
local safe = {
  pages = {},
  pages_unordered = {},
  contexts = {},
}


function register_page(name, def)
  assert(name, "Invalid safe page. Requires a name")
  assert(def, "Invalid safe page. Requires a def[inition] table")
  assert(def.get, "Invalid safe page. Def requires a get function.")
  assert(not safe.pages[name], "Attempt to register already registered safe page " .. dump(name))

  safe.pages[name] = def
  def.name = name
  table.insert(safe.pages_unordered, def)
end


function override_page(name, def)
  assert(name, "Invalid safe page override. Requires a name")
  assert(def, "Invalid safe page override. Requires a def[inition] table")
  local page = safe.pages[name]
  assert(page, "Attempt to override safe page " .. dump(name) .. " which does not exist.")
  for key, value in pairs(def) do
    page[key] = value
  end
end


local function get_menu_tabs(player, context, nav, current_idx)
  return "tabheader[0,0;safe_nav_tabs;"..table.concat(nav, ",")
      ..";"..current_idx..";true;false]"
end


function spos(pos)
  return tostring(pos.x..","..pos.y..","..pos.z)
end


function idpos(pos)
  return tostring(pos.x..pos.y..pos.z):gsub("%-", "n")
end


function can_access_safe(player, pos)
  local name = player:get_player_name()
  local context = get_or_create_context(player)

  if not context.pos then
    record_log(pos, name, "1")
    return false
  end
  
  if idpos(context.pos) == minetest.get_meta(pos):get("name")
      and context.access == name then
    return true
  end

  record_log(context.pos, name, "1")
  return false
end


function make_formspec(player, context, content, show_tabs, size)
  local tmp = {
    size and size.."no_prepend[]" or "size[10,8.1]no_prepend[]",
    show_tabs and get_menu_tabs(player, context, context.nav_titles, context.nav_idx) or "",
    content
  }
  return table.concat(tmp, "")
end


local function get_homepage_name()    
  return "safe:home"
end


local function get_formspec(player, context)
  local nav = {}
  local nav_ids = {}
  local current_idx = 1
  for i, pdef in pairs(safe.pages_unordered) do
    if not pdef.is_in_nav or pdef:is_in_nav(player, context) then
      nav[#nav + 1] = pdef.title
      nav_ids[#nav_ids + 1] = pdef.name
      if pdef.name == context.page then
        current_idx = #nav_ids
      end
    end
  end
  context.nav = nav_ids
  context.nav_titles = nav
  context.nav_idx = current_idx

  -- Generate formspec
  local page = safe.pages[context.page] or safe.pages["404"]

  if page then
    return page:get(player, context)

  else
    local old_page = context.page
    local home_page = get_homepage_name(player)

    if old_page == home_page then
      minetest.log("error",
          "[safe] Couldn't find "..dump(old_page)..", which is also the old page")
      return ""
    end

    context.page = home_page
    assert(safe.pages[context.page], "[safe] Invalid homepage")
    minetest.log("warning",
        "[safe] Couldn't find "..dump(old_page)..", switching to homepage")

    return get_formspec(player, context)
  end
end


function get_or_create_context(player)
  local name = player:get_player_name()
  local context = safe.contexts[name]
  if not context then
    context = {
      page = get_homepage_name(player)
    }
    safe.contexts[name] = context
  end
  return context
end


function show_player_formspec(player, context)
  local fs = get_formspec(player, get_or_create_context(player))
  minetest.after(0.2, minetest.show_formspec,
      player:get_player_name(), "safe:formspec", fs)
end


function set_page(player, pagename)
  local context = get_or_create_context(player)
  local oldpage = safe.pages[context.page]
  
  if oldpage and oldpage.on_leave then
    oldpage:on_leave(player, context)
  end
  
  context.page = pagename
  local page = safe.pages[pagename]
  
  if page.on_enter then
    page:on_enter(player, context)
  end

  show_player_formspec(player, context)
end


local function get_page(player)
  local context = safe.contexts[player:get_player_name()]
  return context and context.page or get_homepage_name(player)
end


function record_log(pos, name, code)
  local meta = minetest.get_meta(pos)
  local logs = minetest.deserialize(meta:get_string("logs")) or {}

  logs[#logs+1] = {os.time(), name, code}

  if #logs > 32 then
    table.remove(logs, 1)
  end

  meta:set_string("logs", minetest.serialize(logs))
  meta:mark_as_private("logs")
end


local mf = math.floor
local mfm = math.fmod
function time_remaining(time_lock)
    local time = (time_lock + 259200) - os.time()
    local h = mf(time/3600)
    local m = mf(mfm(time,3600)/60)
  return time, string.format("%02dh %02dm", h,m)
end

return safe


------------------------------------------------------------------------------------
-- MIT License                                                                    --
--                                                                                --
-- Copyright (C) 2016-2018 rubenwardy <rubenwardy@gmail.com>                      --
-- Copyright (c) 2024 monk <monk.squareone@gmail.com>                             --
--                                                                                --
-- Permission is hereby granted, free of charge, to any person obtaining a copy   --
-- of this software and associated documentation files (the "Software"), to deal  --
-- in the Software without restriction, including without limitation the rights   --
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      --
-- copies of the Software, and to permit persons to whom the Software is          --
-- furnished to do so, subject to the following conditions:                       --
--                                                                                --
-- The above copyright notice and this permission notice shall be included in all --
-- copies or substantial portions of the Software.                                --
--                                                                                --
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     --
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       --
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    --
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         --
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  --
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  --
-- SOFTWARE.                                                                      --
------------------------------------------------------------------------------------