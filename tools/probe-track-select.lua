-- probe-track-select.lua -- log every change of ram_0192 (TrackSelect) and
-- take a screenshot after each one.
--
-- This is what caught the session's own first mistake: ram_0192 was named
-- ObjKind on the strength of AND #$03 matching the manual's four obstacle
-- kinds. Watching it live showed just four changes across 23,985 frames of
-- three-track driving, and every screenshot landed on the same screen --
-- the track select menu -- which is not the rate or the place an obstacle
-- indicator would change at.
--
-- Env: A7800_TS_LOG (default probe-track-select.log)
local M=(type(manager.machine)=="function") and manager:machine() or manager.machine
local mem=M.devices[":maincpu"].spaces["program"]
local F=0
local prev=nil
local log=io.open(os.getenv("A7800_TS_LOG") or "probe-track-select.log","w")
emu.register_frame_done(function()
  F=F+1
  local v=mem:read_u8(0x0192)
  if v~=prev then
    log:write(string.format("%d %02X\n",F,v))
    log:flush()
    if prev~=nil then pcall(function() M.video:snapshot() end) end
    prev=v
  end
end)
if emu.add_machine_stop_notifier then STOPPER=emu.add_machine_stop_notifier(function() log:close() end) end
