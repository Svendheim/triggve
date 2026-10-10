-- @no-index
--[[
  Triggve folder loader
  ---------------------
  Makes the "Load" button in every Triggve zone do something: click it and this
  script opens REAPER's native file picker, takes the folder of whatever sample
  you pick, and hands the first 8 samples back to that zone.

  Why a script at all? A JSFX cannot open a file dialog, cannot list a folder
  and cannot write files, so REAPER has to do that part. The plugin draws the
  button and fills its slots; this script only translates a click into a
  folder path and a directory listing.

  Install (once): the script runs in the background for the whole REAPER
  session, so it is started by REAPER at launch. ./install.sh wires it into
  __startup.lua for you; see the README if you prefer to do it by hand.
]]

local POLL_SECONDS = 0.25
local MAX_SAMPLES  = 8
local HANDOFF      = "triggve_load.txt"   -- lands in REAPER's Data folder

local accepted = { wav = true, ogg = true, flac = true }

local seen   = {}   -- "chain|fx" -> last request id this script has acted on
local cache  = {}   -- "chain|fx" -> { tr, fx, req_i, zone_i } or false
local last_poll = -1
local last_scan = -1
local scan_sig  = ""

-- ---------------------------------------------------------------- instances

-- Every FX chain that can hold a Triggve: all tracks, plus the master.
local function chains()
  local list = {}
  for i = 0, reaper.CountTracks(0) - 1 do
    list[#list + 1] = { tr = reaper.GetTrack(0, i), key = "t" .. i }
  end
  list[#list + 1] = { tr = reaper.GetMasterTrack(0), key = "master" }
  return list
end

-- Find every Triggve instance that has the loader parameters. Looking for the
-- parameters instead of the plug-in name means old Triggve builds (without the
-- buttons) and renamed instances are both handled correctly.
local function locate(track, fx)
  local req_i, zone_i
  for p = 0, reaper.TrackFX_GetNumParams(track, fx) - 1 do
    local ok, name = reaper.TrackFX_GetParamName(track, fx, p)
    if ok and name then
      local low = name:lower()
      if     low:find("load request") then req_i = p
      elseif low:find("load zone")    then zone_i = p end
    end
  end
  if req_i and zone_i then
    return { tr = track, fx = fx, req_i = req_i, zone_i = zone_i }
  end
  return false
end

-- A cheap fingerprint of the FX layout: anything added or removed invalidates
-- the parameter cache, so the poll itself stays light.
local function signature()
  local sig = ""
  for _, c in ipairs(chains()) do
    sig = sig .. reaper.TrackFX_GetCount(c.tr) .. ","
  end
  return sig
end

local function instances(now)
  local sig = signature()
  if sig ~= scan_sig or now - last_scan > 2 then
    cache = {}
    for _, c in ipairs(chains()) do
      for fx = 0, reaper.TrackFX_GetCount(c.tr) - 1 do
        cache[c.key .. "|" .. fx] = locate(c.tr, fx)
      end
    end
    scan_sig  = sig
    last_scan = now
  end

  local out = {}
  for key, e in pairs(cache) do
    if e then out[#out + 1] = { key = key, e = e } end
  end
  return out
end

-- ------------------------------------------------------------------ loading

-- REAPER has no "pick a folder" dialog, so the user picks any file and the
-- folder is taken from it. No extension filter: the picker then shows every
-- file in the folder, whatever the samples in it are.
local function pick_folder()
  local ok, file = reaper.GetUserFileNameForRead(
    "", "Choose any file from the folder you want in this zone", "")
  if not ok or file == "" then return nil end
  return file:match("^(.*[/\\])")
end

local function list_samples(dir)
  local files, i = {}, 0
  reaper.EnumerateFiles(dir, -1)      -- REAPER caches listings; ask for a fresh one
  while i < 4000 do
    local f = reaper.EnumerateFiles(dir, i)
    if not f or f == "" then break end
    local ext = f:match("%.([%w]+)$")
    if ext and accepted[ext:lower()] then files[#files + 1] = f end
    i = i + 1
  end
  table.sort(files)
  return files
end

-- Hand-off format, read by Triggve.jsfx (see check_load_file there):
--   <request id>  the plugin's Load request value, so a stale file is ignored
--   <row>         the row that was clicked
--   <path>        up to 8 absolute sample paths
local function write_handoff(request, row, dir, files)
  local data = reaper.GetResourcePath() .. "/Data"
  reaper.RecursiveCreateDirectory(data, 0)
  local f = io.open(data .. "/" .. HANDOFF, "w")
  if not f then return nil end
  f:write(string.format("%d\n%d\n", request, row))
  for i = 1, math.min(#files, MAX_SAMPLES) do
    f:write(dir .. files[i], "\n")
  end
  f:close()
  return true
end

local function serve(e, request)
  local dir = pick_folder()
  if not dir then return end           -- cancelled: the zone is left alone

  local files = list_samples(dir)
  if #files == 0 then
    reaper.ShowMessageBox(
      "No WAV, OGG or FLAC files in\n\n" .. dir .. "\n\nNothing was loaded.",
      "Triggve", 0)
    return
  end

  if not write_handoff(request, e.row, dir, files) then
    reaper.ShowMessageBox(
      "Triggve could not write its hand-off file in\n\n" ..
      reaper.GetResourcePath() .. "/Data\n\nCheck that folder's permissions.",
      "Triggve", 0)
  end
end

-- ----------------------------------------------------------------- poll loop

local function tick()
  local now = reaper.time_precise()
  if now - last_poll >= POLL_SECONDS then
    last_poll = now
    for _, item in ipairs(instances(now)) do
      local e, key = item.e, item.key
      local request = math.floor(reaper.TrackFX_GetParam(e.tr, e.fx, e.req_i) + 0.5)
      local previous = seen[key]
      if previous == nil then
        seen[key] = request           -- adopt, never act on a click we did not see
      elseif request > previous then
        seen[key] = request
        e.row = math.floor(reaper.TrackFX_GetParam(e.tr, e.fx, e.zone_i) + 0.5)
        serve(e, request)
      end
    end
  end
  reaper.defer(tick)
end

-- Only one copy of the loader may run, or every click would ask twice.
if reaper.GetExtState("Triggve", "folderloader") ~= "" then
  reaper.ShowMessageBox(
    "The Triggve folder loader is already running in this REAPER session.",
    "Triggve", 0)
  return
end
reaper.SetExtState("Triggve", "folderloader", "1", false)

tick()
