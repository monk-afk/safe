  --==[[        Safe        ]]==--
      --====================--
local S = minetest.get_translator("safe")
local FE = minetest.formspec_escape

local modpath = minetest.get_modpath(minetest.get_current_modname()).."/"
local safe = dofile(modpath.."api.lua")
dofile(modpath.."node.lua")
dofile(modpath.."salt.lua")
dofile(modpath.."form.lua")

minetest.register_on_leaveplayer(function(player)
  safe.contexts[player:get_player_name()] = nil
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
  local name = player:get_player_name()

  if formname ~= "safe:formspec" or not safe.contexts[name] then
    return false
  end

  if fields.quit or fields.exit then
    safe.contexts[name] = nil
    return true
  end

  -- Get Context
  local context = safe.contexts[name]
  if not context then
    return false
  end

  -- Was a tab selected?
  if fields.safe_nav_tabs and context.nav then
    local tid = tonumber(fields.safe_nav_tabs)

    if tid and tid > 0 then
      local id = context.nav[tid]
      local page = safe.pages[id]

      if id and page then
        set_page(player, id)
      end
    end

  else
    -- Pass event to page
    local page = safe.pages[context.page]
    if page and page.on_player_receive_fields then
      return page:on_player_receive_fields(player, context, fields)
    end
  end
end)


-- These pages are included in the unlocked safe nav tabs

register_page("safe:safe_inventory", {
  title = S("Safe"),

  get = function(self, player, context)
    local form = bg_locked
    
    if context.pos and can_access_safe(player, context.pos) then
      form = inventory_form(spos(context.pos))
    end
    
    return make_formspec(player, context, form, true)
  end,

  on_enter = function(self, player, context)
    if context.pos and can_access_safe(player, context.pos) then
      local str_pos = spos(context.pos)
      if count_remaining_keys(str_pos) then
        context.force_regen = true
        context.label = "Only two (2) Recovery Keys Remain!\nYou Must Generate new recovery keys.\n"
        return set_page(player, "safe:request_keygen")
      end
    end
  end,

  is_in_nav = function(self, player, context)
    return true
  end,
})


register_page("safe:access_logs", {
  title = S("Logs"),

  get = function(self, player, context)
    local form = bg_locked

    if can_access_safe(player, context.pos) then
      form = access_logs(context.pos)
    end

    return make_formspec(player, context, form, true)
  end,

  is_in_nav = function(self, player, context)
    return true
  end,
})


register_page("safe:request_keygen", {
  title = S("Keys"),

  get = function(self, player, context)
    local form = bg_locked
    if context.pos and can_access_safe(player, context.pos) then
      local meta = minetest.get_meta(context.pos)

      if meta then
        local time_lock = meta:get_int("tlock")
        local time, fmt_time = time_remaining(time_lock)

        if time >= 1 and not context.force_regen then
          form = box("10")
              .. header("Generate Recovery Keys")
              .. textarea({"0.5,1.5", "9.75,6.5", "", "This Menu is Security Time-locked!",
                   "Generating new Keys is temporarily disabled due to a recent PIN reset.\n"
                .. "Check the access logs if you're unaware of this change.\n"
                .. "If you have not authorized this PIN change: please empty the contents of this safe and contact the Admin.\n\n"
                .. "Time-lock expires in: " .. fmt_time
              })

        else
          if not context.force_regen then
            meta:set_int("tlock", 0)
          end

          form = box("10")
              .. header("Generate Recovery Keys")
              .. textarea({"0.5,1.5", "9.75,6.5", "", "Caution!",
                  "Generating a new set of Recovery Keys will overwrite the old Keys. "
                .. "After generating a new set, it is safe to delete the old Keys.\n"
                .. "Each Key can be used one time to reset PIN.\n"
                .. "You are responsible for your own Safe!\n"
                .. "The Admin cannot recover your PIN, Recovery Keys or the contents of this Safe."
              })
              .. button({"8,7.25", "1.8,0.8", "regen_keys", "Okay"})
        end
      end
    end

    return make_formspec(player, context, form, true)
  end,

  on_player_receive_fields = function(self, player, context, fields)
    if context.page == "safe:request_keygen" and fields.regen_keys then
      local meta = minetest.get_meta(context.pos)

      if can_access_safe(player, context.pos)
          or can_access_safe(player, context.pos) and context.force_regen then
        context.backup_codes = generate_backup_codes(spos(context.pos))
        record_log(context.pos, player:get_player_name(), "7")
        set_page(player, "safe:generate_new_keys")
      end
    end
  end,

  is_in_nav = function(self, player, context)
    return true
  end,
})


