-- probe-bank6-dma.lua -- is bank 6 ever touched, by anything?
--
-- disasm.py finds zero instructions reached in bank 6 (fixed, $4000-$7FFF)
-- and no JSR/JMP anywhere else in the ROM operates on that range -- which
-- only rules out the CPU running it as code. MAME's address-space read
-- taps do not distinguish a CPU fetch from MARIA's own DMA, since both
-- cross the same bus in the emulation; tapping the whole range settles
-- what a static read cannot.
--
-- Env: A7800_B6_LOG (default probe-bank6-dma.log)
local M=(type(manager.machine)=="function") and manager:machine() or manager.machine
local mem=M.devices[":maincpu"].spaces["program"]
local count=0
local addrs={}
TAPS={}
TAPS[1]=mem:install_read_tap(0x4000,0x7FFF,"b6",function(off,data)
  count=count+1
  addrs[off]=(addrs[off] or 0)+1
  return data
end)
local function dump()
  local f=io.open(os.getenv("A7800_B6_LOG") or "probe-bank6-dma.log","w")
  f:write(string.format("total reads of $4000-$7FFF: %d\n",count))
  local n=0; for _ in pairs(addrs) do n=n+1 end
  f:write(string.format("distinct addresses touched: %d of 16384\n",n))
  f:close()
end
if emu.add_machine_stop_notifier then STOPPER=emu.add_machine_stop_notifier(dump) end
