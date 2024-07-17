  --==[[        Safe        ]]==--
      --====================--
bg_front = "background9[0,0;0,0;safe_safe_new.png;true;true]"
bg_locked = "background9[0,0;0,0;safe_safe_front.png;true;true]"

set_owner_form = [[
  box[-0.1,-0.1;5,0.77;#30A110FF]
  box[-0.1,2.425;5,0.77;#30A110FF]
]]

pin_form = [[
  box[1.8,1.5;3.9,5.5;#0e0e0eFF]
  style_type[button;bgcolor=#323232;font=bold;textcolor=#00ee00ff]
  button[2.05,3.60;0.9,0;keypad;1]
  button[2.95,3.60;0.9,0;keypad;2]
  button[3.85,3.60;0.9,0;keypad;3]
  button[2.05,4.50;0.9,0;keypad;4]
  button[2.95,4.50;0.9,0;keypad;5]
  button[3.85,4.50;0.9,0;keypad;6]
  button[2.05,5.40;0.9,0;keypad;7]
  button[2.95,5.40;0.9,0;keypad;8]
  button[3.85,5.40;0.9,0;keypad;9]
  button[2.05,6.30;0.9,0;keypad;#]
  button[2.95,6.30;0.9,0;keypad;0]
  button[3.85,6.30;0.9,0;keypad;*]
  style_type[button;bgcolor=#323232;font=bold;textcolor=#008eeeff]
  button[4.75,3.6;0.9,0;pin_submit;>]
  style_type[button_exit;bgcolor=#323232;font=bold;textcolor=#ee0000ff]
  button_exit[4.75,4.5;0.9,0;exit;X]
]]

recover_btn = [[
  style_type[button;bgcolor=#323232;font=bold;textcolor=#ee8e00ff]
  button[4.75,5.4;0.9,0;recover_btn;?]
]]

box = function(width)
  return [[
    box[-0.1,-0.1;]]..width..[[,0.77;#30A110FF]
  ]]
end

function inventory_form(str_pos)
  return [[
    list[nodemeta:]] .. str_pos .. [[;safe;0,0;10,4;]
    list[current_player;main;1,4.25;8,4;]
    listring[nodemeta:]] .. str_pos .. [[;safe]
	  listring[current_player;main]
  ]]
end

function header(text) 
  return [[
    style_type[label;font=bold]
    label[0,0.025;]]..text..[[]
  ]]
end

function label(xy, text)
  return [[
    style_type[label;font=bold]
    label[]]..xy..[[;]]..text..[[]
  ]]
end

-- button[<X>,<Y>;<W>,<H>;<name>;<label>]
function button(fields)
  return [[
    style_type[button;bgcolor=#323232;font=bold]
    button[]]..table.concat(fields, ";")..[[]
  ]]
end

-- button_exit[<X>,<Y>;<W>,<H>;<name>;<label>]
function button_exit(fields) 
  return [[
    style_type[button_exit;bgcolor=#232323;font=bold;textcolor=red]
    button_exit[]]..table.concat(fields, ";")..[[]
  ]]
end

-- field[<X>,<Y>;<W>,<H>;<name>;<label>;<text>]
function field(fields)
  local name = fields[3]

  return [[
    set_focus[]]..name..[[;true]
    field_close_on_enter[]]..name..[[;false]
    field[]]..table.concat(fields, ";")..[[]
  ]]
end

-- textarea[<X>,<Y>;<W>,<H>;<name>;<label>;<default>]
function textarea(fields)
  local name = fields[3]

  return [[
    set_focus[]]..name..[[;true]
    field_close_on_enter[]]..name..[[;false]
    textarea[]]..table.concat(fields, ";")..[[]
  ]]
end

-- pwdfield[<X>,<Y>;<W>,<H>;<name>;<label>;<text>]
function pwdfield(fields)
  local name = fields[3]

  return [[
    set_focus[]]..name..[[;true]
    field_close_on_enter[]]..name..[[;false]
    pwdfield[]]..table.concat(fields, ";")..[[]
  ]]
end

--[[
  record_log(pos, name, "9")
    9 = Authenticated
    8 = PIN Changed
    7 = Generated Keys
    6 = Used Reset Key
    2 = Bad Recovery Key
    1 = Bypass Attempt
    0 = Incorrect PIN
]]

function access_logs(pos)
  local meta = minetest.get_meta(pos)
  local logs = minetest.deserialize(meta:get_string("logs")) or {}
  local rows = {
    "#FFFFFF,0,Time,Access,Player Name,"..
    "#FFFFFF,0,"..os.date("%b/%d %H:%M",os.time())..",Owner,"..meta:get_string("owner")..""
  }
  for i = #logs, 1, -1 do
    local timestamp = os.date("%b/%d %H:%M", logs[i][1])
    local name = logs[i][2]
    local code = logs[i][3]

    local auth_code = code == "9" and "Authenticated" or
                      code == "8" and "New PIN Set" or
                      code == "7" and "Generate Keys" or
                      code == "6" and "Used Recovery Key" or
                      code == "2" and "Bad Recovery Key" or
                      code == "1" and "Bypass Attempt" or
                      code == "0" and "Incorrect PIN"

    local code_color = code == "9" and "#23EE23" or
                       code == "8" and "#239EEE" or
                       code == "7" and "#3EEEE9" or
                       code == "6" and "#EFAC23" or
                       code == "2" and "#E23E23" or
                       code == "1" and "#EE235E" or
                       code == "0" and "#E3232E"

    rows[#rows+1] = ("%s,0,%s,%s,%s"):format(code_color,timestamp,auth_code,name)
  end

  return [[
    tablecolumns[color;tree;text;text;text]
    table[0,0;9.75,8.1;list;]]..table.concat(rows, ",")..[[]
  ]]
end



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