-- Motor Psycho: what do the five indirect jumps actually dispatch to?
--
-- disasm.py finds JMP ($004A), JMP ($004C) x3 and JMP ($006C) and stops
-- there: the target lives in RAM, so no static reader can know it. On a
-- bankswitched cartridge the answer is two numbers, not one -- the address
-- and the bank mapped at $8000-$BFFF when the jump is taken -- so this
-- tracks the SuperGame bank select alongside the vector writes.
--
-- SuperGame selects a bank by *writing* to $8000-$BFFF; the value written
-- is the bank number.
local M=(type(manager.machine)=="function") and manager:machine() or manager.machine
local mem=M.devices[":maincpu"].spaces["program"]
local cpu=M.devices[":maincpu"]
local bank=-1
local seen={}
TAPS={}
TAPS[#TAPS+1]=mem:install_write_tap(0x8000,0xBFFF,"banksel",function(off,data,mask)
  bank=data
  return data
end)
local function vec(lo,name)
  TAPS[#TAPS+1]=mem:install_write_tap(lo+1,lo+1,name,function(off,data,mask)
    local pc=cpu.state["PC"].value
    local t=mem:read_u8(lo)|(data<<8)
    local k=string.format("%s -> $%04X  bank %-3d  written by $%04X",name,t,bank,pc)
    seen[k]=(seen[k] or 0)+1
    return data
  end)
end
vec(0x4A,"vec_4A"); vec(0x4C,"vec_4C"); vec(0x6C,"vec_6C")
local function dump()
  local f=io.open(os.getenv("A7800_MP_LOG") or "mp-vectors.log","w")
  local ks={} for k,_ in pairs(seen) do ks[#ks+1]=k end
  table.sort(ks,function(a,b) return seen[a]>seen[b] end)
  for _,k in ipairs(ks) do f:write(string.format("%s  x%d\n",k,seen[k])) end
  f:close()
end
if emu.add_machine_stop_notifier then MP=emu.add_machine_stop_notifier(dump) end
