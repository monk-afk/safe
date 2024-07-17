local concat = table.concat
local byte = string.byte
local char = string.char
local string_rep = string.rep
local sub = string.sub
local gsub = string.gsub
local string_format = string.format
local floor = math.floor
local math_min = math.min

local AND_of_two_bytes = {[0] = 0}
local idx = 0
for y = 0, 127 * 256, 256 do
  for x = y, y + 127 do
    x = AND_of_two_bytes[x] * 2
    AND_of_two_bytes[idx] = x
    AND_of_two_bytes[idx + 1] = x
    AND_of_two_bytes[idx + 256] = x
    AND_of_two_bytes[idx + 257] = x + 1
    idx = idx + 2
  end
  idx = idx + 256
end

local function and_or_xor(x, y, operation)
  local x0 = x % 2^32
  local y0 = y % 2^32
  local rx = x0 % 256
  local ry = y0 % 256
  local res = AND_of_two_bytes[rx + ry * 256]
  x = x0 - rx
  y = (y0 - ry) / 256
  rx = x % 65536
  ry = y % 256
  res = res + AND_of_two_bytes[rx + ry] * 256
  x = (x - rx) / 256
  y = (y - ry) / 256
  rx = x % 65536 + y % 256
  res = res + AND_of_two_bytes[rx] * 65536
  res = res + AND_of_two_bytes[(x + y - rx) / 256] * 16777216
  if operation then
    res = x0 + y0 - operation * res
  end
  return res
end

local function AND(x, y)
  return and_or_xor(x, y)
end


local function XOR(x, y, z, t, u)
  if z then
    if t then
    if u then
      t = and_or_xor(t, u, 2)
    end
    z = and_or_xor(z, t, 2)
    end
    y = and_or_xor(y, z, 2)
  end
  return and_or_xor(x, y, 2)
end

local function XOR_BYTE(x, y)
  return x + y - 2 * AND_of_two_bytes[x + y * 256]
end


local HEX
HEX = HEX or pcall(string_format, "%x", 2^31) and function(x)
  return string_format("%08x", x % 4294967296)
end


local function create_array_of_lanes()
  return {
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0
  }
end

local sha3_RC_lo = {}
local sha3_RC_hi = {}
local hi_factor_keccak = 0

