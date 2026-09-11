-- probe-player1-steer.lua -- confirm the player-1 steering chain is live.
--
-- Found by tracing the NMI handler (see docs/DISCOVERY.md): a 7-sample
-- SWCHA buffer (ram_2644/ram_264B, indexed by ram_2643) feeds
-- sub_F6ED/sub_F702, which combine it with the response-time scale
-- (ram_26E6-26E9) into ram_0051, then ram_0155. This watches all of them
-- for write frequency and value diversity, which is what told the real
-- pipeline apart from the bank-7 mirror that looked like it at first
-- (one write per session, against a quarter-million here).
--
-- Env: A7800_P1_LOG (default probe-player1-steer.log)
local M=(type(manager.machine)=="function") and manager:machine() or manager.machine
local mem=M.devices[":maincpu"].spaces["program"]
local WATCH={0x2644,0x264B,0x0051,0x0155,0x014D,0x2643}
local seen={}
for _,a in ipairs(WATCH) do seen[a]={n=0,vals={}} end
TAPS={}
for _,a in ipairs(WATCH) do
  local addr=a
  TAPS[#TAPS+1]=mem:install_write_tap(addr,addr,"w",function(off,data)
    seen[addr].n=seen[addr].n+1
    seen[addr].vals[data]=(seen[addr].vals[data] or 0)+1
    return data
  end)
end
local function dump()
  local f=io.open(os.getenv("A7800_P1_LOG") or "probe-player1-steer.log","w")
  for _,a in ipairs(WATCH) do
    local n=0; for _ in pairs(seen[a].vals) do n=n+1 end
    f:write(string.format("$%04X  %d writes, %d distinct values\n",a,seen[a].n,n))
  end
  f:close()
end
if emu.add_machine_stop_notifier then STOPPER=emu.add_machine_stop_notifier(dump) end
