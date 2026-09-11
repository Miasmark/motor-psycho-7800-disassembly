-- probe-vector-install.lua -- how often the $7878/$00B0 stub actually
-- fires, and who calls it.
--
-- f7:C6DC (JMP ($7878), resolving to $00B0) looked like it might be a
-- per-frame handler. Tapping the site directly and reading the return
-- address off the stack at that moment settled it: reached only 4-5 times
-- a session, always from sub_D9B4/sub_D9E4's table-driven vector
-- installer, which fits a track- or object-load event rather than
-- anything running every frame.
--
-- Env: A7800_VI_LOG (default probe-vector-install.log)
local M=(type(manager.machine)=="function") and manager:machine() or manager.machine
local mem=M.devices[":maincpu"].spaces["program"]
local cpu=M.devices[":maincpu"]
local bank=-1
local hits={}
TAPS={}
TAPS[1]=mem:install_write_tap(0x8000,0xBFFF,"bs",function(off,data) bank=data; return data end)
TAPS[2]=mem:install_read_tap(0xC6DC,0xC6DC,"site",function(off,data)
  local sp=cpu.state["SP"].value
  local lo=mem:read_u8(0x100+((sp+1)&0xFF))
  local hi=mem:read_u8(0x100+((sp+2)&0xFF))
  local ret=(lo|(hi<<8))-2
  hits[#hits+1]=string.format("bank %d  called from ~$%04X",bank,ret)
  return data
end)
local function dump()
  local f=io.open(os.getenv("A7800_VI_LOG") or "probe-vector-install.log","w")
  for _,h in ipairs(hits) do f:write(h.."\n") end
  f:close()
end
if emu.add_machine_stop_notifier then STOPPER=emu.add_machine_stop_notifier(dump) end