local function keccak_feed(lanes_lo, lanes_hi, str, offs, size, block_size_in_bytes)
  local RC_lo, RC_hi = sha3_RC_lo, sha3_RC_hi
  local qwords_qty = block_size_in_bytes / 8
  for pos = offs, offs + size - 1, block_size_in_bytes do
    for j = 1, qwords_qty do
      local a, b, c, d = byte(str, pos + 1, pos + 4)
      lanes_lo[j] = XOR(lanes_lo[j], ((d * 256 + c) * 256 + b) * 256 + a)
      pos = pos + 8
      a, b, c, d = byte(str, pos - 3, pos)
      lanes_hi[j] = XOR(lanes_hi[j], ((d * 256 + c) * 256 + b) * 256 + a)
    end
    local L01_lo, L01_hi, L02_lo, L02_hi, L03_lo, L03_hi, L04_lo, L04_hi, L05_lo, L05_hi, L06_lo, L06_hi, L07_lo, L07_hi, L08_lo, L08_hi,
    L09_lo, L09_hi, L10_lo, L10_hi, L11_lo, L11_hi, L12_lo, L12_hi, L13_lo, L13_hi, L14_lo, L14_hi, L15_lo, L15_hi, L16_lo, L16_hi,
    L17_lo, L17_hi, L18_lo, L18_hi, L19_lo, L19_hi, L20_lo, L20_hi, L21_lo, L21_hi, L22_lo, L22_hi, L23_lo, L23_hi, L24_lo, L24_hi, L25_lo, L25_hi =
    lanes_lo[1], lanes_hi[1], lanes_lo[2], lanes_hi[2], lanes_lo[3], lanes_hi[3], lanes_lo[4], lanes_hi[4], lanes_lo[5], lanes_hi[5],
    lanes_lo[6], lanes_hi[6], lanes_lo[7], lanes_hi[7], lanes_lo[8], lanes_hi[8], lanes_lo[9], lanes_hi[9], lanes_lo[10], lanes_hi[10],
    lanes_lo[11], lanes_hi[11], lanes_lo[12], lanes_hi[12], lanes_lo[13], lanes_hi[13], lanes_lo[14], lanes_hi[14], lanes_lo[15], lanes_hi[15],
    lanes_lo[16], lanes_hi[16], lanes_lo[17], lanes_hi[17], lanes_lo[18], lanes_hi[18], lanes_lo[19], lanes_hi[19], lanes_lo[20], lanes_hi[20],
    lanes_lo[21], lanes_hi[21], lanes_lo[22], lanes_hi[22], lanes_lo[23], lanes_hi[23], lanes_lo[24], lanes_hi[24], lanes_lo[25], lanes_hi[25]
    for round_idx = 1, 24 do
      local C1_lo = XOR(L01_lo, L06_lo, L11_lo, L16_lo, L21_lo)
      local C1_hi = XOR(L01_hi, L06_hi, L11_hi, L16_hi, L21_hi)
      local C2_lo = XOR(L02_lo, L07_lo, L12_lo, L17_lo, L22_lo)
      local C2_hi = XOR(L02_hi, L07_hi, L12_hi, L17_hi, L22_hi)
      local C3_lo = XOR(L03_lo, L08_lo, L13_lo, L18_lo, L23_lo)
      local C3_hi = XOR(L03_hi, L08_hi, L13_hi, L18_hi, L23_hi)
      local C4_lo = XOR(L04_lo, L09_lo, L14_lo, L19_lo, L24_lo)
      local C4_hi = XOR(L04_hi, L09_hi, L14_hi, L19_hi, L24_hi)
      local C5_lo = XOR(L05_lo, L10_lo, L15_lo, L20_lo, L25_lo)
      local C5_hi = XOR(L05_hi, L10_hi, L15_hi, L20_hi, L25_hi)
      local D_lo = XOR(C1_lo, C3_lo * 2 + (C3_hi % 2^32 - C3_hi % 2^31) / 2^31)
      local D_hi = XOR(C1_hi, C3_hi * 2 + (C3_lo % 2^32 - C3_lo % 2^31) / 2^31)
      local T0_lo = XOR(D_lo, L02_lo)
      local T0_hi = XOR(D_hi, L02_hi)
      local T1_lo = XOR(D_lo, L07_lo)
      local T1_hi = XOR(D_hi, L07_hi)
      local T2_lo = XOR(D_lo, L12_lo)
      local T2_hi = XOR(D_hi, L12_hi)
      local T3_lo = XOR(D_lo, L17_lo)
      local T3_hi = XOR(D_hi, L17_hi)
      local T4_lo = XOR(D_lo, L22_lo)
      local T4_hi = XOR(D_hi, L22_hi)
      L02_lo = (T1_lo % 2^32 - T1_lo % 2^20) / 2^20 + T1_hi * 2^12
      L02_hi = (T1_hi % 2^32 - T1_hi % 2^20) / 2^20 + T1_lo * 2^12
      L07_lo = (T3_lo % 2^32 - T3_lo % 2^19) / 2^19 + T3_hi * 2^13
      L07_hi = (T3_hi % 2^32 - T3_hi % 2^19) / 2^19 + T3_lo * 2^13
      L12_lo = T0_lo * 2 + (T0_hi % 2^32 - T0_hi % 2^31) / 2^31
      L12_hi = T0_hi * 2 + (T0_lo % 2^32 - T0_lo % 2^31) / 2^31
      L17_lo = T2_lo * 2^10 + (T2_hi % 2^32 - T2_hi % 2^22) / 2^22
      L17_hi = T2_hi * 2^10 + (T2_lo % 2^32 - T2_lo % 2^22) / 2^22
      L22_lo = T4_lo * 2^2 + (T4_hi % 2^32 - T4_hi % 2^30) / 2^30
      L22_hi = T4_hi * 2^2 + (T4_lo % 2^32 - T4_lo % 2^30) / 2^30
      D_lo = XOR(C2_lo, C4_lo * 2 + (C4_hi % 2^32 - C4_hi % 2^31) / 2^31)
      D_hi = XOR(C2_hi, C4_hi * 2 + (C4_lo % 2^32 - C4_lo % 2^31) / 2^31)
      T0_lo = XOR(D_lo, L03_lo)
      T0_hi = XOR(D_hi, L03_hi)
      T1_lo = XOR(D_lo, L08_lo)
      T1_hi = XOR(D_hi, L08_hi)
      T2_lo = XOR(D_lo, L13_lo)
      T2_hi = XOR(D_hi, L13_hi)
      T3_lo = XOR(D_lo, L18_lo)
      T3_hi = XOR(D_hi, L18_hi)
      T4_lo = XOR(D_lo, L23_lo)
      T4_hi = XOR(D_hi, L23_hi)
      L03_lo = (T2_lo % 2^32 - T2_lo % 2^21) / 2^21 + T2_hi * 2^11
      L03_hi = (T2_hi % 2^32 - T2_hi % 2^21) / 2^21 + T2_lo * 2^11
      L08_lo = (T4_lo % 2^32 - T4_lo % 2^3) / 2^3 + T4_hi * 2^29 % 2^32
      L08_hi = (T4_hi % 2^32 - T4_hi % 2^3) / 2^3 + T4_lo * 2^29 % 2^32
      L13_lo = T1_lo * 2^6 + (T1_hi % 2^32 - T1_hi % 2^26) / 2^26
      L13_hi = T1_hi * 2^6 + (T1_lo % 2^32 - T1_lo % 2^26) / 2^26
      L18_lo = T3_lo * 2^15 + (T3_hi % 2^32 - T3_hi % 2^17) / 2^17
      L18_hi = T3_hi * 2^15 + (T3_lo % 2^32 - T3_lo % 2^17) / 2^17
      L23_lo = (T0_lo % 2^32 - T0_lo % 2^2) / 2^2 + T0_hi * 2^30 % 2^32
      L23_hi = (T0_hi % 2^32 - T0_hi % 2^2) / 2^2 + T0_lo * 2^30 % 2^32
      D_lo = XOR(C3_lo, C5_lo * 2 + (C5_hi % 2^32 - C5_hi % 2^31) / 2^31)
      D_hi = XOR(C3_hi, C5_hi * 2 + (C5_lo % 2^32 - C5_lo % 2^31) / 2^31)
      T0_lo = XOR(D_lo, L04_lo)
      T0_hi = XOR(D_hi, L04_hi)
      T1_lo = XOR(D_lo, L09_lo)
      T1_hi = XOR(D_hi, L09_hi)
      T2_lo = XOR(D_lo, L14_lo)
      T2_hi = XOR(D_hi, L14_hi)
      T3_lo = XOR(D_lo, L19_lo)
      T3_hi = XOR(D_hi, L19_hi)
      T4_lo = XOR(D_lo, L24_lo)
      T4_hi = XOR(D_hi, L24_hi)
      L04_lo = T3_lo * 2^21 % 2^32 + (T3_hi % 2^32 - T3_hi % 2^11) / 2^11
      L04_hi = T3_hi * 2^21 % 2^32 + (T3_lo % 2^32 - T3_lo % 2^11) / 2^11
      L09_lo = T0_lo * 2^28 % 2^32 + (T0_hi % 2^32 - T0_hi % 2^4) / 2^4
      L09_hi = T0_hi * 2^28 % 2^32 + (T0_lo % 2^32 - T0_lo % 2^4) / 2^4
      L14_lo = T2_lo * 2^25 % 2^32 + (T2_hi % 2^32 - T2_hi % 2^7) / 2^7
      L14_hi = T2_hi * 2^25 % 2^32 + (T2_lo % 2^32 - T2_lo % 2^7) / 2^7
      L19_lo = (T4_lo % 2^32 - T4_lo % 2^8) / 2^8 + T4_hi * 2^24 % 2^32
      L19_hi = (T4_hi % 2^32 - T4_hi % 2^8) / 2^8 + T4_lo * 2^24 % 2^32
      L24_lo = (T1_lo % 2^32 - T1_lo % 2^9) / 2^9 + T1_hi * 2^23 % 2^32
      L24_hi = (T1_hi % 2^32 - T1_hi % 2^9) / 2^9 + T1_lo * 2^23 % 2^32
      D_lo = XOR(C4_lo, C1_lo * 2 + (C1_hi % 2^32 - C1_hi % 2^31) / 2^31)
      D_hi = XOR(C4_hi, C1_hi * 2 + (C1_lo % 2^32 - C1_lo % 2^31) / 2^31)
      T0_lo = XOR(D_lo, L05_lo)
      T0_hi = XOR(D_hi, L05_hi)
      T1_lo = XOR(D_lo, L10_lo)
      T1_hi = XOR(D_hi, L10_hi)
      T2_lo = XOR(D_lo, L15_lo)
      T2_hi = XOR(D_hi, L15_hi)
      T3_lo = XOR(D_lo, L20_lo)
      T3_hi = XOR(D_hi, L20_hi)
      T4_lo = XOR(D_lo, L25_lo)
      T4_hi = XOR(D_hi, L25_hi)
      L05_lo = T4_lo * 2^14 + (T4_hi % 2^32 - T4_hi % 2^18) / 2^18
      L05_hi = T4_hi * 2^14 + (T4_lo % 2^32 - T4_lo % 2^18) / 2^18
      L10_lo = T1_lo * 2^20 % 2^32 + (T1_hi % 2^32 - T1_hi % 2^12) / 2^12
      L10_hi = T1_hi * 2^20 % 2^32 + (T1_lo % 2^32 - T1_lo % 2^12) / 2^12
      L15_lo = T3_lo * 2^8 + (T3_hi % 2^32 - T3_hi % 2^24) / 2^24
      L15_hi = T3_hi * 2^8 + (T3_lo % 2^32 - T3_lo % 2^24) / 2^24
      L20_lo = T0_lo * 2^27 % 2^32 + (T0_hi % 2^32 - T0_hi % 2^5) / 2^5
      L20_hi = T0_hi * 2^27 % 2^32 + (T0_lo % 2^32 - T0_lo % 2^5) / 2^5
      L25_lo = (T2_lo % 2^32 - T2_lo % 2^25) / 2^25 + T2_hi * 2^7
      L25_hi = (T2_hi % 2^32 - T2_hi % 2^25) / 2^25 + T2_lo * 2^7
      D_lo = XOR(C5_lo, C2_lo * 2 + (C2_hi % 2^32 - C2_hi % 2^31) / 2^31)
      D_hi = XOR(C5_hi, C2_hi * 2 + (C2_lo % 2^32 - C2_lo % 2^31) / 2^31)
      T1_lo = XOR(D_lo, L06_lo)
      T1_hi = XOR(D_hi, L06_hi)
      T2_lo = XOR(D_lo, L11_lo)
      T2_hi = XOR(D_hi, L11_hi)
      T3_lo = XOR(D_lo, L16_lo)
      T3_hi = XOR(D_hi, L16_hi)
      T4_lo = XOR(D_lo, L21_lo)
      T4_hi = XOR(D_hi, L21_hi)
      L06_lo = T2_lo * 2^3 + (T2_hi % 2^32 - T2_hi % 2^29) / 2^29
      L06_hi = T2_hi * 2^3 + (T2_lo % 2^32 - T2_lo % 2^29) / 2^29
      L11_lo = T4_lo * 2^18 + (T4_hi % 2^32 - T4_hi % 2^14) / 2^14
      L11_hi = T4_hi * 2^18 + (T4_lo % 2^32 - T4_lo % 2^14) / 2^14
      L16_lo = (T1_lo % 2^32 - T1_lo % 2^28) / 2^28 + T1_hi * 2^4
      L16_hi = (T1_hi % 2^32 - T1_hi % 2^28) / 2^28 + T1_lo * 2^4
      L21_lo = (T3_lo % 2^32 - T3_lo % 2^23) / 2^23 + T3_hi * 2^9
      L21_hi = (T3_hi % 2^32 - T3_hi % 2^23) / 2^23 + T3_lo * 2^9
      L01_lo = XOR(D_lo, L01_lo)
      L01_hi = XOR(D_hi, L01_hi)
      L01_lo, L02_lo, L03_lo, L04_lo, L05_lo = XOR(L01_lo, AND(-1-L02_lo, L03_lo)), XOR(L02_lo, AND(-1-L03_lo, L04_lo)), XOR(L03_lo, AND(-1-L04_lo, L05_lo)), XOR(L04_lo, AND(-1-L05_lo, L01_lo)), XOR(L05_lo, AND(-1-L01_lo, L02_lo))
      L01_hi, L02_hi, L03_hi, L04_hi, L05_hi = XOR(L01_hi, AND(-1-L02_hi, L03_hi)), XOR(L02_hi, AND(-1-L03_hi, L04_hi)), XOR(L03_hi, AND(-1-L04_hi, L05_hi)), XOR(L04_hi, AND(-1-L05_hi, L01_hi)), XOR(L05_hi, AND(-1-L01_hi, L02_hi))
      L06_lo, L07_lo, L08_lo, L09_lo, L10_lo = XOR(L09_lo, AND(-1-L10_lo, L06_lo)), XOR(L10_lo, AND(-1-L06_lo, L07_lo)), XOR(L06_lo, AND(-1-L07_lo, L08_lo)), XOR(L07_lo, AND(-1-L08_lo, L09_lo)), XOR(L08_lo, AND(-1-L09_lo, L10_lo))
      L06_hi, L07_hi, L08_hi, L09_hi, L10_hi = XOR(L09_hi, AND(-1-L10_hi, L06_hi)), XOR(L10_hi, AND(-1-L06_hi, L07_hi)), XOR(L06_hi, AND(-1-L07_hi, L08_hi)), XOR(L07_hi, AND(-1-L08_hi, L09_hi)), XOR(L08_hi, AND(-1-L09_hi, L10_hi))
      L11_lo, L12_lo, L13_lo, L14_lo, L15_lo = XOR(L12_lo, AND(-1-L13_lo, L14_lo)), XOR(L13_lo, AND(-1-L14_lo, L15_lo)), XOR(L14_lo, AND(-1-L15_lo, L11_lo)), XOR(L15_lo, AND(-1-L11_lo, L12_lo)), XOR(L11_lo, AND(-1-L12_lo, L13_lo))
      L11_hi, L12_hi, L13_hi, L14_hi, L15_hi = XOR(L12_hi, AND(-1-L13_hi, L14_hi)), XOR(L13_hi, AND(-1-L14_hi, L15_hi)), XOR(L14_hi, AND(-1-L15_hi, L11_hi)), XOR(L15_hi, AND(-1-L11_hi, L12_hi)), XOR(L11_hi, AND(-1-L12_hi, L13_hi))
      L16_lo, L17_lo, L18_lo, L19_lo, L20_lo = XOR(L20_lo, AND(-1-L16_lo, L17_lo)), XOR(L16_lo, AND(-1-L17_lo, L18_lo)), XOR(L17_lo, AND(-1-L18_lo, L19_lo)), XOR(L18_lo, AND(-1-L19_lo, L20_lo)), XOR(L19_lo, AND(-1-L20_lo, L16_lo))
      L16_hi, L17_hi, L18_hi, L19_hi, L20_hi = XOR(L20_hi, AND(-1-L16_hi, L17_hi)), XOR(L16_hi, AND(-1-L17_hi, L18_hi)), XOR(L17_hi, AND(-1-L18_hi, L19_hi)), XOR(L18_hi, AND(-1-L19_hi, L20_hi)), XOR(L19_hi, AND(-1-L20_hi, L16_hi))
      L21_lo, L22_lo, L23_lo, L24_lo, L25_lo = XOR(L23_lo, AND(-1-L24_lo, L25_lo)), XOR(L24_lo, AND(-1-L25_lo, L21_lo)), XOR(L25_lo, AND(-1-L21_lo, L22_lo)), XOR(L21_lo, AND(-1-L22_lo, L23_lo)), XOR(L22_lo, AND(-1-L23_lo, L24_lo))
      L21_hi, L22_hi, L23_hi, L24_hi, L25_hi = XOR(L23_hi, AND(-1-L24_hi, L25_hi)), XOR(L24_hi, AND(-1-L25_hi, L21_hi)), XOR(L25_hi, AND(-1-L21_hi, L22_hi)), XOR(L21_hi, AND(-1-L22_hi, L23_hi)), XOR(L22_hi, AND(-1-L23_hi, L24_hi))
      L01_lo = XOR(L01_lo, RC_lo[round_idx])
      L01_hi = L01_hi + RC_hi[round_idx]
    end
    lanes_lo[1]  = L01_lo;  lanes_hi[1]  = L01_hi
    lanes_lo[2]  = L02_lo;  lanes_hi[2]  = L02_hi
    lanes_lo[3]  = L03_lo;  lanes_hi[3]  = L03_hi
    lanes_lo[4]  = L04_lo;  lanes_hi[4]  = L04_hi
    lanes_lo[5]  = L05_lo;  lanes_hi[5]  = L05_hi
    lanes_lo[6]  = L06_lo;  lanes_hi[6]  = L06_hi
    lanes_lo[7]  = L07_lo;  lanes_hi[7]  = L07_hi
    lanes_lo[8]  = L08_lo;  lanes_hi[8]  = L08_hi
    lanes_lo[9]  = L09_lo;  lanes_hi[9]  = L09_hi
    lanes_lo[10] = L10_lo;  lanes_hi[10] = L10_hi
    lanes_lo[11] = L11_lo;  lanes_hi[11] = L11_hi
    lanes_lo[12] = L12_lo;  lanes_hi[12] = L12_hi
    lanes_lo[13] = L13_lo;  lanes_hi[13] = L13_hi
    lanes_lo[14] = L14_lo;  lanes_hi[14] = L14_hi
    lanes_lo[15] = L15_lo;  lanes_hi[15] = L15_hi
    lanes_lo[16] = L16_lo;  lanes_hi[16] = L16_hi
    lanes_lo[17] = L17_lo;  lanes_hi[17] = L17_hi
    lanes_lo[18] = L18_lo;  lanes_hi[18] = L18_hi
    lanes_lo[19] = L19_lo;  lanes_hi[19] = L19_hi
    lanes_lo[20] = L20_lo;  lanes_hi[20] = L20_hi
    lanes_lo[21] = L21_lo;  lanes_hi[21] = L21_hi
    lanes_lo[22] = L22_lo;  lanes_hi[22] = L22_hi
    lanes_lo[23] = L23_lo;  lanes_hi[23] = L23_hi
    lanes_lo[24] = L24_lo;  lanes_hi[24] = L24_hi
    lanes_lo[25] = L25_lo;  lanes_hi[25] = L25_hi
  end
