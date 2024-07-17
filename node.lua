  --==[[        Safe        ]]==--
      --====================--
local S = minetest.get_translator("safe")

minetest.register_node("safe:safe", {
	description = S("Safe Storage"),
	paramtype = "light",
	paramtype2 = "facedir",
	tiles = {
    "safe_safe_back.png",
    "safe_safe_back.png",
    "safe_safe_back.png",
    "safe_safe_back.png",
    "safe_safe_back.png",
    "safe_safe_front.png"
  },
	is_ground_content = false,
	groups = {cracky=1},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
    meta:set_string("infotext", S("Unowned Safe"))
    meta:set_string("logs", minetest.serialize({}))
    meta:mark_as_private("logs")
		meta:set_string("owner", "")
    meta:set_string("name", "Player")
    meta:mark_as_private("name")
    local inv = meta:get_inventory()
    inv:set_size("safe", 10*4)
    meta:mark_as_private("safe")
	end,

	after_place_node = function(pos, player)
    if minetest.check_player_privs(player, "protection_bypass") then
      local context = get_or_create_context(player)
      context.pos = pos
      set_page(player, "safe:set_owner")
    end
	end,

	on_rightclick = function(pos, node, player)
		local meta = minetest.get_meta(pos)
    local name = player:get_player_name()
    local owner = meta:get_string("owner")
    local safe_id = meta:get_string("name")

    if minetest.check_player_privs(player, "protection_bypass")
        and owner == "" then -- Safe admin didnt set name
      local context = get_or_create_context(player)
      context.pos = pos
      return set_page(player, "safe:set_owner")
    end

    if owner == name and safe_id == "Player" then -- owner has not set password
      local context = get_or_create_context(player)
      context.pos = pos
      return set_page(player, "safe:warning_advisory")
    end

    if owner ~= "" and safe_id == idpos(pos) then
      local context = get_or_create_context(player)
      context.pos = pos
      return set_page(player, "safe:unlock_safe")
    end
	end,

  can_dig = function(pos,player)
    local meta = minetest.get_meta(pos);
    local inv = meta:get_inventory()
    return inv:is_empty("safe")
        and minetest.check_player_privs(player, "protection_bypass")
  end,

  after_dig_node = function(pos, oldnode, oldmetadata, player)
    return delete_password(pos)
  end,

  allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
    if not can_access_safe(player, pos) then
      minetest.log("action", player:get_player_name()..
          " tried to access "..minetest.get_node(pos).name..
          " at ("..spos(pos)..")")
      return 0
    end
    return count
  end,

  allow_metadata_inventory_put = function(pos, listname, index, stack, player)
    if not can_access_safe(player, pos) then
      minetest.log("action", player:get_player_name()..
          " tried to access "..minetest.get_node(pos).name..
          " at ("..spos(pos)..")")
      return 0
    end
    return stack:get_count()
  end,

  allow_metadata_inventory_take = function(pos, listname, index, stack, player)
    if not can_access_safe(player, pos) then
      minetest.log("action", player:get_player_name()..
          " tried to access "..minetest.get_node(pos).name..
          " at ("..spos(pos)..")")
      return 0
    end
    return stack:get_count()
  end,

  on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local from_stack = inv:get_stack(from_list, from_index)
    local to_stack = inv:get_stack(to_list, to_index)
    minetest.log("action", player:get_player_name()..
        " moves "..to_stack:get_name().." "..to_stack:get_count()..
        " to "..from_stack:get_name().." "..from_stack:get_count()..
        " inside "..minetest.get_node(pos).name..
        " at ("..spos(pos)..")")
  end,

  on_metadata_inventory_put = function(pos, listname, index, stack, player)
    minetest.log("action", player:get_player_name()..
        " puts "..stack:get_name().." "..stack:get_count()..
        " into "..minetest.get_node(pos).name..
        " at ("..spos(pos)..")")
  end,
  
  on_metadata_inventory_take = function(pos, listname, index, stack, player)
    minetest.log("action", player:get_player_name()..
        " takes "..stack:get_name().." "..stack:get_count()..
        " from "..minetest.get_node(pos).name..
        " at ("..spos(pos)..")")
  end,
})


------------------------------------------------------------------------------------
-- MIT License                                                                    --
--                                                                                --
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