-- Following pages are for setup and access, omitted from nav tabs

register_page("safe:warning_advisory", {
  title = S("Warning"),

  get = function(self, player, context)
    local form = box("10")
        .. header("!! WARNING !!")
        .. textarea({"0.5,0.75", "9.75,6.5", "", "",
             "DO NOT use password or PIN from real life accounts.\n\n"
          .. "Do NOT use Password or PIN from: bank, mobile, email, social media, etc.\n\n"
          .. "All Minetest servers transmit data unencrypted. "
          .. "This means everything that you send to the server "
          .. "has the potential to be seen by a network hijacker.\n\n"
          .. "The chance and risk for this to happen is quite low, "
          .. "however there is still a risk. Until Minetest updates "
          .. "to a more secure network protocol, it is very important "
          .. "to understand and agree to USE A PASSWORD OR PIN "
          .. "THAT YOU DO NOT USE ELSEWHERE!\n\n"
          .. "This warning will be displayed until Minetest adopts "
          .. "encrypted networking protocols.\n\n"
          .. "Do not use this Safe if you don't understand what any of "
          .. "this means."
          })
        .. button({"0,7.25", "10.0,0.8", "agree_warning", "I WILL NOT USE IRL PASSWORDS"})
    return make_formspec(player, context, form, false)
  end,

  on_player_receive_fields = function(self, player, context, fields)
    if context.page == "safe:warning_advisory" and fields.agree_warning then
      return set_page(player, "safe:set_password")
    end
  end,

  is_in_nav = function(self, player, context)
    return false
  end,
})


register_page("safe:exit_page", {
  title = S("Exit"),

  get = function(self, player, context)
    local form = box("10")
        .. button_exit({"7.9,-0.051", "2,0.8", "exit", "Close"})
        .. header((context.header or ""))
        .. textarea({"0.5,0.75", "9.75,5", "", "", (context.textarea or "")})

    return make_formspec(player, context, form, false, "size[10,4]")
  end,

  on_leave = function(self, player, context)
    context = {}
  end,

  is_in_nav = function(self, player, context)
    return false
  end,
})


register_page("safe:use_recovery_key", {
  title = S("Forgot Password"),

  get = function(self, player, context)
    local form = box("4")
        .. header("Reset Forgot PIN")
        .. field({"0.25,1.5", "4,1", "recovery_code", "Enter Reset Key:", ""})
        .. button({"2.35,2.25", "1.5,0.8", "submit_code", "Verify"})
        .. button_exit({"0.1,2.25", "1.5,0.8", "exit", "Cancel"})
    return make_formspec(player, context, form, false, "size[4,2.9]")
  end,

  on_player_receive_fields = function(self, player, context, fields)
    if context.page == "safe:use_recovery_key" and fields.submit_code then
      local meta = minetest.get_meta(context.pos)

      if meta and meta:get_string("name") == idpos(context.pos) then
        local str_pos = spos(context.pos)
        local name = player:get_player_name()

        if verify_recovery_key(fields.recovery_code, str_pos) then
          record_log(context.pos, name, "6")

          meta:set_string("name", "Player")
          meta:mark_as_private("name")
          meta:set_string("owner", name)
          meta:set_int("tlock", os.time())

          context.header = "PIN Reset!"
          context.textarea = "Delete the used key: "..FE(fields.recovery_code).." "
                           .."and re-configure this Safe with a new PIN/Password"
          set_page(player, "safe:exit_page")

        else
          record_log(context.pos, name, "2")

          context.header = "Invalid Recovery Key!"
          context.textarea = "The Key you submitted is either incorrect or already used. "
                           .."Please try a different Recovery Key."

          set_page(player, "safe:exit_page")
        end
      end
    end
  end,

  is_in_nav = function(self, player, context)
    return false
  end,
})


