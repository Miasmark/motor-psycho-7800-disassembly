-- probe-input-readers.lua -- who reads the controller hardware, and how often.
--
-- sub_F1A9/sub_F1BA in bank 7 mirror INPT0/INPT1/SWCHA into RAM, and a first
-- pass watching that mirror found it barely changes across a 270-second
-- run -- a handful of transitions total, which is what a title-screen
-- "press any button" poll looks like, not a race the whole way through.
-- So this taps the hardware registers themselves and records which PC (and
-- which bank, since $8000-$BFFF is switched) reads each one and how often,
-- to find whichever routine is actually driving the car.
--
-- Env: A7800_IR_LOG (default probe-input-readers.log)
local M = (type(manager.machine) == "function") and manager:machine() or manager.machine
local mem = M.devices[":maincpu"].spaces["program"]
local cpu = M.devices[":maincpu"]

local OUT = os.getenv("A7800_IR_LOG") or "probe-input-readers.log"

local bank = -1
TAPS = {}
TAPS[1] = mem:install_write_tap(0x8000, 0xBFFF, "banksel", function(off, data)
  bank = data
  return data
end)

local seen = {}
local function watch(addr, name)
  TAPS[#TAPS+1] = mem:install_read_tap(addr, addr, name, function(off, data)
    local pc = cpu.state["PC"].value
    local where = (pc >= 0x8000 and pc < 0xC000) and string.format("b%d:%04X", bank, pc)
                  or string.format("f7:%04X", pc)
    local k = name .. " <- " .. where
    seen[k] = (seen[k] or 0) + 1
    return data
  end)
end
watch(0x0008, "INPT0")
watch(0x0009, "INPT1")
watch(0x0280, "SWCHA")

local function dump()
  local f = io.open(OUT, "w")
  local ks = {}
  for k in pairs(seen) do ks[#ks+1] = k end
  table.sort(ks, function(a, b) return seen[a] > seen[b] end)
  for _, k in ipairs(ks) do
    f:write(string.format("%-28s x%d\n", k, seen[k]))
  end
  f:close()
end
if emu.add_machine_stop_notifier then STOPPER = emu.add_machine_stop_notifier(dump)
else emu.register_stop(dump) end