end

do
  local sh_reg = 29

  local function next_bit()
    local r = sh_reg % 2
    sh_reg = XOR_BYTE((sh_reg - r) / 2, 142 * r)
    return r
  end

  for idx = 1, 24 do
    local lo, m = 0
      for _ = 1, 6 do
        m = m and m * m * 2 or 1
        lo = lo + next_bit() * m
      end
    local hi = next_bit() * m
    sha3_RC_hi[idx], sha3_RC_lo[idx] = hi, lo + hi * hi_factor_keccak
  end
end

local function keccak(block_size_in_bytes, digest_size_in_bytes, is_SHAKE, message)
  if type(digest_size_in_bytes) ~= "number" then
    error("Argument 'digest_size_in_bytes' must be a number", 2)
  end

  local tail, lanes_lo, lanes_hi = "", create_array_of_lanes(), hi_factor_keccak == 0 and create_array_of_lanes()
  local result

  local function partial(message_part)
    if message_part then
      if tail then
        local offs = 0
        if tail ~= "" and #tail + #message_part >= block_size_in_bytes then
          offs = block_size_in_bytes - #tail
          keccak_feed(lanes_lo, lanes_hi, tail..sub(message_part, 1, offs), 0, block_size_in_bytes, block_size_in_bytes)
          tail = ""
        end
        local size = #message_part - offs
        local size_tail = size % block_size_in_bytes
        keccak_feed(lanes_lo, lanes_hi, message_part, offs, size - size_tail, block_size_in_bytes)
        tail = tail..sub(message_part, #message_part + 1 - size_tail)
        return partial
      else
        error("Adding more chunks is not allowed after receiving the result", 2)
      end
    else
      if tail then
        local gap_start = is_SHAKE and 31 or 6
        tail = tail..(#tail + 1 == block_size_in_bytes and char(gap_start + 128) or char(gap_start)..string_rep("\0", (-2 - #tail) % block_size_in_bytes).."\128")
        keccak_feed(lanes_lo, lanes_hi, tail, 0, #tail, block_size_in_bytes)
        tail = nil
        local lanes_used = 0
        local total_lanes = floor(block_size_in_bytes / 8)
        local qwords = {}

        local function get_next_qwords_of_digest(qwords_qty)
          if lanes_used >= total_lanes then
            keccak_feed(lanes_lo, lanes_hi, "\0\0\0\0\0\0\0\0", 0, 8, 8)
            lanes_used = 0
          end
          qwords_qty = floor(math_min(qwords_qty, total_lanes - lanes_used))
          if hi_factor_keccak ~= 0 then
            for j = 1, qwords_qty do
              qwords[j] = HEX64(lanes_lo[lanes_used + j - 1 + lanes_index_base])
            end
          else
            for j = 1, qwords_qty do
              qwords[j] = HEX(lanes_hi[lanes_used + j])..HEX(lanes_lo[lanes_used + j])
            end
          end
          lanes_used = lanes_used + qwords_qty
          return
          gsub(concat(qwords, "", 1, qwords_qty), "(..)(..)(..)(..)(..)(..)(..)(..)", "%8%7%6%5%4%3%2%1"),
          qwords_qty * 8
        end

        local parts = {}
        local last_part, last_part_size = "", 0

        local function get_next_part_of_digest(bytes_needed)
          bytes_needed = bytes_needed or 1
          if bytes_needed <= last_part_size then
            last_part_size = last_part_size - bytes_needed
            local part_size_in_nibbles = bytes_needed * 2
            local result = sub(last_part, 1, part_size_in_nibbles)
            last_part = sub(last_part, part_size_in_nibbles + 1)
            return result
          end
          local parts_qty = 0
          if last_part_size > 0 then
            parts_qty = 1
            parts[parts_qty] = last_part
            bytes_needed = bytes_needed - last_part_size
          end
          while bytes_needed >= 8 do
            local next_part, next_part_size = get_next_qwords_of_digest(bytes_needed / 8)
            parts_qty = parts_qty + 1
            parts[parts_qty] = next_part
            bytes_needed = bytes_needed - next_part_size
          end
          if bytes_needed > 0 then
            last_part, last_part_size = get_next_qwords_of_digest(1)
            parts_qty = parts_qty + 1
            parts[parts_qty] = get_next_part_of_digest(bytes_needed)
          else
            last_part, last_part_size = "", 0
          end
          return concat(parts, "", 1, parts_qty)
        end

        if digest_size_in_bytes < 0 then
          result = get_next_part_of_digest
        else
          result = get_next_part_of_digest(digest_size_in_bytes)
        end
      end
      return result
    end
  end

  if message then
    return partial(message)()
  else
    return partial
  end
end

sha3 = function(message) return keccak((1600 - 2 * 224) / 8, 224 / 8, false, message) end

return sha3

-- return {
--   sha3_224 = function(message) return keccak((1600 - 2 * 224) / 8, 224 / 8, false, message) end,
--   sha3_256 = function(message) return keccak((1600 - 2 * 256) / 8, 256 / 8, false, message) end,
--   sha3_384 = function(message) return keccak((1600 - 2 * 384) / 8, 384 / 8, false, message) end,
--   sha3_512 = function(message) return keccak((1600 - 2 * 512) / 8, 512 / 8, false, message) end,
--   shake128 = function(message, digest_size_in_bytes) return keccak((1600 - 2 * 128) / 8, (digest_size_in_bytes or 32), true, message) end,
--   shake256 = function(message, digest_size_in_bytes) return keccak((1600 - 2 * 256) / 8, (digest_size_in_bytes or 64), true, message) end,
-- }


------------------------------------------------------------------------------------
-- MIT License                                                                    --
--                                                                                --
-- Copyright (c) 2018-2022  Egor Skriptunoff                                      --
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