register_page("safe:generate_new_keys", {
  title = S("Generate Recovery Keys"),

  get = function(self, player, context)
    local form = bg_locked
  
    if context.pos and can_access_safe(player, context.pos) then
      form = box("10")
          .. header("New Password Recovery Keys")
          .. textarea({"0.5,0.75", "9.75,6.5", "", "",
               "Save these codes and do not share them, they will only be shown here once.\n"
            .. "Each key is a single-use token to reset a forgotten PIN/Password.\n"
            .. "After using a Recovery Key, you cannot generate new keys for 72-hours.\n"
            .. "After using 4 Keys, you must Generate a new set.\n\n"
            .. "New Recovery Keys can be generated from the Safe Menu.\n"
            .. "All Keys and Passwords are encrypted with SHA3.\n"
            .. "Admin cannot recover your PIN, Keys or Safe items."
          })
          .. textarea({"0.5,6.5", "7.75,2", "nil", "",
            table.concat(context.backup_codes, "  ")
          })
          .. button_exit({"8,6.5", "1.8,0.8", "exit", "Done"})
    end

    return make_formspec(player, context, form, false)
  end,

  on_leave = function(self, player, context)
    context = {}
  end,

  is_in_nav = function(self, player, context)
    return false
  end,
})


register_page("safe:unlock_safe", {
  title = S("PIN Authorize"),

  get = function(self, player, context)
    if context and context.pos then
      local form = bg_front
          .. pin_form
          .. recover_btn

      if context.keyed_pin and #context.keyed_pin > 0 then
        local fakepin = context.keyed_pin

        form = form .. field({
          "2.35,3","3.5,0",
          context.field_name or "unlock_pass",
          context.label or "Enter PIN",
          fakepin:gsub(".", "*") or ""
        })

      else
        form = form .. pwdfield({
          "2.35,3","3.5,0",
          context.field_name or "unlock_pass",
          context.label or "Enter PIN"
        })
      end

      return make_formspec(player, context, form, false, "size[8,8]")
    end
  end,

  on_player_receive_fields = function(self, player, context, fields)
    if context.page == "safe:unlock_safe" and context.pos then
      local meta = minetest.get_meta(context.pos)
      local name = player:get_player_name()

      if meta:get_string("name") ~= idpos(context.pos) then
        return
      end

      if fields.recover_btn then
        -- local time_lock = meta:get_int("tlock") or 0
        -- local time, fmt_time = time_remaining(time_lock)
        -- if time == 0 then
        --   meta:set_int("tlock", 0)
          set_page(player, "safe:use_recovery_key")
        -- else
        --   context.label = "Security Time-locked!\n\n"
        --       .. "Expires in: "..fmt_time
        --   set_page(player, "safe:exit_page")
        -- end
      end

      if fields.keypad and not fields.pin_submit then
        if not context.keyed_pin then
          context.keyed_pin = fields.keypad
        else
          context.keyed_pin = context.keyed_pin .. fields.keypad
        end
        return set_page(player, "safe:unlock_safe")
      end

      if fields.pin_submit and fields.unlock_pass
          and not context.field_name then
        
        if context.keyed_pin then
          fields.unlock_pass = context.keyed_pin
        end

        local try_password = tostring(fields.unlock_pass)

        if check_password(try_password, context.pos) then
          context.label = nil
          context.keyed_pin = nil
          context.field_name = nil
          context.access = name
          record_log(context.pos, name, "9")
          set_page(player, "safe:safe_inventory")

        else
          context.label = "Invalid PIN!"
          context.keyed_pin = nil
          context.field_name = nil

          record_log(context.pos, name, "0")
          return set_page(player, "safe:unlock_safe")
        end
      end
    end
  end,

  is_in_nav = function(self, player, context)
    return false
  end,
})


