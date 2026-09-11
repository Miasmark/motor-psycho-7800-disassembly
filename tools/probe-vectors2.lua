-- probe-vectors2.lua -- every known indirect jump, sampled at the jump itself.
--
-- probe-vectors.lua records the bank selected when a vector's pointer is
-- *written*. The jump happens later and the bank can change in between, so
-- that is a hypothesis, not a fact -- and it produced one clearly wrong
-- answer (26 candidates attributed to bank 3 that decoded to 27
-- instructions of real code between them).
--
-- This instead taps a read at each JMP ($xxxx) instruction's own address,
-- which fires on the opcode fetch, and reads the bank register and the
-- vector's current value at that exact moment. No inference needed.
--
-- All nine sites --check-gaps currently knows about. The last one it finds,
-- f7:C6DC JMP ($7878), turned out not to need this at all: $7878/$7879 sit
-- in fixed bank 6 ROM and hold the constant bytes $B0 $00, so the jump
-- always resolves to $00B0 -- zero page, i.e. a small RAM-resident stub
-- installed at startup. It is watched here anyway, as the confirmation.
--
-- Env: A7800_MP_LOG (default probe-vectors2.log)
local M = (type(manager.machine) == "function") and manager:machine() or manager.machine
local mem = M.devices[":maincpu"].spaces["program"]

local OUT = os.getenv("A7800_MP_LOG") or "probe-vectors2.log"

local bank = -1
TAPS = {}
TAPS[1] = mem:install_write_tap(0x8000, 0xBFFF, "banksel", function(off, data)
  bank = data
  return data
end)

-- (site address, vector pointer address, label)
local SITES = {
  {0xB7F7, 0x4C,   "b5:B7F7"},
  {0xC0C3, 0x6C,   "f7:C0C3"},
  {0xC299, 0x26A8, "f7:C299"},
  {0xC29C, 0x26AA, "f7:C29C"},
  {0xC29F, 0x26AC, "f7:C29F"},
  {0xC6DC, 0x7878, "f7:C6DC"},
  {0xEC69, 0x4A,   "f7:EC69"},
  {0xFA44, 0x4C,   "f7:FA44"},
  {0xFD13, 0x4C,   "f7:FD13"},
}

local seen = {}
for _, s in ipairs(SITES) do
  local addr, vec, name = s[1], s[2], s[3]
  TAPS[#TAPS+1] = mem:install_read_tap(addr, addr, name, function(off, data)
    local t = mem:read_u8(vec) | (mem:read_u8(vec + 1) << 8)
    local k = string.format("%s  bank %-3d  -> $%04X", name, bank, t)
    seen[k] = (seen[k] or 0) + 1
    return data
  end)
end

local function dump()
  local f = io.open(OUT, "w")
  local ks = {}
  for k in pairs(seen) do ks[#ks+1] = k end
  table.sort(ks, function(a, b) return seen[a] > seen[b] end)
  for _, k in ipairs(ks) do
    f:write(string.format("%s  x%d\n", k, seen[k]))
  end
  f:close()
end
if emu.add_machine_stop_notifier then STOPPER = emu.add_machine_stop_notifier(dump)
else emu.register_stop(dump) end
