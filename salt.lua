  --==[[        Safe        ]]==--
      --====================--
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname).."/"
local storage = minetest.get_mod_storage()
local passwords = {}

local available_hash = {
  sha3   = "sha3.lua",
  blake3 = "blake3.lua",
  sha512 = "sha512.lua"
}

local algorithm = minetest.settings:get("safe_hash_algorithm")

if not algorithm or algorithm == "" then
  algorithm = available_hash.sha3
elseif available_hash[algorithm] then
  algorithm = available_hash[algorithm]
else
  algorithm = available_hash.sha3
end

local hash_password = dofile(modpath..algorithm)

local byte = string.byte
local char = string.char
local srep = string.rep
local rand = math.random

local random = function()
  return rand(33,126)
end

local function generate_salt(length)
  length = length or 16
  local salt = {}

  for i = 1, length do
    salt[i] = char(random())
  end
  return table.concat(salt)
end

local function padding(str)
  local original_len = #str
  local pad = -(original_len + 1 + 8) % 64

  local function len_to_8byte(len)
    local result = ""
    len = len * 8
    for i = 1, 8 do
      local rem = len % 256
      result = char(rem) .. result
      len = (len - rem) / 256
    end
    return result
  end

  str = str .. "0".. srep("0", pad) .. len_to_8byte(original_len)
  assert(#str % 64 == 0)
  return str
end


local function pos_to_string(pos)
  return tostring(pos.x..","..pos.y..","..pos.z)
end


local safe_data = minetest.deserialize(storage:get_string(modname))
if type(safe_data) ~= "table" then
  safe_data = {} 
end


local function save_safe_data()
  if type(safe_data) == "table" then
    storage:set_string(modname, minetest.serialize(safe_data))
    minetest.log("action", "[safe] Saved safe data")
  end
end


-- function to check if there are 2 codes left, to generate new keys
local function count_remaining_keys(str_pos)
  if #safe_data[str_pos][3] <= 2 then
    return true
  end
end
passwords.count_remaining_keys = count_remaining_keys


local function verify_recovery_key(raw_code, str_pos)
  local baseless_salt = minetest.decode_base64(safe_data[str_pos][1])
  local code = hash_password(baseless_salt..padding(raw_code))

  for c = 1, #safe_data[str_pos][3] do
    if safe_data[str_pos][3][c] == code then
      safe_data[str_pos][3][c] = nil
      save_safe_data()

      return true
    end
  end
end
passwords.verify_recovery_key = verify_recovery_key


local function generate_backup_codes(str_pos)
  local backup_codes = {}
  local chars = "SmK96xNTXjhylqLnidZpkDgsCHVM7cJr302aewAEBWQFOtR14zGPbY5vuUoI8f"
  local baseless_salt = minetest.decode_base64(safe_data[str_pos][1])

  for n = 1,6 do
    for c = 1,12 do
      local r = rand(#chars)
      backup_codes[n] = (backup_codes[n] or "") .. chars:sub(r,r)
    end

    safe_data[str_pos][3][n] = hash_password(baseless_salt..padding(backup_codes[n]))
  end

  save_safe_data()

  return backup_codes
end
passwords.generate_backup_codes = generate_backup_codes


local safe_context = {}

local function save_safe_context(pos)
  local function transfer_context(str_pos, data)
    safe_data[str_pos] = {
      minetest.encode_base64(data[1]),
      data[2], data[3]
    }
    return safe_data[str_pos]
  end

  local str_pos = pos_to_string(pos)
  local new_data = transfer_context(str_pos, safe_context[str_pos])

  if new_data and new_data[2] == safe_context[str_pos][2] then
    save_safe_data()
    safe_context[str_pos] = nil
  end
end
passwords.save_safe_context = save_safe_context


local function new_password(password, pos)
  local salt = generate_salt(32)
  local keys = {}
  local str_pos = pos_to_string(pos)

  if safe_data[str_pos] then
    salt = minetest.decode_base64(safe_data[str_pos][1])
    keys = safe_data[str_pos][3]
  end

  local hash = hash_password(salt .. padding(password))
  safe_context[str_pos] = {salt, hash, keys}
  return true
end
passwords.new_password = new_password


local function check_password(password, pos, check_context)
  -- check_context true to check password (to unlock safe)
  local str_pos = pos_to_string(pos)

  if not check_context and safe_data[str_pos] then
    local hash = safe_data[str_pos][2]
    local base = safe_data[str_pos][1]
    local salt = minetest.decode_base64(base)

    if hash_password(salt..padding(password)) == hash then
      return true
    end
  
  -- check_context nil to verify second password (for new password)
  elseif check_context and safe_context[str_pos] then
    local hash = safe_context[str_pos][2]
    local salt = safe_context[str_pos][1]

    if hash_password(salt..padding(password)) == hash then
      return true
    end
  end

  return false
end
passwords.check_password = check_password


local function delete_password(pos)
  local str_pos = pos_to_string(pos)

  if safe_data[str_pos] then
    safe_data[str_pos] = nil
  end

  if safe_context[str_pos] then
    safe_context[str_pos] = nil
  end

  return save_safe_data()
end
passwords.delete_password = delete_password

return passwords



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