register_page("safe:set_password", {
  title = S("Password"),

  get = function(self, player, context)
    if context and context.pos then
      local pos = context.pos
      local meta = minetest.get_meta(pos)

      if meta:get_string("name") == "Player" and
          meta:get_string("owner") == player:get_player_name() then

        local form = pin_form .. bg_front

        if context.keyed_pin and #context.keyed_pin > 0 then
          local fakepin = context.keyed_pin

          form = form .. field({
            "2.35,3","3.5,0",
            context.field_name or "first_pass",
            context.label or "Enter New PIN",
            fakepin:gsub(".", "*") or ""
          })

        else
          form = form .. pwdfield({
            "2.35,3","3.5,0",
            context.field_name or "first_pass",
            context.label or "Enter New PIN"
          })
        end

        return make_formspec(player, context, form, false, "size[8,8]")
      end
    end
  end,

  on_player_receive_fields = function(self, player, context, fields)
    if context.page == "safe:set_password" and context.pos then
      local meta = minetest.get_meta(context.pos)
      local name = player:get_player_name()

      if meta:get_string("owner") ~= name then
        return
      end

      if fields.keypad then
        if not context.keyed_pin then
          context.keyed_pin = fields.keypad
        else
          context.keyed_pin = context.keyed_pin .. fields.keypad
        end

        return set_page(player, "safe:set_password")
      end

      if fields.pin_submit and fields.first_pass
          and not context.field_name then
        
        if context.keyed_pin then
          fields.first_pass = context.keyed_pin
        end

        local first_password = tostring(fields.first_pass)
        
        if #first_password < 4 then
          context.label = "Min. 4 characters"
          return set_page(player, "safe:set_password")

        elseif first_password ~= string.match(first_password, "^[%w%d%p%s]+$") then
          context.label = "Invalid Character"
          return set_page(player, "safe:set_password")

        else
          context.keyed_pin = nil
          context.first_pass = first_password
          context.field_name = "second_pass"
          context.label = "Confirm PIN:"
          return set_page(player, "safe:set_password")
        end
      end

      if fields.pin_submit and fields.second_pass
          and context.field_name == "second_pass" then

        local second_password = tostring(fields.second_pass)

        if context.keyed_pin then
          second_password = context.keyed_pin
        end

        if second_password ~= context.first_pass then
          context.keyed_pin = nil
          context.field_name = nil
          context.first_pass = nil
          context.label = "Password Mismatch"
          return set_page(player, "safe:set_password")
        end

        if not new_password(context.first_pass, context.pos) then
          context.keyed_pin = nil
          context.field_name = nil
          context.first_pass = nil
          context.label = "Creation Failed!"
          return set_page(player, "safe:set_password")
        end

        if check_password(second_password, context.pos, true) then
          save_safe_context(context.pos)

          local safe_id = idpos(context.pos)
          meta:set_string("name", safe_id)
          meta:mark_as_private("name")
          meta:set_string("infotext", "Locked Safe (ID:"..safe_id..")")

          context.keyed_pin = nil
          context.field_name = nil
          context.first_pass = nil

          record_log(context.pos, name, "8")

          if meta:get_int("tlock") == 0 then
            context.access = name
            context.backup_codes = generate_backup_codes(spos(context.pos))
            return set_page(player, "safe:generate_new_keys")
          else
            context.header = "Success!"
            context.textarea = "Your safe is configured with the new PIN!"
            return set_page(player, "safe:exit_page")
          end

        else
          context.label = "Validation Failed!"
          return set_page(player, "safe:set_password")
        end
      end
    end
  end,

  is_in_nav = function(self, player, context)
    return false
  end,
})


register_page("safe:set_owner", {
  title = S("Set Owner"),
  get = function(self, player, context)
    if not minetest.check_player_privs(player, "protection_bypass") then
      return false
    end
      local form = set_owner_form
      ..header("New Safe Setup")
      ..field({
        "0.275,1.675","5,1",
        "field_setowner",
        FE(context.label) or "Set Owner:",
        FE(context.field_default) or ""
      })
      ..button({
        "3.1,2.48","1.8,0.8",
        "submit_setowner",
        "Apply"
      })
      ..button_exit({
        "0.1,2.48","1.8,0.8",
        "exit",
        context.exit_label or "Cancel"
      })

    return make_formspec(player, context, form, false, "size[5,3]")
  end,

  on_player_receive_fields = function(self, player, context, fields)
    if context.page == "safe:set_owner" and context.pos
        and minetest.check_player_privs(player, "protection_bypass") then

      if not (fields.field_setowner and fields.submit_setowner) then
        context.label = "Invalide form submission"
        return set_page(player, "safe:set_owner")
      end

      if fields.field_setowner == "" or fields.field_setowner == "Player" then
        context.label = "'"..fields.field_setowner.."' is an invalide player"
        return set_page(player, "safe:set_owner")
      end

      if fields.field_setowner ~= string.match(fields.field_setowner, "^[a-zA-Z0-9_-]+$")
          or fields.field_setowner:len() > 18
          or not minetest.player_exists(fields.field_setowner) then
        context.field_default = fields.field_setowner
        context.label = "'"..fields.field_setowner.."' Player not found!"
        return set_page(player, "safe:set_owner")

      else
        local meta = minetest.get_meta(context.pos)
        meta:set_string("owner", fields.field_setowner)
        meta:set_string("infotext", fields.field_setowner.."'s Safe (Unconfigured)")
        context.field_default = fields.field_setowner
        context.label = "Owner set to <"..meta:get_string("owner")..">"
        context.exit_label = "Exit"
        return set_page(player, "safe:set_owner")
      end
    end
  end,

  is_in_nav = function(self, player, context)
    return false
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