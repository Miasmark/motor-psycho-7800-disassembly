local M=(type(manager.machine)=="function") and manager:machine() or manager.machine
local mem=M.devices[":maincpu"].spaces["program"]
local cpu=M.devices[":maincpu"]
local reads={}
local writes={}
TAPS={}
TAPS[1]=mem:install_read_tap(0x259D,0x25B0,"r",function(off,data)
  local pc=cpu.state["CURPC"].value
  reads[pc]=(reads[pc] or 0)+1
  return data
end)
TAPS[2]=mem:install_write_tap(0x259D,0x25B0,"w",function(off,data)
  local pc=cpu.state["CURPC"].value
  local x=cpu.state["X"].value
  local y=cpu.state["Y"].value
  writes[#writes+1]=string.format("$%04X <- %02X from curpc $%04X X=%02X Y=%02X",off,data,pc,x,y)
  return data
end)
local function dump()
  local f=io.open(os.getenv("A7800_259D_LOG") or "mp259d.log","w")
  f:write("reads by CURPC:\n")
  local ks={} for k in pairs(reads) do ks[#ks+1]=k end
  table.sort(ks)
  for _,pc in ipairs(ks) do f:write(string.format("  curpc $%04X  x%d\n",pc,reads[pc])) end
  f:write(string.format("total writes: %d\n",#writes))
  for i=1,math.min(60,#writes) do f:write(writes[i].."\n") end
  f:close()
end
if emu.add_machine_stop_notifier then STOPPER=emu.add_machine_stop_notifier(dump) end
