-- @description TCHelper
-- @version 3.4.4
-- @author mittim88
-- @changelog
--   v3.4.0 - Added: Shortcut functionality (Settings -> Shortcuts)
--   v3.4.1 - Fixed: -startup crash because of shortcuts), naming of sequences
--   v3.4.2 - Fixed: -naming issue of temp/flash cues (all temp/flash cues are now named the same)
--   v3.4.3 - Updated: -changed naming behavior of temp/flash cuename window (only the first cue is named)
--   v3.4.4 - Fixed: -Fadetime behavior for temp/flash cues
--                   -Cue Notes cannot be changed anymore (chaning caused crash an corrupted project)
-- @provides
--   /TC_Helper/*.lua
--   /TC_Helper/data/pdf/*.pdf
--   /TC_Helper/data/keyMap/*.ReaperKeyMap
--   /TC_Helper/data/images/*.png
--   /TC_Helper/data/logo/*.png
--   /TC_Helper/data/projectTemplate/*.RPP


local version = '3.4.4'
local page = "https://raw.githubusercontent.com/mittim88/TCHelper/refs/heads/master/index.xml"
local mode2BETA = false
local testcmd3 = 'Echo --CONNECTION IS FINE--'
local testcmd2 = 'Echo --CONNECTION ESTABLISHED--'
local script_title = 'TCHelper'
local hostIP = reaper.GetExtState('network','ip')
local MAmode = reaper.GetExtState('console','mode')
local startupMode = 'Mode 3'
local prefix = reaper.GetExtState('network','prefix')
local consolePort = reaper.GetExtState('network','port')
local repositoryName = 'mittim88_ReaScript_Repository'
------MA 2 ---------------INPUTS---------------------------------------------------------------
local userName = reaper.GetExtState('network','userName')
------MA 2 + 3---------------INPUTS---------------------------------------------------------------
local cueListName = 'Test Cuelist'
local seqName = 'empty'
local seqID = tonumber(reaper.GetExtState('trackconfig', 'seqId'))
local seqBase = tonumber(reaper.GetExtState('trackconfig', 'seqId'))
if seqID == nil then
    seqID = 1
    seqBase = 1
end
local pageID = 'empty'
local execID = 'empty'
if MAmode == 'Mode 2' then
    pageID = reaper.GetExtState('trackconfig','pageId')
    execID = reaper.GetExtState('trackconfig','execId')
    if pageID == 'empty' then
        pageID = 1 
    end
    if execID == 'empty' then
        execID = 101
    end
end
local tcID = tonumber(reaper.GetExtState('trackconfig', 'tcId'))
if tcID == nil then
    tcID = 1
end
local fadetime = 2
local datapoolName = reaper.GetExtState('basic','dataPoolName')
local holdtime = '1.0'
local inputCueName = 'empty'
local cueNr = 1
local selectedBtnOption = ''
local selectedTrackOption = ''
local popups = {}
local standardTextwith = 50
local btnNames = { 
    'Cue List', 
    'Flash Button', 
    'Temp Button', 
    --'Top Button', 
    --'Top&Release' 
}
local selOptions = {'selected Track', 'all Tracks'}
local eventTime = '00:00:00:00'
local cursor = 0
local selectedOption = 'empty'
local liveupdatebox = false
local snapCursorbox = false
local loadProjectMarker = false
local cuesChecked = false
local seqChecked = false
local networkChecked = false
local shortcutsChecked = false
local textInputActive = false
local inputCueNameFieldActive = false
local dummyIPstring = '--Enter console IP--'
local tracks = {}
local loadedtracks = {}
local sendedData = {}
local dummytrack = {}
local clipboard = {}
local previousTrackGUID = nil
local oldusedTracks = nil
local eventAdded = false 
local eventRenamed = false
local mainDocked = false
local cueDocked = false
local trackDocked = false
local firstopened = false
local startup = false
local mainDockID = tonumber(reaper.GetExtState("TCHelper", "MainDockID")) or 0
local cueDockID = tonumber(reaper.GetExtState("TCHelper", "CueDockID")) or 0
local trackDockID = tonumber(reaper.GetExtState("TCHelper", "TrackDockID")) or 0
local selectedTrackOption = 'selected Track' -- Standardmäßig aktivierte Option
local pendingLiveUpdate = false
local lastLiveUpdateState = liveupdatebox
local manualCheck = false
local aboutWindowOpen = false
local openNewVersionWindow = false
local openOldVersionWindow = false
--extData--------------------------------------------------------------------------------------------
local selectedIcon = ''
local dataFolder = 'data/'
local iconFolder = 'images/'
local logoFolder = 'logo/'
local pdfFolder = 'pdf/'
local keyMapFolder = 'keyMap/'
local projectTemplateFolder = 'projectTemplate/'

local logoBigName = 'LogoBig_App1024x768.png'
local manualName = 'TCHelper Manual.pdf'
local keyMapName = 'TCHelper_Actions.ReaperKeyMap'
local projectTemplateName = 'TCHelper Project.RPP'

local BigLogoWidth = 130
local BigLogoHeight = 110
local BigLogoY = -10
local assigningShortcut = nil -- Speichert den TrackGUID, für den ein Shortcut zugewiesen wird
local trackShortcuts = trackShortcuts or {}
local globalShortcuts = globalShortcuts or { playPause = "P", createCue = "N" }
local trackShortcutsSafed = reaper.GetExtState('TCHelper', 'trackShortcutsSafed') or false
local globalShortcutsSafed = reaper.GetExtState('TCHelper', 'globalShortcutsSafed') or false
--------------------------------------------------------------- 
dummytrack.id = 'dummyTrackID'
dummytrack.name = 'dummySeqName'
dummytrack.execID = 'dummyExecID'
dummytrack.pageID = 'dummyPageID'
dummytrack.seqID = 'dummySeqID'
dummytrack.execoption = 'dummyExecOption'
dummytrack.cue = {}
dummytrack.cue.id = 'dummyCueID'
dummytrack.cue.name = 'dummyCueName'
dummytrack.cue.fadetime = 'dummyFadetime'
dummytrack.cue.holdtime = 'dummyHoldTime'
dummytrack.cue.itemStart = 'dummyitemStart'
dummytrack.cue.itemEnd = 'dummyitemEnd'
local trackIcon = {}
trackIcon.name = {}
trackIcon.name[1] = 'Cuelist.png'
trackIcon.name[2] = 'Flash.png'
trackIcon.name[3] = 'Temp.png'
trackIcon.name[4] = 'Top.png'
trackIcon.name[5] = 'Top Release.png'
local inputHH = 0
local inputMM = 0
local inputSS = 0
local inputFF = 0
local Color = {}
local loopback = reaper.GetExtState('console', '3onPC')

if loopback == nil then
    loopback = 'false'
end
local ma2Loopback = reaper.GetExtState('console', '2onPC')
if ma2Loopback == nil then
    ma2Loopback = 'false'
end
local addonCheck = true
local NewCueNames = {} 
local NewFadeTimes = {}
local PLOT1_SIZE = 90
local widgets = {}
widgets.plots = {
    animate = true,
    frame_times = reaper.new_array({ 0.6, 0.1, 1.0, 0.5, 0.92, 0.1, 0.2 }),
    plot1 = {
      offset       = 1,
      refresh_time = 0.0,
      phase        = 0.0,
      data         = reaper.new_array(PLOT1_SIZE),
    },
    plot2 = {
      func = 0,
      size = 70,
      fill = true,
      data = reaper.new_array(1),
    },
    progress     = 0.0,
    progress_dir = 1,
  }
------Setup SendedData Dummy Table
function InitiateSendedData()
    local usedTracks = readTrackGUID('used')
    for i = 1, #usedTracks, 1 do
      local itemGuid = readItemGUID(usedTracks[i])
      local trackID = reaper.BR_GetMediaTrackByGUID(0, usedTracks[i])
      local itemAmmount = reaper.CountTrackMediaItems(trackID)
      SetupSendedDataTrack(usedTracks[i])

        for j = 1, itemAmmount, 1 do
            SetupSendedDataItem(usedTracks[i],itemGuid[j])
        end
    end
    sendedData.TCsendedShow = false    
end
function SetupSendedDataTrack (trackGUID)
    sendedData[trackGUID] = {}
    sendedData[trackGUID].id = 'empty'
    sendedData[trackGUID].name = 'empty'
    sendedData[trackGUID].seqID = 'empty'
    sendedData[trackGUID].pageID = 'empty'
    sendedData[trackGUID].execID = 'empty'
    sendedData[trackGUID].execoption = 'empty'
    sendedData[trackGUID].trackNr = 'empty'
    sendedData[trackGUID].cue = {}
    sendedData[trackGUID].itemAmmount = 'empty'
    sendedData[trackGUID].TCsendedTrack = false
    sendedData[trackGUID].sended = false
    sendedData[trackGUID].tempCueSended = false
    sendedData[trackGUID].tempNameSended = false
    sendedData[trackGUID].tempFadeSended = false
end   
function SetupSendedDataItem (trackGUID,itemGUID)    
    sendedData[trackGUID].cue[itemGUID] = {}
    sendedData[trackGUID].cue[itemGUID].id = 'empty'
    sendedData[trackGUID].cue[itemGUID].sended = false
    sendedData[trackGUID].cue[itemGUID].name = 'empty'
    sendedData[trackGUID].cue[itemGUID].cuenr = 'empty'
    sendedData[trackGUID].cue[itemGUID].fadetime = 'empty'
    sendedData[trackGUID].cue[itemGUID].holdtime = 'empty'
    sendedData[trackGUID].cue[itemGUID].itemStart = 'empty'
    sendedData[trackGUID].cue[itemGUID].itemEnd = 'empty'
    sendedData[trackGUID].cue[itemGUID].TCid = 'empty'
    sendedData[trackGUID].cue[itemGUID].TCname = 'empty'
    sendedData[trackGUID].cue[itemGUID].token = 'empty'
end
---------------HTTP+XML--------------------------------------------------------------------
---------------DEFINE HTTP+XML TOOLS--------------------------------------------------------------------
-- LuaSocket HTTP implementation
local http_socket = {}
http_socket.http = {}
http_socket.http.request = function(params)
    local url = params.url
    local sink = params.sink

    local handle = io.popen("curl -s -w '%{http_code}' -o - " .. url)
    local result = handle:read("*a")
    handle:close()

    local code = tonumber(result:sub(-3))
    local content = result:sub(1, -4)

    sink(content)
    return 1, code
end
-- Simplified xml2lua implementation
local xml2lua = {}
xml2lua.parser = function(handler)
    return {
        parse = function(self, xmlContent)
            handler.root = {}
            for version in xmlContent:gmatch('<version name="(.-)"') do
                table.insert(handler.root, version)
            end
        end
    }
end
local handler = {}
---------------OSC--------------------------------------------------------------------
---------------DEFINE OSC TOOLS--------------------------------------------------------------------
local info = debug.getinfo(1, 'S');
local script_path = info.source:match [[^@?(.*[\/])[^\/]-$]];
package.cpath = package.cpath ..
    ";" ..
    reaper.GetResourcePath() ..
    '/Scripts/Mavriq ReaScript Repository/Various/Mavriq-Lua-Sockets/?.dll' -- Add current folder/socket module for looking at .dll
package.cpath = package.cpath ..
    ";" ..
    reaper.GetResourcePath() ..
    '/Scripts/Mavriq ReaScript Repository/Various/Mavriq-Lua-Sockets/?.so' -- Add current folder/socket module for looking at .so
package.path = package.path ..
    ";" .. reaper.GetResourcePath() .. '/Scripts/Mavriq ReaScript Repository/Various/Mavriq-Lua-Sockets/?.lua'
local socket = {}
local reqStatus ,lib = pcall(require, 'socket.core')
if reqStatus == true then
    socket = lib
else
    addonCheck = false
    reaper.ShowMessageBox("Missing Mavriq Lua Sockets\n Install it with Reapack:\nhttps://raw.githubusercontent.com/mavriq-dev/public-reascripts/master/index.xml", "Error", 0)
end
dofile(script_path .. '/osc.lua') -- Load OSC Functions made over LuaSockets for send/Receive OSC
----------------SETUP GUI-----------------------------------------------------------------------------------------------
local doStatus , lib = pcall(dofile, reaper.GetResourcePath()..'/Scripts/ReaTeam Extensions/API/imgui.lua')
local ctx = 'empty'
local sans_serif = 'empty'
if doStatus == true then
    local foo = lib
    dofile(reaper.GetResourcePath() ..
    '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.8')
    ctx = reaper.ImGui_CreateContext(script_title)
    sans_serif = reaper.ImGui_CreateFont('sans-serif', 16)
    reaper.ImGui_Attach(ctx, sans_serif)
else
    addonCheck = false
    reaper.ShowMessageBox('\nMissing GUI Package', 'Error', 0)
end
---------------Für Copy Paste API aus Demo File-------------
local ImGui = {}
local app = {}
local layout = {}
for name, func in pairs(reaper) do
    name = name:match('^ImGui_(.+)$')
    if name then ImGui[name] = func end
end
if not widgets.basic then
    widgets.basic = {
      clicked = 0,
      check   = true,
      radio   = 0,
      counter = 0,
      tooltip = reaper.new_array({ 0.6, 0.1, 1.0, 0.5, 0.92, 0.1, 0.2 }),
      curitem = 0,
      str0    = 'Hello, world!',
      str1    = '',
      vec4a   = reaper.new_array({ 0.10, 0.20, 0.30, 0.44 }),
      i0      = 123,
      i1      = 50,
      i2      = 42,
      i3      = 0,
      d0      = 999999.00000001,
      d1      = 1e10,
      d2      = 1.00,
      d3      = 0.0067,
      d4      = 0.123,
      d5      = 0.0,
      angle   = 0.0,
      elem    = 2,
      col1    = 0xff0033,   -- 0xRRGGBB
      col2    = 0x66b2007f, -- 0xRRGGBBAA
      listcur = 0,
    }
end
if MAmode == 'Mode 2' then
    widgets.basic.elem = 1
elseif MAmode == 'Mode 3' then
    widgets.basic.elem = 2
end
function checkSWS()
    local version = reaper.CF_GetSWSVersion()
    if version == nil then
        reaper.ShowMessageBox('\nSWS Addon not installed\nPlease Install SWS Extenstions:\nhttps://www.sws-extension.org', 'Error', 0)
        addonCheck = false
    end
    
end
-----------------BACKROUND STUFF-------------------------------------------------------------
function consoleMSG(x)
    reaper.ShowConsoleMsg(x..'\n')
end
function fetchXML(url)
    local response = {}
    local _, code = http_socket.http.request{
        url = url,
        sink = function(chunk)
            table.insert(response, chunk)
        end
    }
    --consoleMSG('code: '..code)

    if code ~= 200 then
        -- Fehlermeldung in die Konsole schreiben
        --reaper.ShowConsoleMsg("Unable to fetch XML content. Please check your internet connection or the URL.\n")
        return nil, code
    end

    return table.concat(response), code
end
function tableToString(tbl)
    local result = {}
    local function serialize(tbl, indent)
        for k, v in pairs(tbl) do
            local key = type(k) == "string" and string.format("%q", k) or tostring(k)
            if type(v) == "table" then
                table.insert(result, string.format("%s[%s] = {", indent, key))
                serialize(v, indent .. "  ")
                table.insert(result, string.format("%s},", indent))
            else
                local value = type(v) == "string" and string.format("%q", v) or tostring(v)
                table.insert(result, string.format("%s[%s] = %s,", indent, key, value))
            end
        end
    end
    table.insert(result, "{")
    serialize(tbl, "  ")
    table.insert(result, "}")
    return table.concat(result, "\n")
end
local notesWarned = false

local notesWarned = false

local notesWarned = false

function checkAndRestoreNotes()
    local anyWrong = false
    local usedTracks = readTrackGUID('used')
    for _, trackGUID in ipairs(usedTracks) do
        local itemGUIDs = readItemGUID(trackGUID)
        for _, itemGUID in ipairs(itemGUIDs) do
            local item = reaper.BR_GetMediaItemByGUID(0, itemGUID)
            if item and loadedtracks[trackGUID] and loadedtracks[trackGUID].cue and loadedtracks[trackGUID].cue[itemGUID] then
                local cue = loadedtracks[trackGUID].cue[itemGUID]
                local cueName = cue and cue.name or ""
                local execoption = loadedtracks[trackGUID].execoption or ""
                local cuenr = cue and cue.cuenr or ""
                local fadetime = cue and cue.fadetime or ""
                local holdtime = cue and cue.holdtime or ""

                local expectedNotes = ""
                if execoption == "Cue List" then
                    expectedNotes = "|" .. cueName .. "|\n|" .. execoption .. "|\n|Cue: " .. cuenr .. "|\n|Fadetime: " .. fadetime .. "|"
                elseif execoption == "Flash Button" or execoption == "Temp Button" then
                    expectedNotes = "|" .. cueName .. "|\n|" .. execoption .. "|\n|Press: " .. cuenr .. "|\n|Fadetime: " .. fadetime .. "|\n|Hold: " .. holdtime .. "|"
                end

                local rv, currentNotes = reaper.GetSetMediaItemInfo_String(item, "P_NOTES", "", false)
                if type(currentNotes) ~= "string" then currentNotes = "" end

                -- Wenn die Note leer ist oder nicht exakt dem erwarteten Wert entspricht, wiederherstellen
                if currentNotes ~= expectedNotes then
                    reaper.GetSetMediaItemInfo_String(item, "P_NOTES", expectedNotes, true)
                    -- Nochmals prüfen, ob die Wiederherstellung erfolgreich war
                    local rv2, newNotes = reaper.GetSetMediaItemInfo_String(item, "P_NOTES", "", false)
                    if type(newNotes) ~= "string" then newNotes = "" end
                    if newNotes ~= expectedNotes then
                        anyWrong = true
                    end
                end
            end
        end
    end

    -- Nur warnen, wenn mindestens ein Fehler gefunden wurde und noch nicht gewarnt wurde
    if anyWrong and not notesWarned then
        reaper.ShowMessageBox("Bitte ändere die Notes eines Cues nicht direkt!\nNutze stattdessen das Cue Window in TCHelper.", "Warnung", 0)
        notesWarned = true
    elseif not anyWrong then
        notesWarned = false
    end
end
-- Deserialisiert einen String in eine Tabelle
function stringToTable(str)
    local func = load("return " .. str)
    if func then
        return func()
    else
        return nil
    end
end
function checkForNewVersion(currentVersion, xmlContent)
    if not xmlContent then
        if manualCheck then
            reaper.ShowMessageBox("Unable to check for updates.\nPlease check your internet connection", "Error", 0)
        end
        return
    end

    local parser = xml2lua.parser(handler)
    parser:parse(xmlContent)
    local versions = handler.root
    if not versions then
        reaper.ShowMessageBox("No versions found.", "Info", 0)
        return
    end

    local function split(version)
        local t = {}
        for part in version:gmatch("(%d+)") do
            table.insert(t, tonumber(part))
        end
        return t
    end

    local function isNewerVersion(currentVersion, latestVersion)
        local current = split(currentVersion)
        local latest = split(latestVersion)

        for i = 1, math.max(#current, #latest) do
            if (latest[i] or 0) > (current[i] or 0) then
                return true
            elseif (latest[i] or 0) < (current[i] or 0) then
                return false
            end
        end
        return false
    end

    local latestVersion = versions[#versions] -- Letzte Version im Table
    if isNewerVersion(currentVersion, latestVersion) then
        if manualCheck then
            ShowNewVersionUpdateWindow(latestVersion)
            openNewVersionWindow = true
        else
            openNewVersionWindow = true
        end
    else
        if manualCheck then
            openOldVersionWindow = true
        end
    end
    return latestVersion
end
function manualUpdate()
    local xmlContent, code = fetchXML(page)
    if xmlContent then
        manualCheck = true
        checkForNewVersion(version, xmlContent)
    else
        reaper.ShowMessageBox("Unable to check for updates.\nPlease check yoour internet connection", "Error", 0)
    end
end
function drawCenteredButton(ctx, text, buttonWidth, buttonHeight)
    local lines = {}
    for line in text:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    local maxWidth = 0
    for _, line in ipairs(lines) do
        local width = reaper.ImGui_CalcTextSize(ctx, line)
        if width > maxWidth then
            maxWidth = width
        end
    end

    local windowWidth = reaper.ImGui_GetWindowSize(ctx)
    local startX = (windowWidth - buttonWidth) / 2

    reaper.ImGui_SetCursorPosX(ctx, startX)
    if reaper.ImGui_Button(ctx, "", buttonWidth, buttonHeight) then
        return true
    end

    for i, line in ipairs(lines) do
        local lineWidth = reaper.ImGui_CalcTextSize(ctx, line)
        local lineX = startX + (buttonWidth - lineWidth) / 2
        local lineY = reaper.ImGui_GetCursorPosY(ctx) + (buttonHeight / #lines) * (i - 1)
        reaper.ImGui_SetCursorPos(ctx, lineX, lineY)
        reaper.ImGui_Text(ctx, line)
    end

    return false
end
function defineBash()
    local platform = reaper.GetOS()
    local system = 'empty'
    local bash = 'empty'
    local winBash = 'cmd.exe /C '
    local macBash = "/bin/sh -c "
    if platform == 'Win64' then
        bash = winBash
        system = 'win'
    elseif platform == 'Win32' then
        bash = winBash
        system = 'win'
    elseif platform == 'OSX32' then
        bash = macBash
        system = 'macOS'
    elseif platform == 'OSX64' then
        bash = macBash
        system = 'macOS'
    elseif platform == 'macOS-arm64' then
        bash = macBash
        system = 'macOS'
    else
        consoleMSG('NO SUPPORTED OS')
    end
return bash,system
end
function replaceSpecialCharacters(inputString)
    local replacements = {
        { "ä", "ae" },
        { "ö", "oe" },
        { "ü", "ue" },
        { "Ä", "Ae" },
        { "Ö", "Oe" },
        { "Ü", "Ue" }
    }

    for _, replacement in ipairs(replacements) do
        inputString = string.gsub(inputString, replacement[1], replacement[2])
    end

    return inputString
end
function checkDuplicateCueNames()
    getTrackContent()
    local trackGUID = readTrackGUID('selected')
    local nameCount = {}
    
    local execoption = loadedtracks[trackGUID].execoption or 'unknown'
    if execoption == 'Cue List' then
        local itemGUIDs = readItemGUID(trackGUID)
        for j = 1, #itemGUIDs do
            local track = loadedtracks[trackGUID]
            if track and track.cue and track.cue[itemGUIDs[j]] then
                local cueName = track.cue[itemGUIDs[j]].name
                -- Entferne den Index, falls vorhanden
                local baseName = cueName:match("^(.-) %(%d+%)$") or cueName:match("^(.-) %-%d+$") or cueName:match("^(.-) %d+$") or cueName
                if not nameCount[baseName] then
                    nameCount[baseName] = 1
                else
                    nameCount[baseName] = nameCount[baseName] + 1
                    local newCueName = baseName .. ' '.. nameCount[baseName]
                    local oldCue = track.cue[itemGUIDs[j]]
                    track.cue[itemGUIDs[j]].name = newCueName
                    local newItemName = '|' .. newCueName .. '|\n|' .. execoption .. '|\n|Cue: ' .. oldCue.cuenr .. '|\n|Fadetime: ' .. oldCue.fadetime .. '|'
                    reaper.GetSetMediaItemInfo_String(reaper.BR_GetMediaItemByGUID(0, itemGUIDs[j]), "P_NOTES", newItemName, true)
                end
            end
        end
    end
    getTrackContent()
end
function sleep (a) 
    local sec = tonumber(os.clock() + a); 
    while (os.clock() < sec) do 
    end 
end
function checkSeqInfo()
    local seqCheckname = {}
    local seqCheckID = {}
    local check = false
    local usedTracks = readTrackGUID('used')

    for i = 1, #usedTracks, 1 do
        seqCheckname[i] = loadedtracks[usedTracks[i]].name
        seqCheckID[i] = loadedtracks[usedTracks[i]].seqID
        for j = 1, #usedTracks do
            if seqCheckname[i] == loadedtracks[usedTracks[j]].name and i ~= j then
                reaper.ShowConsoleMsg('\nDoppelter SeqName:'..seqCheckname[i])
                reaper.ShowConsoleMsg('\n:Track'..i)
                reaper.ShowConsoleMsg('\n:Track'..j)
                check = true
            end
            if seqCheckID[i] == loadedtracks[usedTracks[j]].seqID and i ~= j then
                reaper.ShowConsoleMsg('\nDoppelter SeqID:'..seqCheckID[i])
                reaper.ShowConsoleMsg('\n:Track'..i)
                reaper.ShowConsoleMsg('\n:Track'..j)
                check = true
                check = true
            end
        end
    end
    return check
end
function readTrackGUID(token)
    local tracknum = reaper.GetNumTracks(0)
    local trackcount = 1
    local trackGUID = {}
    local check = '|'
    if token == 'all' then
        --reaper.ShowConsoleMsg('\nall')
        for i = 0, tracknum - 1 do
            local trackID = reaper.GetTrack(0, i)
            local loadedGUID = reaper.GetTrackGUID(trackID)
            trackGUID[trackcount] = loadedGUID
            trackcount = trackcount + 1
        end
        return trackGUID 
    elseif token == 'used' then

        for i = 0, tracknum - 1 do
            local trackID = reaper.GetTrack(0, i)
            local retval, name = reaper.GetTrackName(trackID)
            local checkname = string.sub(name, 1, 1) --hier wird das erste Zeichen vom TrackLabel ausgelesen
            local trackIcon = ''
            local rv = ''
            local trackIcon = ''
            rv, trackIcon = reaper.GetSetMediaTrackInfo_String(trackID, 'P_ICON', trackIcon, false)
            if rv == true then
                if checkname == check then --WENN das erste Zeichen dem Check aus Zeile 94 entspricht UND ein Icon an den Track angefügt ist wird der Track ausgelesen und im Daten Table gespeichert
                    local loadedGUID = reaper.GetTrackGUID(trackID)
                    trackGUID[trackcount] = loadedGUID
                    trackcount = trackcount + 1
                else
                    i = i + 1
                end
            else
                i = i + 1
            end
        end
        return trackGUID 
    elseif token == 'selected' then

        --reaper.ShowConsoleMsg('\nseleceted')
        local selectedTrack = reaper.GetSelectedTrack(0, 0)
        if selectedTrack ~= nil then

            local loadedGUID = reaper.GetTrackGUID(selectedTrack)
            trackGUID[1] = loadedGUID
        else
            if track1 ~= nil then
                local track1 = reaper.GetTrack(0, 0)
                local loadedGUID = reaper.GetTrackGUID(track1)
                trackGUID[1] = loadedGUID
                noTrackError()  
            end
        end
        return trackGUID[1]
    end
end
function readItemGUID(trackGUID)
    local trackID = reaper.BR_GetMediaTrackByGUID(0, trackGUID)
    if trackID ~= nil then
        local itemAmmount = reaper.CountTrackMediaItems(trackID)
        local itemGUID = {}
        local count = 1
        for i = 0, itemAmmount - 1, 1 do
            local mediaItem = reaper.GetTrackMediaItem(trackID, i)
            if mediaItem ~= nil then
                local rv, loadedGUID = reaper.GetSetMediaItemInfo_String(mediaItem, "GUID", "", false)
                itemGUID[count] = loadedGUID
                count = count + 1
        
            end
            --reaper.ShowConsoleMsg('\nREADITEMGUID FUNCTION'..itemGUID[count])
        end
        return itemGUID
    end
end
function getSelectedItemGUID()
    local selectedItem = reaper.GetSelectedMediaItem(0, 0) -- Get the first selected item
    local GUID = reaper.BR_GetMediaItemGUID(selectedItem)
    return GUID
end
function getCursorPosition()
    cursor = reaper.GetCursorContext2(true)
end
function getSelectedOption()
    local oldTrack = 'empty'
    if cursor == 1 then
        local selectedTrack = readTrackGUID('selected')
        if loadedtracks[selectedTrack] ~= nil then
            if oldTrack ~= selectedTrack then
                if loadedtracks[selectedTrack].execoption == 'Cue List' then
                    selectedOption = 'Cue List'
                elseif loadedtracks[selectedTrack].execoption == 'Flash Button' then
                    selectedOption = 'Flash Button'
                elseif loadedtracks[selectedTrack].execoption == 'Temp Button' then
                    selectedOption = 'Temp Button'
                end
                --reaper.ShowConsoleMsg('\nSelected Btn Option: '..selectedOption..'   '..selectedTrack)
                oldTrack = selectedTrack
            end
        end
    end
end
function getTrackContent() 
    local check = '|'
    local trackAmmount = reaper.GetNumTracks()
    local trackcount = 1
    for i = 0, trackAmmount - 1, 1 do
        --TRACKINFOS------------------------------------------------------------
        local trackID = reaper.GetTrack(0, i)
        local word = {}
        local retval, name = reaper.GetTrackName(trackID)
        local itemAmmount = reaper.CountTrackMediaItems(trackID)
        local checkname = string.sub(name, 1, 1) --hier wird das erste Zeichen vom TrackLabel ausgelesen
        local trackIcon = ''
        local rv = ''
        rv, trackIcon = reaper.GetSetMediaTrackInfo_String(trackID, 'P_ICON', trackIcon, false)
        if rv == true then
            if checkname == check then --WENN das erste Zeichen dem Check aus Zeile 94 entspricht UND ein Icon an den Track angefügt ist wird der Track ausgelesen und im Daten Table gespeichert
                local loadedTrackGUID = {}
                local tGC = i + 1
                loadedTrackGUID[tGC] = reaper.GetTrackGUID(trackID)
                for w in string.gmatch(name, "[^|]+") do
                    table.insert(word, w)
                end
                if loadedtracks[loadedTrackGUID[tGC]] == nil then
                    loadedtracks[loadedTrackGUID[tGC]] = {}
                end
                local seqNr = word[2]:gsub("%D", "")
                local tcNr = word[4]:gsub("%D", "")
                local pageNr = 'empty'
                local execNr = 'empty'
                if MAmode == 'Mode 2' then
                    pageNr = word[5]:gsub("%D", "")
                    execNr = word[6]:gsub("%D", "")
                    
                end
                loadedtracks.TCsendedShow = true
                loadedtracks[loadedTrackGUID[tGC]].id = loadedTrackGUID[tGC]
                loadedtracks[loadedTrackGUID[tGC]].nr = tGC
                loadedtracks[loadedTrackGUID[tGC]].name = word[1]
                loadedtracks[loadedTrackGUID[tGC]].seqID = seqNr
                loadedtracks[loadedTrackGUID[tGC]].execoption = word[3]
                loadedtracks[loadedTrackGUID[tGC]].trackNr = tGC
                loadedtracks[loadedTrackGUID[tGC]].tcID = tcNr
                loadedtracks[loadedTrackGUID[tGC]].TCsendedTrack = true
                loadedtracks[loadedTrackGUID[tGC]].sended = true
                loadedtracks[loadedTrackGUID[tGC]].itemAmmount = itemAmmount
                if MAmode == 'Mode 2' then
                    loadedtracks[loadedTrackGUID[tGC]].pageID = pageNr
                    loadedtracks[loadedTrackGUID[tGC]].execID = execNr
                end
                loadedtracks[loadedTrackGUID[tGC]].cue = {}
                --MEDIA ITEM INFOS-------------------------------------------------------
                local loadedItemGUID = {}
                local rv = ''
                local itemammount = reaper.CountTrackMediaItems(trackID)
                local iGC = 1
                local item = 'empty'
                local itemword = {}
                for j = 0, itemammount - 1, 1 do
                    itemword[iGC] = {}
                    local itemName = 'empty'
                    item = reaper.GetTrackMediaItem(trackID, j)
                    local rv, itemGUID = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)
                    loadedItemGUID[iGC] = itemGUID
                    if loadedtracks[loadedTrackGUID[tGC]].cue[loadedItemGUID[iGC]] == nil then
                        loadedtracks[loadedTrackGUID[tGC]].cue[loadedItemGUID[iGC]] = {}
                    end
                    rv, itemName = reaper.GetSetMediaItemInfo_String(item, 'P_NOTES', itemName, false)
                    for w in string.gmatch(itemName, "|([^|]+)|") do
                        --reaper.ShowConsoleMsg('\n+'..w..'-')
                        table.insert(itemword[iGC], w)
                    end

                    local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                    local offset = reaper.GetProjectTimeOffset(0, false)
                    itemStart = itemStart + offset 
                    local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                    local fadetime = itemword[iGC][4]:gsub("%D", "") or 0
                    local cueNr = itemword[iGC][3]:gsub("%D", "")

                    --loadedtracks[loadedTrackGUID[tGC]].cue[loadedItemGUID[iGC]] = {}
                    loadedtracks[loadedTrackGUID[tGC]].cue[loadedItemGUID[iGC]].id = loadedItemGUID[iGC]
                    loadedtracks[loadedTrackGUID[tGC]].cue[loadedItemGUID[iGC]].name = itemword[iGC][1]
                    loadedtracks[loadedTrackGUID[tGC]].cue[loadedItemGUID[iGC]].cuenr = cueNr
                    loadedtracks[loadedTrackGUID[tGC]].cue[loadedItemGUID[iGC]].fadetime = fadetime
                    loadedtracks[loadedTrackGUID[tGC]].cue[loadedItemGUID[iGC]].holdtime = itemLength
                    loadedtracks[loadedTrackGUID[tGC]].cue[loadedItemGUID[iGC]].itemStart = itemStart
                    loadedtracks[loadedTrackGUID[tGC]].cue[loadedItemGUID[iGC]].itemEnd = itemStart + itemLength
                    loadedtracks[loadedTrackGUID[tGC]].cue[loadedItemGUID[iGC]].TCid = loadedItemGUID[iGC]
                    loadedtracks[loadedTrackGUID[tGC]].cue[loadedItemGUID[iGC]].TCname = true
                    loadedtracks[loadedTrackGUID[tGC]].cue[loadedItemGUID[iGC]].token = word[5]
                    iGC = iGC + 1
                end
                tGC = tGC + 1
            else
                i = i + 1
            end
            i = i + 1
        end
        trackcount = trackcount + 1
    end
end
function checkItemStatus()
    local trackGUID = readTrackGUID('used')
    for i = 1, #trackGUID, 1 do
        if sendedData[trackGUID[i]] and sendedData[trackGUID[i]].cue then
            local itemGUID = readItemGUID(trackGUID[i])
            for j = 1, #itemGUID do
                if sendedData[trackGUID[i]].cue[itemGUID[j]] and sendedData[trackGUID[i]].cue[itemGUID[j]].id == nil then
                    SetupSendedDataItem(trackGUID[i], itemGUID[j])
                end
            end
        else
            -- Initialisiere die fehlenden Daten, falls sie nicht existieren
            if not sendedData[trackGUID[i]] then
                SetupSendedDataTrack(trackGUID[i])
            end
        end
    end
end
function checkIfTrackSelected()
    -- Get the total number of tracks in the project
    local numTracks = reaper.CountTracks(0)
    -- Variable to keep track of whether any track is selected
    local anyTrackSelected = false
    -- Iterate through all tracks and check if any are selected
    for i = 0, numTracks - 1 do
        local track = reaper.GetTrack(0, i)
        if reaper.IsTrackSelected(track) then
            
            anyTrackSelected = true
            break  -- Exit the loop once a selected track is found
        end
    end
    return anyTrackSelected
end
function Color.HSV(h, s, v, a)
    local r, g, b = ImGui.ColorConvertHSVtoRGB(h, s, v)
    return ImGui.ColorConvertDouble4ToU32(r, g, b, a or 1.0)
  end
function getItemCount(GUID)

    if GUID == nil then
        local selectedTrack = 'noTrack'
        selectedTrack = reaper.GetSelectedTrack(0, 0)
        if selectedTrack == nil then
            itemCount = 0
        else
            itemCount = reaper.CountTrackMediaItems(selectedTrack)
        end
    else
        local trackID = reaper.BR_GetMediaTrackByGUID(0, GUID)
        if trackID ~= nil then
            itemCount = reaper.CountTrackMediaItems(trackID)
        else
            itemCount = 0
        end
    end
    return itemCount
end
function getLongestTrackTime()
    local longestLength = reaper.GetProjectLength(0)
    return longestLength
end
function copy3(obj, seen)

    -- Handle non-tables and previously-seen tables.

    if type(obj) ~= 'table' then return obj end

    if seen and seen[obj] then return seen[obj] end



  -- New table; mark it as seen and copy recursively.

  local s = seen or {}

  local res = {}

  s[obj] = res

  for k, v in pairs(obj) do res[copy3(k, s)] = copy3(v, s) end

  return setmetatable(res, getmetatable(obj))

end
function getFirstTouchedMediaItem()
    local numSelectedItems = reaper.CountSelectedMediaItems(0)
    if numSelectedItems > 0 then
        -- Loop through all selected items
        for i = 0, numSelectedItems - 1 do
            local item = reaper.GetSelectedMediaItem(0, i)
            local isTouched = reaper.GetMediaItemInfo_Value(item, "B_UISEL")
            if isTouched == 1 then
                return item
            end
        end
    end
    return nil -- No touched items found
end
function getCueNames()
    local trackID = readTrackGUID('selected')
    local selectedTrack = 'noTrack'
    selectedTrack = reaper.GetSelectedTrack(0, 0)
    local itemCount = 0
    local cueGUIDs = 'empty'

    if selectedTrack == nil then
        itemCount = 0
    else
        itemCount = reaper.CountTrackMediaItems(selectedTrack)
        cueGUIDs = readItemGUID(trackID)
    end
    local oldCueName = {}
    for i = 1, itemCount, 1 do
        if loadedtracks[trackID] and loadedtracks[trackID].cue[cueGUIDs[i]] then
            oldCueName[i] = loadedtracks[trackID].cue[cueGUIDs[i]].name or 'empty'
        else
            oldCueName[i] = 'empty'
        end
    end
    return oldCueName
end
function getSeqNames () 
    local newSeqNames = {}
    local usedTracks = readTrackGUID('used')
    for i = 1, #usedTracks, 1 do
        newSeqNames[i] = loadedtracks[usedTracks[i]].name
    end
    return newSeqNames
end
function getFadeTimes()
    local trackID = readTrackGUID('selected')
    local selectedTrack = 'noTrack'
    selectedTrack = reaper.GetSelectedTrack(0, 0)
    local itemCount = 0
    local cueGUIDs = 'empty'

    if selectedTrack == nil then
        itemCount = 0
    else
        itemCount = reaper.CountTrackMediaItems(selectedTrack)
        cueGUIDs = readItemGUID(trackID)
    end
    local oldFadeTime = {}
    for i = 1, itemCount, 1 do
        if loadedtracks[trackID] and loadedtracks[trackID].cue[cueGUIDs[i]] then
            oldFadeTime[i] = loadedtracks[trackID].cue[cueGUIDs[i]].fadetime or 0
        else
            oldFadeTime[i] = 0
        end
    end
    return oldFadeTime
end
function ensureUniqueSeqName(seqName, existingNames)
    -- Falls der Name bereits existiert, füge eine Nummer an
    local uniqueName = seqName
    local counter = 2
    while existingNames[uniqueName] do
        uniqueName = seqName .. " -" .. counter
        counter = counter + 1
    end

    -- Füge den eindeutigen Namen zur Liste der bestehenden Namen hinzu
    existingNames[uniqueName] = true
    return uniqueName
end
function checkTCHelperTracks()
    local selTrack = readTrackGUID('selected')
    local tcHelperTracks = readTrackGUID('used')
    local trackCheck = false
    if selTrack == nil then
        --reaper.ShowMessageBox('\nNo Track selected\nPlease select your desired Track', 'Error', 0)
    else
        for i = 0, #tcHelperTracks do
            if tcHelperTracks[i] == selTrack then
                trackCheck = true
                break
            else
                trackCheck = false
                
            end
        end
        if trackCheck == true then
            return trackCheck
        else
            local rv = reaper.ShowMessageBox('\nNo TC Helper Track selected\nPlease select your desired Track', 'Error', 0)
            if rv == 1 then
                -- Definiere die GUID des Tracks, den du auswählen möchtest
                local track_guid_to_select = tcHelperTracks[1]

                -- Hole die Anzahl der Tracks im Projekt
                local track_count = reaper.CountTracks(0)

                -- Durchlaufe alle Tracks im Projekt
                for i = 0, track_count - 1 do
                    -- Hole den aktuellen Track
                    local track = reaper.GetTrack(0, i)

                    -- Hole die GUID des Tracks
                    local guid = reaper.GetTrackGUID(track)

                    -- Überprüfe, ob die GUID mit der gewünschten GUID übereinstimmt
                    if guid == track_guid_to_select then
                        -- Wähle den Track aus
                        reaper.SetOnlyTrackSelected(track)
                        --reaper.ShowMessageBox("Track mit GUID '" .. track_guid_to_select .. "' wurde ausgewählt.", "Erfolg", 0)
                        break
                    end
                end

                -- Aktualisiere die GUI und die Arrange-Ansicht
                reaper.UpdateArrange()
            end
            return trackCheck
        end
    end
end
function mergeDataOption()
    if loadProjectMarker == false then
        sendedData = copy3(loadedtracks)
        loadProjectMarker = true
    end
    checkItemStatus()
    local OscCommands = setOSCcommand()
    sendToConsole(hostIP, consolePort, OscCommands)
end
function defineMA3ModeOnFirstStrartup()
    if MAmode == '' then
        MAmode = startupMode
        reaper.SetExtState('console','mode', startupMode, true )
    end
end
function copySelectedItems()
    getTrackContent()
    -- Leere die Zwischenablage
    clipboard = {}

    -- Anzahl der Tracks im Projekt
    local numTracks = reaper.CountTracks(0)

    -- Schleife durch alle Tracks
    for trackIndex = 0, numTracks - 1 do
        local track = reaper.GetTrack(0, trackIndex)
        local trackGUID = reaper.GetTrackGUID(track)
        -- Anzahl der ausgewählten Media-Items im aktuellen Track
        local numSelectedItems = reaper.CountTrackMediaItems(track)

        -- Schleife durch alle ausgewählten Media-Items im aktuellen Track
        for itemIndex = 0, numSelectedItems - 1 do
            local mediaItem = reaper.GetTrackMediaItem(track, itemIndex)
            if reaper.IsMediaItemSelected(mediaItem) then
                local rv, itemGUID = reaper.GetSetMediaItemInfo_String(mediaItem, "GUID", "", false)
                table.insert(clipboard, {guid = itemGUID, trackGUID = trackGUID})
            end
        end
    end

    -- Ausgabe zur Bestätigung
    --reaper.ShowConsoleMsg("Kopierte " .. #clipboard .. " Events in die Zwischenablage.\n")
end
function pasteItems()
    getTrackContent()

    -- Überprüfen, ob die Zwischenablage leer ist
    if #clipboard == 0 then
        reaper.ShowMessageBox("Clipboard is empty", "Error", 0)
        return
    end

    -- Aktuelle Play-Cursor-Position
    local cursorPos = reaper.GetCursorPosition()

    -- Schleife durch alle kopierten Media-Items
    for i, itemData in ipairs(clipboard) do
        local itemGUID = itemData.guid
        local originalTrackGUID = itemData.trackGUID

        -- Original-Item finden
        local originalItem = reaper.BR_GetMediaItemByGUID(0, itemGUID)
        if not originalItem then
            reaper.ShowMessageBox("Original item not found for GUID: " .. tostring(itemGUID), "Error", 0)
            return
        end

        -- Original-Startzeit und Länge
        local originalStart = reaper.GetMediaItemInfo_Value(originalItem, "D_POSITION")
        local originalLength = reaper.GetMediaItemInfo_Value(originalItem, "D_LENGTH")

        -- Neue Startzeit basierend auf der Cursor-Position und dem Timing-Abstand
        local newStart = cursorPos + (originalStart - reaper.GetMediaItemInfo_Value(reaper.BR_GetMediaItemByGUID(0, clipboard[1].guid), "D_POSITION"))

        -- Neues Media-Item erstellen
        local trackID = reaper.BR_GetMediaTrackByGUID(0, originalTrackGUID)
        if not trackID then
            reaper.ShowMessageBox("Track not found for GUID: " .. tostring(originalTrackGUID), "Error", 0)
            return
        end

        local newItem = reaper.AddMediaItemToTrack(trackID)
        if newItem then
            -- Setze die Position und Länge des neuen Items
            reaper.SetMediaItemInfo_Value(newItem, "D_POSITION", newStart)
            reaper.SetMediaItemInfo_Value(newItem, "D_LENGTH", originalLength)

            -- Kopiere die Notizen vom Original-Item
            local rv, notes = reaper.GetSetMediaItemInfo_String(originalItem, "P_NOTES", "", false)
            reaper.GetSetMediaItemInfo_String(newItem, "P_NOTES", notes, true)
        else
            reaper.ShowMessageBox("Failed to create new media item", "Error", 0)
            return
        end
    end

    -- Aktualisiere die Track-Inhalte und überprüfe auf doppelte Namen
    checkDuplicateCueNames()
    getTrackContent()
    eventAdded = true
end
function openPDFManual()
    local rv, script_path = isInstalledViaReapack()
    local pdf_path = script_path..dataFolder..pdfFolder..manualName
    local os_name = reaper.GetOS()
    if os_name:find("OSX") or os_name:find("macOS") then
        os.execute('open "' .. pdf_path .. '"')
    elseif os_name:find("Win") then
        os.execute('start "" "' .. pdf_path .. '"')
    elseif os_name:find("Linux") then
        os.execute('xdg-open "' .. pdf_path .. '"')
    else
        reaper.ShowMessageBox("Unsupported OS: " .. os_name, "Error", 0)
    end
end
function refreshAndBrowseTCHelper()
    reaper.ReaPack_BrowsePackages('TCHelper')
    reaper.ReaPack_ProcessQueue(true)

end
function isInstalledViaReapack()
    -- Hole den Pfad des aktuellen Skripts
    local script_path = ({reaper.get_action_context()})[2]

    -- Extrahiere den Ordnerpfad
    local script_folder = script_path:match("^(.*[\\/])")

    -- Überprüfe, ob ReaPack verfügbar ist
    if not reaper.ReaPack_GetOwner then
        reaper.ShowConsoleMsg('ReaPack ist nicht installiert oder die API ist nicht verfügbar\n')
        return false
    end

    -- Hole den Besitzer des aktuellen Skripts (ReaPack-Paket)
    local owner = reaper.ReaPack_GetOwner(script_path)
    if owner then
        -- reaper.ShowConsoleMsg('Script is installed via ReaPack\n')
        -- reaper.ShowConsoleMsg('Script path: ' .. script_path .. '\n')
        -- reaper.ShowConsoleMsg('Script folder: ' .. script_folder .. '\n')

        return true, script_folder
    else
        -- reaper.ShowConsoleMsg('Script is not installed via ReaPack\n')
        -- reaper.ShowConsoleMsg('Script path: ' .. script_path .. '\n')
        -- reaper.ShowConsoleMsg('Script folder: ' .. script_folder .. '\n')
        return false, script_folder
    end
end
function copyReaperTemplate()
    local reaperPath = reaper.GetResourcePath()
    local rv, script_Path = isInstalledViaReapack()
    -- Pfade der Quelldateien
    local keyMapSource = script_Path .. dataFolder .. keyMapFolder .. keyMapName
    local projectTemplateSource = script_Path .. dataFolder .. projectTemplateFolder .. projectTemplateName

    -- Pfade der Zielverzeichnisse
    local keyMapDestination = reaperPath .. "/KeyMaps/"
    local projectTemplateDestination = reaperPath .. "/ProjectTemplates/"
    -- consoleMSG('KeyMapSource: '..keyMapSource)
    -- consoleMSG('KeyMapDestination: '..keyMapDestination)
    -- consoleMSG('ProjectTemplateSource: '..projectTemplateSource)
    -- consoleMSG('ProjectTemplateDestination: '..projectTemplateDestination)
    
    -- Kopiere die Dateien
    copyFile(keyMapSource, keyMapDestination)
    copyFile(projectTemplateSource, projectTemplateDestination)
    
    --reaper.ShowMessageBox("Dateien erfolgreich kopiert.", "Erfolg", 0)
end
function copyFile(source, destination)
    local os_name = reaper.GetOS()
    local command

    if os_name:find("OSX") or os_name:find("macOS") then
        command = string.format('cp "%s" "%s"', source, destination)
    elseif os_name:find("Win") then
        command = string.format('copy "%s" "%s"', source:gsub("/", "\\"), destination:gsub("/", "\\"))
    elseif os_name:find("Linux") then
        command = string.format('cp "%s" "%s"', source, destination)
    else
        reaper.ShowMessageBox("Unsupported OS: " .. os_name, "Error", 0)
        return
    end

    local result = os.execute(command)
    -- if result ~= 0 then
    --     reaper.ShowMessageBox("Fehler beim Kopieren der Datei: " .. source.. ' nach: '..destination, "Fehler", 0)
    -- end
end
function checkShortcuts()
    trackShortcuts = trackShortcuts or {}
    -- Verhindere das Erstellen von Events, wenn ein Shortcut zugewiesen wird
    if assigningShortcut then return end
    if textInputActive then return end
    -- Initialisiere globalShortcuts, falls sie nicht existiert
    globalShortcuts = globalShortcuts or { playPause = "P", createCue = "N" }
    -- Track-Shortcuts prüfen
    local usedTracks = readTrackGUID("used")
    for _, trackGUID in ipairs(usedTracks) do
        local assignedKey = trackShortcuts[trackGUID]
        if assignedKey then
            local imguiKeyFunc = reaper["ImGui_Key_" .. assignedKey]
            if imguiKeyFunc and reaper.ImGui_IsKeyPressed(ctx, imguiKeyFunc()) then
                -- Füge ein Cue zum Track hinzu, auch wenn kein Track ausgewählt ist
                addItem(trackGUID)
                return
            end
        end
    end

    -- Shortcut für Play/Pause
    if globalShortcuts.playPause then
        local playPauseKeyFunc = reaper["ImGui_Key_" .. globalShortcuts.playPause]
        if playPauseKeyFunc and reaper.ImGui_IsKeyPressed(ctx, playPauseKeyFunc()) then
            togglePlayPause()
        end
    end

    -- Shortcut für das Erstellen eines Cues im ausgewählten Track
    if globalShortcuts.createCue then
        local createCueKeyFunc = reaper["ImGui_Key_" .. globalShortcuts.createCue]
        if createCueKeyFunc and reaper.ImGui_IsKeyPressed(ctx, createCueKeyFunc()) then
            createCueInSelectedTrack()
        end
    end
end
function saveShortcuts()
    trackShortcuts = trackShortcuts or {}
    local serializedShortcuts = tableToString(trackShortcuts)
    reaper.SetExtState("TCHelper", "TrackShortcuts", serializedShortcuts, true)
    reaper.SetExtState("TCHelper", "trackShortcutsSafed", "true", true)
end
function loadShortcuts()
    -- Initialisiere trackShortcuts, falls sie nicht existiert
    trackShortcuts = trackShortcuts or {}

    local serializedShortcuts = reaper.GetExtState("TCHelper", "TrackShortcuts")
    local userDefined = reaper.GetExtState("TCHelper", "trackShortcutsSafed")

    if serializedShortcuts and serializedShortcuts ~= "" and userDefined == "true" then
        -- Benutzer hat eigene Shortcuts gespeichert → lade diese
        trackShortcuts = stringToTable(serializedShortcuts)
    else
        -- Noch keine eigenen Shortcuts gespeichert → Standard-Shortcuts 1-9 für die ersten 9 used Tracks
        local defaultKeys = {"1", "2", "3", "4", "5", "6", "7", "8", "9"}
        local usedTracks = readTrackGUID("used")
        for i, trackGUID in ipairs(usedTracks) do
            if defaultKeys[i] then
                trackShortcuts[trackGUID] = defaultKeys[i]
            end
        end
        -- NICHT speichern! Erst speichern, wenn der User einen Shortcut selbst zuweist
    end
end
function initializeTrackShortcuts()
    trackShortcuts = trackShortcuts or {}
    -- Sicherstellen, dass trackShortcuts initialisiert ist
    --trackShortcuts = trackShortcuts or {}
    if trackShortcutsSafed == false or trackShortcutsSafed == 'false' then
        -- Hole die GUIDs der "used" Tracks
        local usedTracks = readTrackGUID("used")
        local defaultKeys = {"1", "2", "3", "4", "5", "6", "7", "8", "9"}
    
        -- Weisen Sie den ersten 9 "used" Tracks die Shortcuts 1-9 zu
        for i = 1, math.min(#usedTracks, 9) do
            local trackGUID = usedTracks[i]
            trackShortcuts[trackGUID] = defaultKeys[i]
            consoleMSG('TrackGUID: '..trackGUID..' assigned to: '..defaultKeys[i])
        end
    
        -- Optional: Shortcuts speichern
        saveShortcuts()
        
    end
end
function saveGlobalShortcuts()
    local serializedShortcuts = tableToString(globalShortcuts)
    reaper.SetExtState("TCHelper", "GlobalShortcuts", serializedShortcuts, true)
    reaper.SetExtState("TCHelper", "globalShortcutsSafed", "true", true)

end
function loadGlobalShortcuts()
    -- Initialisiere globalShortcuts, falls sie nicht existiert
    if not globalShortcuts then
        globalShortcuts = { playPause = "Space", createCue = "." }
    end

    local serializedShortcuts = reaper.GetExtState("TCHelper", "GlobalShortcuts")
    if serializedShortcuts and serializedShortcuts ~= "" then
        globalShortcuts = stringToTable(serializedShortcuts)
    else
        -- Standard-Shortcuts definieren, wenn keine vorhanden sind
        globalShortcuts = { playPause = "Space", createCue = "." }
        saveGlobalShortcuts() -- Speichere die Standard-Shortcuts
    end
end
function updateInputCueName(targetTrackGUID)
    -- Verwende den übergebenen TrackGUID oder den aktuell ausgewählten Track
    local trackGUID = targetTrackGUID or readTrackGUID('selected')
    if not trackGUID then
        inputCueName = 'empty'
        cueNr = 1
        return
    end

    -- Hole den Track basierend auf der GUID
    local track = reaper.BR_GetMediaTrackByGUID(0, trackGUID)
    if not track then
        inputCueName = 'empty'
        cueNr = 1
        return
    end

    -- Zähle die Anzahl der Media-Items (Cues) im Ziel-Track
    local itemCount = reaper.CountTrackMediaItems(track)

    -- Berechne den Cue-Namen basierend auf der Option und der Anzahl der vorhandenen Cues
    if loadedtracks[trackGUID] and loadedtracks[trackGUID].execoption == 'Cue List' then
        cueNr = itemCount + 1
        inputCueName = 'Cue - ' .. cueNr
    elseif loadedtracks[trackGUID] and (loadedtracks[trackGUID].execoption == 'Flash Button' or loadedtracks[trackGUID].execoption == 'Temp Button') then
        cueNr = 1
        inputCueName = 'Cue - 1'
    else
        inputCueName = 'empty'
        cueNr = 1
    end
end
function togglePlayPause()
    if reaper.GetPlayState() == 0 then
        reaper.OnPlayButton() -- Startet die Wiedergabe
    else
        reaper.OnPauseButton() -- Pausiert die Wiedergabe
    end
end
---SELECTION TOOLS
function snapCursorToSelection()
    local selectedItem = getFirstTouchedMediaItem()
    --local selectedItem = reaper.GetSelectedMediaItem(0, 0)
    if snapCursorbox == true then
        if selectedItem ~= nil then
            local startTime = reaper.GetMediaItemInfo_Value(selectedItem, "D_POSITION")
            reaper.SetEditCurPos(startTime, true, false)
        end
    end
end
function selectToolsmaller()
    local trackGUID = {}
    local trackAmmount = 0
    local cursorposition = reaper.GetCursorPosition()
    if selectedTrackOption == 'selected Track' then
        trackGUID[1] = readTrackGUID('selected')
        trackAmmount = 1
    elseif selectedTrackOption == 'all Tracks' then
        trackGUID = readTrackGUID('used')        
        trackAmmount = #trackGUID
    end
    for i = 1, trackAmmount do
        local itemGUID = readItemGUID(trackGUID[i])
        for j = 1, #itemGUID, 1 do
            if loadedtracks[trackGUID[i]].cue[itemGUID[j]].itemStart <= cursorposition then
                local itemhandle = reaper.BR_GetMediaItemByGUID( 0, loadedtracks[trackGUID[i]].cue[itemGUID[j]].id)
                reaper.SetMediaItemSelected(itemhandle, true) -- Select the item
                reaper.UpdateArrange() -- Update the arrangement to show the selection
            end
        end
    end
end
function selectToolhigher()
    local trackGUID = {}
    local trackAmmount = 0
    local cursorposition = reaper.GetCursorPosition()
    if selectedTrackOption == 'selected Track' then
        trackGUID[1] = readTrackGUID('selected')
        trackAmmount = 1
    elseif selectedTrackOption == 'all Tracks' then
        trackGUID = readTrackGUID('used')        
        trackAmmount = #trackGUID
    end
    for i = 1, trackAmmount do
        local itemGUID = readItemGUID(trackGUID[i])
        for j = 1, #itemGUID, 1 do
            if loadedtracks[trackGUID[i]].cue[itemGUID[j]].itemStart >= cursorposition then
                local itemhandle = reaper.BR_GetMediaItemByGUID( 0, loadedtracks[trackGUID[i]].cue[itemGUID[j]].id)
                reaper.SetMediaItemSelected(itemhandle, true) -- Select the item
                reaper.UpdateArrange() -- Update the arrangement to show the selection
            end
        end
    end
end
function selectToolall()
    local trackGUID = {}
    local trackAmmount = 0
    local cursorposition = reaper.GetCursorPosition()
    if selectedTrackOption == 'selected Track' then
        trackGUID[1] = readTrackGUID('selected')
        trackAmmount = 1
    elseif selectedTrackOption == 'all Tracks' then
        trackGUID = readTrackGUID('used')        
        trackAmmount = #trackGUID
    end
    for i = 1, trackAmmount do
        local itemGUID = readItemGUID(trackGUID[i])
        for j = 1, #itemGUID, 1 do            
            local itemhandle = reaper.BR_GetMediaItemByGUID( 0, loadedtracks[trackGUID[i]].cue[itemGUID[j]].id)
            reaper.SetMediaItemSelected(itemhandle, true) -- Select the item
            reaper.UpdateArrange() -- Update the arrangement to show the selection
        end
    end
end
function noTrackError()
    local selected_trk = reaper.GetSelectedTrack(0, 0)
    if selected_trk == nil then
        reaper.ShowMessageBox("No Track selected", "Error", 0)
    end    
end
-----------------GUI WINDOW MAIN-------------------------------------------------------------
local toptextXoffset = 650
local toptextYoffset = 20
local headerText = script_title..' '..MAmode
local old_trackcount = -1
local function TCHelper_Window()
    local rv
    -- Menu Bar
    if reaper.ImGui_BeginMenuBar(ctx) then
        if reaper.ImGui_BeginMenu(ctx, 'Menu') then
            if ImGui.MenuItem(ctx, 'About') then
                aboutWindowOpen = true
            end
            if ImGui.MenuItem(ctx, 'Merge data') then
                mergeDataOption()
                local rv = reaper.ShowMessageBox('Merged data', script_title, 0)
            end
            if ImGui.MenuItem(ctx, 'Update') then
                manualCheck = true
                manualUpdate()

            end
            reaper.ImGui_EndMenu(ctx)
        end
        if reaper.ImGui_BeginMenu(ctx, 'Edit') then
            if ImGui.MenuItem(ctx, 'Cues') then
                local validTracks = checkTCHelperTracks()
                if validTracks == true then
                    local selTrack = readTrackGUID('selected')
                    seqName = loadedtracks[selTrack].name
                    NewCueNames = getCueNames()
                    NewFadeTimes = getFadeTimes()
                    cuesChecked = true
                else
                    NewCueNames = getCueNames()
                    NewFadeTimes = getFadeTimes()
                    cuesChecked = true
                end  
            end
            if ImGui.MenuItem(ctx, 'Sequence') then
                local validTracks = checkTCHelperTracks()
                if validTracks == true then
                    local selTrack = readTrackGUID('selected')
                    --seqName = loadedtracks[selTrack].name
                    getSeqNames()
                    seqChecked = true
                else
                    
                    seqChecked = true
                end  
            end
            reaper.ImGui_EndMenu(ctx)
        end
        if reaper.ImGui_BeginMenu(ctx, 'Settings') then
            if ImGui.MenuItem(ctx, 'Network') then
                networkChecked = true
            end
            if ImGui.MenuItem(ctx, 'Shortcuts') then
                shortcutsChecked = true -- Variable, um das Shortcut-Fenster zu öffnen
            end
            if reaper.ImGui_BeginMenu(ctx, 'Mode') then
                local modeCheck2 = false
                local modeCheck3 = true
                if MAmode == 'Mode 2' then
                    modeCheck2 = true
                else
                    modeCheck3 = false
                end
                if MAmode == 'Mode 3' then
                    modeCheck3 = true
                else
                    modeCheck3 = false
                end
                if ImGui.MenuItem(ctx, 'Mode 2', nil, modeCheck2) then 
                    if mode2BETA == false then
                        MAmode = 'Mode 3'
                        local rv = reaper.ShowMessageBox('MODE 2 IS NOT READY YET', script_title, 0)
                        --consoleMSG('Mode: '..MAmode)
                    elseif mode2BETA == true then
                        MAmode = 'Mode 2'
                        
                        --consoleMSG('Mode: '..MAmode)
                    end
                end
                if ImGui.MenuItem(ctx, 'Mode 3', nil, modeCheck3) then 
                    MAmode = 'Mode 3'
                    --consoleMSG('Mode: '..MAmode)
                end
                
                reaper.ImGui_EndMenu(ctx)
            end
            
            reaper.ImGui_EndMenu(ctx)
        end
        if reaper.ImGui_BeginMenu(ctx, 'Help') then
            if ImGui.MenuItem(ctx, 'Manual') then
                openPDFManual()
            end
            reaper.ImGui_EndMenu(ctx)
        end
        reaper.ImGui_EndMenuBar(ctx)
    end
    
    -------TABS----------------------------------------------------------------------
    if ImGui.BeginTabBar(ctx, 'MyTabBar', ImGui.TabBarFlags_None()) then
        if ImGui.BeginTabItem(ctx, 'Show Setup') then
            if cursor == 0 then
                CueListSetupWindow()
                local usedTracks = readTrackGUID('used')
                if old_trackcount ~= #usedTracks then
                    cueListName = 'Cue List '..#usedTracks + 1
                    seqID = seqBase + #usedTracks
                    
                    old_trackcount = #usedTracks
                end
                elseif cursor == 1 then
                    local itemcount = getItemCount()
                    local selectedTrack = readTrackGUID('selected')
                    if old_itemcount ~= itemcount or old_track ~= selectedTrack then
                    if not inputCueNameFieldActive then
                        if selectedOption == 'Cue List' then
                            inputCueName = 'Cue - ' .. itemcount + 1
                            cueNr = itemcount + 1
                        else
                            inputCueName = 'Cue - 1'
                            cueNr = 1
                        end
                    end
                    old_track = selectedTrack
                    old_itemcount = itemcount
                end
                if selectedOption == 'Cue List' then
                    CueItemWindow()
                elseif selectedOption == 'Flash Button' or 'Temp Button' then
                    TempItemWindow()
                end
            end
            
        ImGui.EndTabItem(ctx)
        end
        if ImGui.BeginTabItem(ctx, 'Tools') then
            ToolsWindow()
            ImGui.EndTabItem(ctx)
        end
        -- if ImGui.BeginTabItem(ctx, 'Connection',0,0) then
        --     if MAmode == 'Mode 2' then
        --         connectionWindowMode2()
        --     elseif MAmode == 'Mode 3' then
        --         connectionWindowMode3()
                
        --     end
        --     ImGui.EndTabItem(ctx)
        -- end
        
        -- if mode2BETA == true then 
        --     if ImGui.BeginTabItem(ctx, 'Mode',0,0) then
        --     modeWindow()
        --     ImGui.EndTabItem(ctx)
        --     end
        
        -- end
        ImGui.EndTabBar(ctx)
    end
end
local rv
local function ShowFocusHint()
    -- Prüfe, ob das ImGui-Fenster im Fokus ist
    local isFocused = reaper.ImGui_IsWindowFocused(ctx)
    local hintText, color

    if isFocused then
        hintText = "Shortcuts are ACTIVATED"
        color = 0x1DB287FF -- grün
    else
        hintText = "Click in TCHelper Window to activate Shortcuts!!!!!! Shortcuts are DISABLED"
        color = 0xFF6E59FF -- rot
    end

    -- Positioniere den Hinweis immer am unteren Rand des Fensters
    local windowHeight = reaper.ImGui_GetWindowHeight(ctx)
    local hintHeight = reaper.ImGui_GetTextLineHeight(ctx) + 30 -- Höhe des Textes + 10px Abstand
    local yPos = windowHeight - hintHeight - 0 -- 5px Abstand zum unteren Rand

    reaper.ImGui_SetCursorPos(ctx, 0, yPos)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), 0x22222288)
    if reaper.ImGui_BeginChild(ctx, "FocusHint", 0, hintHeight, true, reaper.ImGui_WindowFlags_NoInputs()) then
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), color)
        local windowWidth = reaper.ImGui_GetWindowWidth(ctx)
        local textWidth = reaper.ImGui_CalcTextSize(ctx, hintText)
        reaper.ImGui_SetCursorPosX(ctx, (windowWidth - textWidth) / 2)
        reaper.ImGui_Text(ctx, hintText)
        reaper.ImGui_PopStyleColor(ctx)
        reaper.ImGui_EndChild(ctx)
    end
    reaper.ImGui_PopStyleColor(ctx)
end
function ShowAboutWindow()
    local rv, script_path = isInstalledViaReapack()
    local logoImage_path = script_path..dataFolder..logoFolder..logoBigName
    local logoImage_texture = reaper.ImGui_CreateImage(logoImage_path)
    if aboutWindowOpen then
        local windowWidth, windowHeight = 300, 400
        reaper.ImGui_SetNextWindowSize(ctx, windowWidth, windowHeight, reaper.ImGui_Cond_Always())
        local windowFlags = reaper.ImGui_WindowFlags_NoResize()
        local visible, open = reaper.ImGui_Begin(ctx, 'About TC Helper', true, windowFlags)
        if visible then
            if logoImage_texture then
                local logoWidth, logoHeight = 200, 150
                local logoX = (windowWidth - logoWidth) / 2
                reaper.ImGui_SetCursorPos(ctx, logoX, 20)
                reaper.ImGui_Image(ctx, logoImage_texture, logoWidth, logoHeight)
            else
                reaper.ShowMessageBox('Bild konnte nicht geladen werden.', 'Fehler', 0)
            end

            local text = 'version: '..version..'\nmade by: Lichtwerk\nTim Eschert\nsupport: support@lichtwerk.info'
            local lines = {}
            for line in text:gmatch("[^\n]+") do
                table.insert(lines, line)
            end

            local totalTextHeight = #lines * reaper.ImGui_GetTextLineHeight(ctx)
            local startY = (windowHeight - totalTextHeight) / 2
            for i, line in ipairs(lines) do
                local textWidth = reaper.ImGui_CalcTextSize(ctx, line)
                local textX = (windowWidth - textWidth) / 2
                local textY = startY + (i - 1) * reaper.ImGui_GetTextLineHeight(ctx)
                reaper.ImGui_SetCursorPos(ctx, textX, textY)
                if line:find("Version:") or line:find("made by:") or line:find("Support:") then
                    --reaper.ImGui_PushFont(ctx, sans_serif_bold)
                    reaper.ImGui_Text(ctx, line)
                    --reaper.ImGui_PopFont(ctx)
                else
                    reaper.ImGui_Text(ctx, line)
                end
            end

            -- Platz für den Button unten im Fenster
            local buttonWidth, buttonHeight = 60, 30
            local buttonX = (windowWidth - buttonWidth) / 2
            local buttonY = windowHeight - buttonHeight - 20
            reaper.ImGui_SetCursorPos(ctx, buttonX, buttonY)
            if reaper.ImGui_Button(ctx, 'OK', buttonWidth, buttonHeight) then
                aboutWindowOpen = false
            end
            reaper.ImGui_End(ctx)
        end
        if not open then
            aboutWindowOpen = false
        end
    end
end
function ShowOldVersionUpdateWindow(currentVersion)
    if openOldVersionWindow then
        local windowWidth, windowHeight = 400, 300
        reaper.ImGui_SetNextWindowSize(ctx, windowWidth, windowHeight, reaper.ImGui_Cond_Always())
        local windowFlags = reaper.ImGui_WindowFlags_NoResize()
        local visible, open = reaper.ImGui_Begin(ctx, "Update TCHelper", true, windowFlags)
        if visible then
            -- Logo anzeigen
            local logoImage_path = script_path..dataFolder..logoFolder..logoBigName
            local logoImage_texture = reaper.ImGui_CreateImage(logoImage_path)
            if logoImage_texture then
                local logoWidth, logoHeight = 190, 170
                local logoX = (windowWidth - logoWidth) / 2
                reaper.ImGui_SetCursorPos(ctx, logoX, 20)
                reaper.ImGui_Image(ctx, logoImage_texture, logoWidth, logoHeight)
            else
                reaper.ShowMessageBox('Bild konnte nicht geladen werden.', 'Fehler', 0)
            end

            -- Text anzeigen
            local text = "You are using the latest version (" .. currentVersion .. ") of TCHelper.\nNo update is necessary."
            local lines = {}
            for line in text:gmatch("[^\n]+") do
                table.insert(lines, line)
            end

            local totalTextHeight = #lines * reaper.ImGui_GetTextLineHeight(ctx)
            local startY = (windowHeight - totalTextHeight) / 2 + 50
            for i, line in ipairs(lines) do
                local textWidth = reaper.ImGui_CalcTextSize(ctx, line)
                local textX = (windowWidth - textWidth) / 2
                local textY = startY + (i - 1) * reaper.ImGui_GetTextLineHeight(ctx)
                reaper.ImGui_SetCursorPos(ctx, textX, textY)
                reaper.ImGui_Text(ctx, line)
            end

            -- OK Button
            local buttonWidth, buttonHeight = 100, 30
            local buttonY = windowHeight - buttonHeight - 20
            reaper.ImGui_SetCursorPos(ctx, (windowWidth - buttonWidth) / 2, buttonY)
            if reaper.ImGui_Button(ctx, "OK", buttonWidth, buttonHeight) then
                openOldVersionWindow = false
            end

            reaper.ImGui_End(ctx)
        end
        if not open then
            openOldVersionWindow = false
        end
    end
end
function ShowNewVersionUpdateWindow(latestVersion)
    if openNewVersionWindow then
        local windowWidth, windowHeight = 400, 300
        reaper.ImGui_SetNextWindowSize(ctx, windowWidth, windowHeight, reaper.ImGui_Cond_Always())
        local windowFlags = reaper.ImGui_WindowFlags_NoResize()
        local visible, open = reaper.ImGui_Begin(ctx, "Update TCHelper", true, windowFlags)
        if visible then
            -- Logo anzeigen
            local logoImage_path = script_path..dataFolder..logoFolder..logoBigName
            local logoImage_texture = reaper.ImGui_CreateImage(logoImage_path)
            if logoImage_texture then
                local logoWidth, logoHeight = 190, 170
                local logoX = (windowWidth - logoWidth) / 2
                reaper.ImGui_SetCursorPos(ctx, logoX, 20)
                reaper.ImGui_Image(ctx, logoImage_texture, logoWidth, logoHeight)
            else
                reaper.ShowMessageBox('Bild konnte nicht geladen werden.', 'Fehler', 0)
            end

            -- Text anzeigen
            local text = "A new version (" .. (latestVersion or "unknown") .. ") of TCHelper is available.\nPlease update to the latest version."
            local lines = {}
            for line in text:gmatch("[^\n]+") do
                table.insert(lines, line)
            end

            local totalTextHeight = #lines * reaper.ImGui_GetTextLineHeight(ctx)
            local startY = (windowHeight - totalTextHeight) / 2 + 50
            for i, line in ipairs(lines) do
                local textWidth = reaper.ImGui_CalcTextSize(ctx, line)
                local textX = (windowWidth - textWidth) / 2
                local textY = startY + (i - 1) * reaper.ImGui_GetTextLineHeight(ctx)
                reaper.ImGui_SetCursorPos(ctx, textX, textY)
                reaper.ImGui_Text(ctx, line)
            end

            local buttonWidth, buttonHeight = 100, 30
            local buttonY = windowHeight - buttonHeight - 20

            reaper.ImGui_SetCursorPos(ctx, (windowWidth / 2) - buttonWidth - 10, buttonY)
            if reaper.ImGui_Button(ctx, "Update", buttonWidth, buttonHeight) then
                openNewVersionWindow = false
                refreshAndBrowseTCHelper()
            end

            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_SetCursorPos(ctx, (windowWidth / 2) + 10, buttonY)
            if reaper.ImGui_Button(ctx, "Not Now", buttonWidth, buttonHeight) then
                openNewVersionWindow = false
            end

            reaper.ImGui_End(ctx)
        end
        if not open then
            openNewVersionWindow = false
        end
    end
end
function connectionWindowMode2()
    ---------------INPUTS---------------------------------------------------------------
    ---------------Input IP---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 250)
    
    rv, hostIP = reaper.ImGui_InputText(ctx, 'Host IP', hostIP)
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)

    ---------------Input Port---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 250)
    rv, userName = reaper.ImGui_InputText(ctx, 'Username', userName)
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)
    ---------------Input Test Message ---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 250)
    rv, testcmd2 = reaper.ImGui_InputText(ctx, 'Testcommand', testcmd2)
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)
    ---------------BUTTON---------------------------------------------------------------
    ---------------Test Button---------------------------------------------------------------
    
    if reaper.ImGui_Button(ctx, '          Save\nNetworkconfig', 121, 50) then
        reaper.SetExtState('network','ip',hostIP,true)
        reaper.SetExtState('network','userName',userName,true)
        reaper.SetExtState('network','prefix',prefix,true)
        reaper.SetExtState('basic','dataPoolName',datapoolName,true)
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, '          Load\nNetworkConfig', 121, 50) then
        hostIP = reaper.GetExtState('network','ip')
        userName = reaper.GetExtState('network','userName')
      
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, ' Reset\nConfig', 121, 50) then
        hostIP = dummyIPstring
        userName = '--Enter User Name--'
        reaper.SetExtState('network','ip',hostIP,true)
        reaper.SetExtState('network','userName',userName,true)
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, '      Test\nConnection', 121, 50) then
        sendTelnet(testcmd2)
    end
    if reaper.ImGui_Button(ctx, '   Merge\nto console', 121, 70) then
        --reaper.ShowMessageBox('TC Helper\nMERGE NOT IMPLEMENTED YET', 'Error', 0)
        renumberItems()
        getTrackContent()
        if loadProjectMarker == false then
            sendedData = copy3(loadedtracks)
            loadProjectMarker = true
        end
        checkItemStatus()
        local OscCommands = setOSCcommand()
        sendToConsoleMA2(OscCommands)
    end
    
    reaper.ImGui_SameLine(ctx)
    ImGui.PushID(ctx, 1)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button(),        Color.HSV(1 / 0, 1, 0.3, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), Color.HSV(1 / 0, 1, 0.8, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(),  Color.HSV(1 / 0, 1, 1, 1.0))
    if reaper.ImGui_Button(ctx, ' OVERWRITE\nTO CONSOLE', 121, 70) then
        local cueText = setupSeqXml()
        XMLwriting('Sequence',cueText)
        pushXML('Sequence')
        importInShowfile('Sequence', '6')

        -- renumberItems()
        -- getTrackContent()
        -- InitiateSendedData()
        -- local OscCommands = setOSCcommand()
        -- sendToConsoleMA2(OscCommands)
    end
    if ImGui.IsItemHovered(ctx) then
        ImGui.SetTooltip(ctx, 'ATTENTION!! \nBUTTON OVERWRITES EXISTING CONTENT ON CONSOLE!!!!')
    end
    ImGui.PopStyleColor(ctx, 3)
    ImGui.PopID(ctx)
    reaper.ImGui_SameLine(ctx)
    if ma2Loopback == 'false' then
        ImGui.PushID(ctx, 1)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button(),        Color.HSV(1 / 0, 1, 0.3, 1.0))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), Color.HSV(1 / 0, 1, 0.5, 1.0))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(),  Color.HSV(1 / 0, 1, 0,5, 1.0))
        if reaper.ImGui_Button(ctx, '    Connect to \nGrandMA2 OnPC', 250, 70) then

            ma2Loopback = 'true'
            reaper.SetExtState('console','2onPC',ma2Loopback, true)
        end
        ImGui.PopStyleColor(ctx, 3)
        ImGui.PopID(ctx)
    else
        ImGui.PushID(ctx, 1)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button(),        Color.HSV(1 / 3, 1, 0.3, 1.0))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), Color.HSV(1 / 3, 1, 0.5, 1.0))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(),  Color.HSV(1 / 3, 1, 0.5, 1.0))
        if reaper.ImGui_Button(ctx, '    Connected to \nGrandMA2 OnPC', 250, 70) then
            
            ma2Loopback = 'false'
            reaper.SetExtState('console','2onPC',ma2Loopback, true)
        end
        ImGui.PopStyleColor(ctx, 3)
        ImGui.PopID(ctx)
    end
    
    
    --reaper.ImGui_SetCursorPos(ctx, 500, 35)
    --rv,liveupdatebox = ImGui.Checkbox(ctx, 'Live Update to Console', liveupdatebox)
    
   
    
    
end
function connectionWindowMode3()
    ---------------INPUTS---------------------------------------------------------------
    ---------------Input IP---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 250)
    
    rv, hostIP = reaper.ImGui_InputText(ctx, 'Host IP', hostIP)
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)
    
    
    ---------------Input Port---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 250)
    rv, consolePort = reaper.ImGui_InputText(ctx, 'Port', consolePort)
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)
    ---------------Input Praefix---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 250)
    rv, prefix = reaper.ImGui_InputText(ctx, 'Prefix', prefix)
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)
    ---------------Input Profile---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 250)
    rv, datapoolName = reaper.ImGui_InputText(ctx, 'DataPool', datapoolName)
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)
    ---------------Input Test Message ---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 250)
    rv, testcmd3 = reaper.ImGui_InputText(ctx, 'Testcommand', testcmd3)
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)
    ---------------BUTTON---------------------------------------------------------------
    ---------------Test Button---------------------------------------------------------------
    rv,liveupdatebox = ImGui.Checkbox(ctx, 'Live update to console', liveupdatebox)
    if reaper.ImGui_Button(ctx, '       Save\nNetworkconfig', 121, 50) then
        reaper.SetExtState('network','ip',hostIP,true)
        reaper.SetExtState('network','port',consolePort,true)
        reaper.SetExtState('network','prefix',prefix,true)
        reaper.SetExtState('basic','dataPoolName',datapoolName,true)
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, '       Load\nNetworkconfig', 121, 50) then
        hostIP = reaper.GetExtState('network','ip')
        consolePort = reaper.GetExtState('network','port')
        prefix = reaper.GetExtState('network','prefix')
        datapoolName = reaper.GetExtState('basic','dataPoolName')
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, ' Reset\nConfig', 121, 50) then
        hostIP = dummyIPstring
        consolePort = '8000'
        prefix = 'reaper'
        datapoolName = 'default'
        reaper.SetExtState('network','ip',hostIP,true)
        reaper.SetExtState('network','port',consolePort,true)
        reaper.SetExtState('network','prefix',prefix,true)
        reaper.SetExtState('basic','dataPoolName',datapoolName,true)
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, '     Test\nConnection', 121, 50) then
        sendOSC(hostIP, consolePort, testcmd3)
    end
    
    ImGui.PushID(ctx, 1)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button(),        Color.HSV(1 / 0, 1, 0.3, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), Color.HSV(1 / 0, 1, 0.8, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(),  Color.HSV(1 / 0, 1, 1, 1.0))
    if reaper.ImGui_Button(ctx, 'OVERWRITE TO CONSOLE', 250, 70) then
        renumberItems()
        getTrackContent()
        InitiateSendedData()
        local OscCommands = setOSCcommand()
        sendToConsole(hostIP, consolePort, OscCommands)
        
    end
    if ImGui.IsItemHovered(ctx) then
        ImGui.SetTooltip(ctx, 'ATTENTION!! \nBUTTON OVERWRITES EXISTING CONTENT ON CONSOLE!!!!')
    end
    ImGui.PopStyleColor(ctx, 3)
    ImGui.PopID(ctx)
    reaper.ImGui_SameLine(ctx)
    if hostIP == '127.0.0.1' and loopback == 'true' then
        -- Button ist grün, wenn die IP 127.0.0.1 ist und Loopback aktiviert ist
        ImGui.PushID(ctx, 1)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button(), Color.HSV(1 / 3, 1, 0.3, 1.0))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), Color.HSV(1 / 3, 1, 0.5, 1.0))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(), Color.HSV(1 / 3, 1, 0.5, 1.0))
        if reaper.ImGui_Button(ctx, '   Connected to \nGrandMA3 OnPC', 250, 70) then
            -- Deaktiviere Loopback und setze die IP zurück
            local ipOld = reaper.GetExtState('network', 'ip')
            hostIP = ipOld
            loopback = 'false'
            reaper.SetExtState('console', '3onPC', loopback, true)
        end
        ImGui.PopStyleColor(ctx, 3)
        ImGui.PopID(ctx)
    else
        -- Button ist rot, wenn die IP nicht 127.0.0.1 ist oder Loopback deaktiviert ist
        ImGui.PushID(ctx, 1)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button(), Color.HSV(1 / 0, 1, 0.3, 1.0))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), Color.HSV(1 / 0, 1, 0.5, 1.0))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(), Color.HSV(1 / 0, 1, 0.5, 1.0))
        if reaper.ImGui_Button(ctx, '    Connect to \nGrandMA3 OnPC', 250, 70) then
            -- Aktiviere Loopback und setze die IP auf 127.0.0.1
            hostIP = '127.0.0.1'
            loopback = 'true'
            reaper.SetExtState('console', '3onPC', loopback, true)
        end
        ImGui.PopStyleColor(ctx, 3)
        ImGui.PopID(ctx)
    end
    
    
    reaper.ImGui_SetCursorPos(ctx, 500, toptextYoffset + 50)
    
    ---------------Single Update Button---------------------------------------------------------------
    --[[ reaper.ImGui_SetCursorPos(ctx, 300, 190)
    if reaper.ImGui_Button(ctx, 'Load Project', 100, 50) then
        renumberItems()
        reaper.ImGui_SameLine(ctx)
    end ]]
end
function openShortcutWindow()
    -- Sicherstellen, dass trackShortcuts und globalShortcuts initialisiert sind
    trackShortcuts = trackShortcuts or {}
    globalShortcuts = globalShortcuts or { playPause = "P", createCue = "C" }

    reaper.ImGui_SetNextWindowSize(ctx, 400, 500, reaper.ImGui_Cond_FirstUseEver())
    local visible, open = reaper.ImGui_Begin(ctx, "Shortcut Settings", true)
    if visible then
        reaper.ImGui_Text(ctx, "Assign personal cue shortcuts")
        reaper.ImGui_Separator(ctx)

        -- Unterstützte Tasten
        local supportedKeys = {
            "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
            "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
            "-", "=", "[", "]", ";", "'", ",", ".", "/", "\\", "`", " "
        }

        -- Tracks durchlaufen und Shortcuts anzeigen
        local usedTracks = readTrackGUID("used")
        for i, trackGUID in ipairs(usedTracks) do
            local trackName = loadedtracks[trackGUID] and loadedtracks[trackGUID].name or "Track " .. i
            reaper.ImGui_Text(ctx, trackName .. ":")
            reaper.ImGui_SameLine(ctx)

            -- Aktuellen Shortcut anzeigen oder "Assign Key" anzeigen
            local currentShortcut = trackShortcuts[trackGUID] or "Assign Key"
            if assigningShortcut == trackGUID then
                currentShortcut = "Press key to assign"
            end

            if reaper.ImGui_Button(ctx, currentShortcut, 150, 20) then
                if assigningShortcut == trackGUID then
                    assigningShortcut = nil -- Deaktivieren
                else
                    assigningShortcut = trackGUID -- Shortcut-Zuweisung aktivieren
                end
            end

            -- Wenn Shortcut-Zuweisung aktiv ist, warte auf Tastendruck
            if assigningShortcut == trackGUID then
                for _, key in ipairs(supportedKeys) do
                    local imguiKeyFunc = reaper["ImGui_Key_" .. key]
                    if imguiKeyFunc and reaper.ImGui_IsKeyPressed(ctx, imguiKeyFunc()) then
                        -- Überprüfe, ob der Shortcut bereits verwendet wird
                        local isDuplicate = false
                        local duplicateType = nil

                        -- Überprüfe Track-Shortcuts
                        for otherTrackGUID, existingKey in pairs(trackShortcuts) do
                            if existingKey == key and otherTrackGUID ~= trackGUID then
                                isDuplicate = true
                                duplicateType = "Track Shortcut"
                                break
                            end
                        end

                        -- Überprüfe globale Shortcuts
                        for globalKey, existingKey in pairs(globalShortcuts) do
                            if existingKey == key then
                                isDuplicate = true
                                duplicateType = "Global Shortcut (" .. globalKey .. ")"
                                break
                            end
                        end

                        if not isDuplicate then
                            trackShortcuts[trackGUID] = key -- Shortcut speichern
                            assigningShortcut = nil -- Zuweisung beenden
                            saveShortcuts() -- Shortcuts speichern
                        else
                            -- Zeige eine Fehlermeldung an
                            reaper.ShowMessageBox(
                                "Shortcut '" .. key .. "' is already assigned to '" .. duplicateType .. "'. Please choose another key.",
                                "Duplicate Shortcut",
                                0
                            )
                        end
                        break
                    end
                end
            end
        end

        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Text(ctx, "Global Shortcuts:")
        
        -- Play/Pause Shortcut
        reaper.ImGui_Text(ctx, "Play/Pause:")
        reaper.ImGui_SameLine(ctx)
        local playPauseShortcut = globalShortcuts.playPause or "Assign Key"
        if assigningShortcut == "playPause" then
            playPauseShortcut = "Press key to assign"
        end
        if reaper.ImGui_Button(ctx, playPauseShortcut, 150, 20) then
            if assigningShortcut == "playPause" then
                assigningShortcut = nil
            else
                assigningShortcut = "playPause"
            end
        end
        if assigningShortcut == "playPause" then
            for _, key in ipairs(supportedKeys) do
                local imguiKeyFunc = reaper["ImGui_Key_" .. key]
                if imguiKeyFunc and reaper.ImGui_IsKeyPressed(ctx, imguiKeyFunc()) then
                    -- Überprüfe, ob der Shortcut bereits verwendet wird
                    local isDuplicate = false
                    local duplicateType = nil

                    -- Überprüfe Track-Shortcuts
                    for _, existingKey in pairs(trackShortcuts) do
                        if existingKey == key then
                            isDuplicate = true
                            duplicateType = "Track Shortcut"
                            break
                        end
                    end

                    -- Überprüfe andere globale Shortcuts
                    for globalKey, existingKey in pairs(globalShortcuts) do
                        if existingKey == key and globalKey ~= "playPause" then
                            isDuplicate = true
                            duplicateType = "Global Shortcut (" .. globalKey .. ")"
                            break
                        end
                    end

                    if not isDuplicate then
                        globalShortcuts.playPause = key
                        assigningShortcut = nil
                        saveGlobalShortcuts()
                    else
                        -- Zeige eine Fehlermeldung an
                        reaper.ShowMessageBox(
                            "Shortcut '" .. key .. "' is already assigned to '" .. duplicateType .. "'. Please choose another key.",
                            "Duplicate Shortcut",
                            0
                        )
                    end
                    break
                end
            end
        end

        -- Create Cue Shortcut
        reaper.ImGui_Text(ctx, "Create Cue in Selected Track:")
        reaper.ImGui_SameLine(ctx)
        local createCueShortcut = globalShortcuts.createCue or "Assign Key"
        if assigningShortcut == "createCue" then
            createCueShortcut = "Press key to assign"
        end
        if reaper.ImGui_Button(ctx, createCueShortcut, 150, 20) then
            if assigningShortcut == "createCue" then
                assigningShortcut = nil
            else
                assigningShortcut = "createCue"
            end
        end
        if assigningShortcut == "createCue" then
            for _, key in ipairs(supportedKeys) do
                local imguiKeyFunc = reaper["ImGui_Key_" .. key]
                if imguiKeyFunc and reaper.ImGui_IsKeyPressed(ctx, imguiKeyFunc()) then
                    -- Überprüfe, ob der Shortcut bereits verwendet wird
                    local isDuplicate = false
                    local duplicateType = nil

                    -- Überprüfe Track-Shortcuts
                    for _, existingKey in pairs(trackShortcuts) do
                        if existingKey == key then
                            isDuplicate = true
                            duplicateType = "Track Shortcut"
                            break
                        end
                    end

                    -- Überprüfe andere globale Shortcuts
                    for globalKey, existingKey in pairs(globalShortcuts) do
                        if existingKey == key and globalKey ~= "createCue" then
                            isDuplicate = true
                            duplicateType = "Global Shortcut (" .. globalKey .. ")"
                            break
                        end
                    end

                    if not isDuplicate then
                        globalShortcuts.createCue = key
                        assigningShortcut = nil
                        saveGlobalShortcuts()
                    else
                        -- Zeige eine Fehlermeldung an
                        reaper.ShowMessageBox(
                            "Shortcut '" .. key .. "' is already assigned to '" .. duplicateType .. "'. Please choose another key.",
                            "Duplicate Shortcut",
                            0
                        )
                    end
                    break
                end
            end
        end

        reaper.ImGui_End(ctx)
    end
    return open
end
function ToolsWindow()    
    local windowWidth, windowHeight = reaper.ImGui_GetWindowSize(ctx)
    local systemFramerate = reaper.TimeMap_curFrameRate(0)
    local framerateText = 'Project Framerate: '..systemFramerate..' Frames'
    local inputwidth = 40
    local timetextX = 20
    local timetextY = 70
    local buttonHeight = 50
    local buttonWidth = 80
    local xButtonsStart = 550
    local offset = 55
    local Yoffset = 30
    local hhSeconds = 0
    local mmSeconds = 0
    local ssfloat = 0
    local ffSeconds = 0
    local rv, script_path = isInstalledViaReapack()
    local logoImage_path = script_path..dataFolder..logoFolder..logoBigName
    local logoImage_texture = reaper.ImGui_CreateImage(logoImage_path)
    -- Fenstergröße abrufen
    
    -- X-Position des Logos berechnen
    local logoX = (windowWidth - BigLogoWidth) / 2

    -- Bild anzeigen und skalieren
    if logoImage_texture then
        reaper.ImGui_SetCursorPos(ctx, logoX, BigLogoY)
        reaper.ImGui_Image(ctx, logoImage_texture, BigLogoWidth, BigLogoHeight) 
    else
        reaper.ShowMessageBox('Bild konnte nicht geladen werden.', 'Fehler', 0)
    end
   --ImGui.SeparatorText(ctx, 'Selection Tools')
   reaper.ImGui_SetCursorPos(ctx, timetextX, timetextY)
    ImGui.Text(ctx, framerateText)
    reaper.ImGui_SetCursorPos(ctx, timetextX, timetextY + Yoffset)
    ImGui.Text(ctx, 'hh')
    reaper.ImGui_SetCursorPos(ctx, timetextX + offset, timetextY + Yoffset)
    ImGui.Text(ctx, 'mm')
    reaper.ImGui_SetCursorPos(ctx, timetextX + 115, timetextY + Yoffset)
    ImGui.Text(ctx, 'ss')
    reaper.ImGui_SetCursorPos(ctx, timetextX + 180, timetextY + Yoffset)
    ImGui.Text(ctx, 'ff')
    --reaper.ImGui_SameLine(ctx)
    
    reaper.ImGui_SetNextItemWidth(ctx, inputwidth)
    rv1, inputHH = reaper.ImGui_InputTextWithHint(ctx, ' :', 'hh', inputHH)
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, inputwidth)
    rv2, inputMM = reaper.ImGui_InputTextWithHint(ctx, ':', 'mm', inputMM)
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, inputwidth)
    rv3, inputSS = reaper.ImGui_InputTextWithHint(ctx, ': ', 'ss', inputSS)  
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, inputwidth)
    rv4, inputFF = reaper.ImGui_InputTextWithHint(ctx, 'New items time', 'ff', inputFF)
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)

    reaper.ImGui_SetCursorPos(ctx, timetextX ,timetextY + 80)
    if reaper.ImGui_Button(ctx, 'Set item to time', 200, 50) then
        hhSeconds = tonumber(inputHH) * 3600
        mmSeconds = tonumber(inputMM) * 60
        ssfloat = tonumber(inputSS)
        ffSeconds = tonumber(inputFF) / (systemFramerate)
        local newTime = hhSeconds + mmSeconds + ssfloat + ffSeconds
        moveItem (newTime)
        
    end
    rv,snapCursorbox = ImGui.Checkbox(ctx, 'Snap cursor to item', snapCursorbox)
    

    -- Track options as checkboxes
    local yBoxStart = 410
    reaper.ImGui_SetCursorPos(ctx, yBoxStart, timetextY + Yoffset)
    ImGui.Text(ctx, 'Track options:')
    local yAdd = 2
    for i, option in ipairs(selOptions) do
        reaper.ImGui_SetCursorPos(ctx, yBoxStart, timetextY + yAdd*Yoffset)
        local isSelected = (selectedTrackOption == option)
        if ImGui.Checkbox(ctx, option, isSelected) then
            selectedTrackOption = option
        end
        yAdd = yAdd + 1
    end
    reaper.ImGui_SetCursorPos(ctx, xButtonsStart + 15, timetextY + Yoffset)
    ImGui.Text(ctx, 'Select on before or after cursor')
    reaper.ImGui_SetCursorPos(ctx, xButtonsStart, timetextY + 1.6*Yoffset)
    if reaper.ImGui_Button(ctx, 'Before', buttonWidth, buttonHeight) then
        selectToolsmaller()
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'ALL', buttonWidth, buttonHeight) then
        selectToolall()
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'After', buttonWidth, buttonHeight) then
        selectToolhigher()
    end
    ---------------Copy Item Button---------------------------------------------------------------
    reaper.ImGui_SetCursorPos(ctx, xButtonsStart, toptextYoffset + 155)
    if reaper.ImGui_Button(ctx, 'Copy', buttonWidth, buttonHeight) then
        local check = checkTCHelperTracks()

        if check == false then
            --consoleMSG('Check False')
        else
            --consoleMSG('Check true')

            copySelectedItems()


        end
    end 
    reaper.ImGui_SameLine(ctx)
    ---------------Paste Item Button---------------------------------------------------------------
    if reaper.ImGui_Button(ctx, 'Paste', buttonWidth, buttonHeight) then
        local check = checkTCHelperTracks()

        if check == false then
            --consoleMSG('Check False')
        else
            --consoleMSG('Check true')

            pasteItems()

        end
        reaper.ImGui_SameLine(ctx)
    end 
    reaper.ImGui_SameLine(ctx)
    ImGui.PushID(ctx, 1)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button(),        Color.HSV(1 / 0, 1, 0.3, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), Color.HSV(1 / 0, 1, 0.8, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(),  Color.HSV(1 / 0, 1, 1, 1.0))
    if reaper.ImGui_Button(ctx, '  Delete\nselection', buttonWidth, buttonHeight) then
        deleteSelection()
        reaper.ImGui_SameLine(ctx)
    end 
    ImGui.PopStyleColor(ctx, 3)
    ImGui.PopID(ctx)
    ShowFocusHint()
end
function CueListSetupWindow()
    local buttonX = 9
    local buttonY = 160
    local buttonWidth = 120
    local buttonHeight = 80
    local buttonSpace = 10
    local rv, script_path = isInstalledViaReapack()
    local logoImage_path = script_path..dataFolder..logoFolder..logoBigName
    local logoImage_texture = reaper.ImGui_CreateImage(logoImage_path)
    ImGui.SeparatorText(ctx, 'SETUP SEQUENCE')
    
    -- Fenstergröße abrufen
    local windowWidth, windowHeight = reaper.ImGui_GetWindowSize(ctx)
    
    -- X-Position des Logos berechnen
    local logoX = (windowWidth - BigLogoWidth) / 2

    -- Bild anzeigen und skalieren
    if logoImage_texture then
        reaper.ImGui_SetCursorPos(ctx, logoX, BigLogoY)
        reaper.ImGui_Image(ctx, logoImage_texture, BigLogoWidth, BigLogoHeight) 
    else
        reaper.ShowMessageBox('Bild konnte nicht geladen werden.', 'Fehler', 0)
    end
    ---------------INPUTS---------------------------------------------------------------
    ---------------Input Cuelist Name---------------------------------------------------------------
    reaper.ImGui_SetCursorPos(ctx, 9, 80)
    reaper.ImGui_SetNextItemWidth(ctx, 300)
    rv, cueListName = reaper.ImGui_InputText(ctx, 'Sequence Name', cueListName)
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)
    cueListName = replaceSpecialCharacters(cueListName)
    ---------------Input Sequence ID---------------------------------------------------------------
    reaper.ImGui_SetCursorPos(ctx, 500, 80)
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    seqID = tonumber(reaper.GetExtState('trackconfig', 'seqId')) or 1
    local rv, newSeqID = reaper.ImGui_InputText(ctx, 'Sequence ID', tostring(seqID))
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)

    -- Wenn der Benutzer eine neue Zahl einträgt, aktualisiere die Basis
    if rv and tonumber(newSeqID) then
        seqID = tonumber(newSeqID)
        reaper.SetExtState('trackconfig', 'seqId', tostring(seqID), true)
    end
    reaper.ImGui_SetCursorPos(ctx, 500, 110)
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    rv, tcID = reaper.ImGui_InputText(ctx, 'Timecode ID', tcID)
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)
    if MAmode == 'Mode 2' then
        ---------------BUTTON---------------------------------------------------------------
        ---------------Input Page Number---------------------------------------------------------------
        reaper.ImGui_SetCursorPos(ctx, 500, 140)
        reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
        rv, pageID = reaper.ImGui_InputText(ctx, 'Page Number', pageID)
        textInputActive = reaper.ImGui_IsAnyItemActive(ctx)
        ---------------Input Executor ID ---------------------------------------------------------------
        reaper.ImGui_SetCursorPos(ctx, 500,170)
        reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
        rv, execID = reaper.ImGui_InputText(ctx, 'Executor ID', execID)
        textInputActive = reaper.ImGui_IsAnyItemActive(ctx)
        
    end
    reaper.ImGui_SetCursorPos(ctx, 500, buttonY)
    
    if reaper.ImGui_Button(ctx, 'Save track config', 145, 50) then
        reaper.SetExtState('trackconfig', 'seqId', seqID , true)
        reaper.SetExtState('trackconfig', 'tcId', tcID, true)
        reaper.SetExtState('trackconfig', 'pageId', pageID, true)
        reaper.SetExtState('trackconfig', 'execId', execID, true)
        
        reaper.ImGui_SameLine(ctx)
    end
    
    ---------------Input TimecodeID---------------------------------------------------------------
    ---------------Add Item Button---------------------------------------------------------------
    reaper.ImGui_SetCursorPos(ctx, buttonX, buttonY)
    if reaper.ImGui_Button(ctx, '   Add\nTC track', buttonWidth, buttonHeight) then
        addTrack()
        
        reaper.ImGui_SameLine(ctx)
    end
    reaper.ImGui_SetCursorPos(ctx, buttonX+buttonWidth+buttonSpace, buttonY)
    
    ImGui.PushID(ctx, 1)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button(),        Color.HSV(1 / 0, 1, 0.3, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), Color.HSV(1 / 0, 1, 0.8, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(),  Color.HSV(1 / 0, 1, 1, 1.0))
    if reaper.ImGui_Button(ctx, '  Delete\nTC track', buttonWidth, buttonHeight) then
        deleteTrack() --@Paul hier wird delete Track ausgeführt (buttonpress)
        reaper.ImGui_SameLine(ctx)
    end
    ImGui.PopStyleColor(ctx, 3)
    ImGui.PopID(ctx)
    ShowFocusHint()
    
    
    
    ---------------POPUPS---------------------------------------------------------------
    ---------------Select Exec Option---------------------------------------------------------------
    if not popups.popups then
        popups.popups = {
            selectedExecOption = 1,
        }
    end
    reaper.ImGui_SetCursorPos(ctx, 9, 110)
    if ImGui.Button(ctx, 'Select exec option') then
        ImGui.OpenPopup(ctx, 'my_select_popup')
    end
    ImGui.SameLine(ctx)
    ImGui.Text(ctx, btnNames[popups.popups.selectedExecOption] or '<None>')
    if ImGui.BeginPopup(ctx, 'my_select_popup') then
        ImGui.SeparatorText(ctx, 'Exec Button Options')
        for i, options in ipairs(btnNames) do
            if ImGui.Selectable(ctx, options) then
                popups.popups.selectedExecOption = i
            end
        end
        ImGui.EndPopup(ctx)
    end
    
    for i = 1, #btnNames, 1 do
        if popups.popups.selectedExecOption == i then
            selectedBtnOption = btnNames[i]
        end
    end
   
end

---------------ADD CUE WINDOW---------------------------------------------------------------
function CueItemWindow()
    local buttonHeight = 50
    local buttonWidth = 80
    local xButtonsStart = 380
    local rv, script_path = isInstalledViaReapack()
    local logoImage_path = script_path..dataFolder..logoFolder..logoBigName
    local logoImage_texture = reaper.ImGui_CreateImage(logoImage_path)
    ImGui.SeparatorText(ctx, 'SETUP EVENT')
    -- Fenstergröße abrufen
    local windowWidth, windowHeight = reaper.ImGui_GetWindowSize(ctx)
    
    -- X-Position des Logos berechnen
    local logoX = (windowWidth - BigLogoWidth) / 2

    -- Bild anzeigen und skalieren
    if logoImage_texture then
        reaper.ImGui_SetCursorPos(ctx, logoX, BigLogoY)
        reaper.ImGui_Image(ctx, logoImage_texture, BigLogoWidth, BigLogoHeight) 
    else
        reaper.ShowMessageBox('Bild konnte nicht geladen werden.', 'Fehler', 0)
    end
    ---------------Input Cuelist Name---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 205)
    rv, inputCueName = reaper.ImGui_InputText(ctx, 'Cuename', inputCueName)
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)
    inputCueNameFieldActive = reaper.ImGui_IsItemActive(ctx)
    if rv then
        inputCueName = replaceSpecialCharacters(inputCueName)
    end
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    rv, fadetime = reaper.ImGui_InputText(ctx, 'Fadetime ', fadetime)
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)

    
    ---------------Add Item Button---------------------------------------------------------------
    reaper.ImGui_SetCursorPos(ctx, xButtonsStart, toptextYoffset * 4.5)
    if reaper.ImGui_Button(ctx, 'Add cue', buttonWidth * 2 + 8, 80) then
        local check = checkTCHelperTracks()
        
        if check == false then
            --consoleMSG('Check False')
        else
            --consoleMSG('Check true')
            
            addItem()
        end 
        ---------------Delete Item Button---------------------------------------------------------------
    end
    ---------------Copy Item Button---------------------------------------------------------------
    reaper.ImGui_SetCursorPos(ctx, xButtonsStart, toptextYoffset + 155)
    if reaper.ImGui_Button(ctx, 'Copy', buttonWidth, buttonHeight) then
        local check = checkTCHelperTracks()
        
        if check == false then
            --consoleMSG('Check False')
        else
            --consoleMSG('Check true')
            
            copySelectedItems()
            
            
        end
        reaper.ImGui_SameLine(ctx)
    end 
    ---------------Paste Item Button---------------------------------------------------------------
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'Paste', buttonWidth, buttonHeight) then
        local check = checkTCHelperTracks()
        
        if check == false then
            --consoleMSG('Check False')
        else
            --consoleMSG('Check true')
            
            pasteItems()
            
        end
        reaper.ImGui_SameLine(ctx)
    end 
    reaper.ImGui_SameLine(ctx)
    ImGui.PushID(ctx, 1)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button(),        Color.HSV(1 / 0, 1, 0.3, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), Color.HSV(1 / 0, 1, 0.8, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(),  Color.HSV(1 / 0, 1, 1, 1.0))
    
    if reaper.ImGui_Button(ctx, '  Delete\nselection', buttonWidth, buttonHeight) then
        deleteSelection()
        reaper.ImGui_SameLine(ctx)
    end 
    ImGui.PopStyleColor(ctx, 3)
    ImGui.PopID(ctx)
    reaper.ImGui_SetCursorPos(ctx, 610, toptextYoffset + 55)
    ShowFocusHint()
end
function TempItemWindow()
    local buttonHeight = 50
    local buttonWidth = 80
    local xButtonsStart = 380
    local rv, script_path = isInstalledViaReapack()
    local logoImage_path = script_path..dataFolder..logoFolder..logoBigName
    local logoImage_texture = reaper.ImGui_CreateImage(logoImage_path)
    ImGui.SeparatorText(ctx, 'SETUP EVENT')
     -- Fenstergröße abrufen
     local windowWidth, windowHeight = reaper.ImGui_GetWindowSize(ctx)
    
     -- X-Position des Logos berechnen
     local logoX = (windowWidth - BigLogoWidth) / 2
 
     -- Bild anzeigen und skalieren
     if logoImage_texture then
         reaper.ImGui_SetCursorPos(ctx, logoX, BigLogoY)
         reaper.ImGui_Image(ctx, logoImage_texture, BigLogoWidth, BigLogoHeight) 
     else
         reaper.ShowMessageBox('Bild konnte nicht geladen werden.', 'Fehler', 0)
     end
    ---------------Input Cuelist Name---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    rv, fadetime = reaper.ImGui_InputText(ctx, 'Fadetime ', fadetime)
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    rv, holdtime = reaper.ImGui_InputText(ctx, 'Holdtime in sec', holdtime)
    textInputActive = reaper.ImGui_IsAnyItemActive(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    
    
    
    ---------------Add Item Button---------------------------------------------------------------
    reaper.ImGui_SetCursorPos(ctx,xButtonsStart, toptextYoffset * 4.5)
    if reaper.ImGui_Button(ctx, '      Add\nbuttonpress', buttonWidth * 2 + 8, 80) then
        --cueName = 'Cue '..cueNr
        local check = checkTCHelperTracks()

        if check == false then
            --consoleMSG('Check False')
        else
            --consoleMSG('Check true')

        addItem()
        
        end
    end
    
     ---------------Copy Item Button---------------------------------------------------------------
     reaper.ImGui_SetCursorPos(ctx, xButtonsStart, toptextYoffset + 155)
     if reaper.ImGui_Button(ctx, 'Copy', buttonWidth, buttonHeight) then
         local check = checkTCHelperTracks()
 
         if check == false then
             --consoleMSG('Check False')
         else
             --consoleMSG('Check true')
 
             copySelectedItems()
 
 
         end
         reaper.ImGui_SameLine(ctx)
     end 
     ---------------Paste Item Button---------------------------------------------------------------
     reaper.ImGui_SameLine(ctx)
     if reaper.ImGui_Button(ctx, 'Paste', buttonWidth, buttonHeight) then
         local check = checkTCHelperTracks()
 
         if check == false then
             --consoleMSG('Check False')
         else
             --consoleMSG('Check true')
 
             pasteItems()
 
         end
         reaper.ImGui_SameLine(ctx)
     end 
     ---------------Delete Item Button---------------------------------------------------------------
    reaper.ImGui_SameLine(ctx)
    ImGui.PushID(ctx, 1)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button(),        Color.HSV(1 / 0, 1, 0.3, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), Color.HSV(1 / 0, 1, 0.8, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(),  Color.HSV(1 / 0, 1, 1, 1.0))
    if reaper.ImGui_Button(ctx, '  Delete\nselection', buttonWidth, buttonHeight) then
        deleteSelection()
        reaper.ImGui_SameLine(ctx)
    end 
    ImGui.PopStyleColor(ctx, 3)
    ImGui.PopID(ctx)
    ShowFocusHint()
end
-----------------RENAMEING DATA WINDOWS-------------------------------------------------------------
function renameTrackWindow()
    getTrackContent()
    local spaceBtn = 20
    local minPaneWidth = 200
    local minTextWidth = 150
    local minButtonWidth = 100
    local minButtonHeight = 100
    local minWindowWidth = minPaneWidth + minButtonWidth + spaceBtn + 50

    local windowWidth, windowHeight = reaper.ImGui_GetWindowSize(ctx)
    windowWidth = math.max(windowWidth, minWindowWidth)
    local paneWidth = math.max(minPaneWidth, windowWidth - minButtonWidth - spaceBtn - 50)
    local textWidth = paneWidth - 100
    local buttonWidth = math.max(minButtonWidth, 100)
    local buttonHeight = math.max(minButtonHeight, 100)

    local usedTracks = readTrackGUID('used')
    local seqIDs = {}
    local existingNames = {} -- Tabelle zur Überprüfung auf doppelte Namen

    -- Initialisiere die Liste der neuen Sequenznamen, falls sie noch nicht existiert
    if not newSeqNames or #newSeqNames ~= #usedTracks or trackRenamed  then
        newSeqNames = getSeqNames()
        trackRenamed = false
    end

    -- Bestehende Namen sammeln
    for i = 1, #usedTracks, 1 do
        seqIDs[i] = loadedtracks[usedTracks[i]].seqID
        existingNames[newSeqNames[i]] = true
    end

    reaper.ImGui_Text(ctx, 'Sequence Names')
    if reaper.ImGui_BeginChild(ctx, 'left pane', paneWidth, windowHeight - 50, true) then
        for i = 1, #usedTracks, 1 do
            reaper.ImGui_SetNextItemWidth(ctx, textWidth)
            if newSeqNames[i] == nil then
                newSeqNames[i] = 'deleted'
            end

            -- Eingabefeld für den neuen Namen
            local rv, newName = reaper.ImGui_InputText(ctx, 'Seq ' .. seqIDs[i], newSeqNames[i])
            textInputActive = reaper.ImGui_IsAnyItemActive(ctx)

            -- Speichere den neuen Namen in der Liste, wenn er geändert wurde
            if rv then
                newSeqNames[i] = newName
            end
        end
        reaper.ImGui_EndChild(ctx)
    end

    -- Button zum Schreiben der neuen Daten
    reaper.ImGui_SetCursorPos(ctx, paneWidth + spaceBtn, 60)
    if reaper.ImGui_Button(ctx, 'WRITE NEW\n     DATA', buttonWidth, buttonHeight) then
        renameTrack(newSeqNames) -- Schreibe die neuen Namen in die Tracks
        newSeqNames = getSeqNames()

    end

    -- Dummy-Komponente hinzufügen, um die Fenstergrenzen zu validieren
    reaper.ImGui_Dummy(ctx, 0, 0)
end
function renameCuesWindow()
    local spaceBtn = 20
    local minPaneWidth = 100
    local minTextWidth = 100
    local minFadeWidth = 50
    local minButtonWidth = 100
    local minButtonHeight = 20
    local minWindowWidth = minPaneWidth + minButtonWidth + spaceBtn + 50

    local windowWidth, windowHeight = reaper.ImGui_GetWindowSize(ctx)
    windowWidth = math.max(windowWidth, minWindowWidth)
    local paneWidth = math.max(minPaneWidth, windowWidth - minButtonWidth - spaceBtn - 20)
    local fadeWidth = math.max(minFadeWidth, 50)
    local buttonWidth = math.max(minButtonWidth, 100)
    local buttonHeight = math.max(minButtonHeight, 20)
    local textWidth = paneWidth - fadeWidth - buttonWidth - 170
    local spacer = 20
    local usedTracks = readTrackGUID('used')
    local tcTrack = readTrackGUID('selected')

    -- Überprüfen, ob der ausgewählte Track in den verwendeten Tracks vorhanden ist
    local trackFound = false
    for _, track in ipairs(usedTracks) do
        if track == tcTrack then
            trackFound = true
            break
        end
    end
    -- Wenn der ausgewählte Track nicht in den verwendeten Tracks vorhanden ist, setze tcTrack auf den ersten verwendeten Track
    if not trackFound then
        tcTrack = usedTracks[1]
    end

    if tcTrack == nil or trackFound == false then
        reaper.ImGui_Text(ctx, 'No TCHelper track selected')
        tcTrack = previousTrackGUID
        return
    end
    if previousTrackGUID ~= tcTrack or eventAdded then
        NewCueNames = getCueNames()
        NewFadeTimes = getFadeTimes()
        previousTrackGUID = tcTrack
        eventAdded = false
    end

    if not app.layout then
        app.layout = {
            selected = 0,
        }
    end
    seqName = loadedtracks[tcTrack].name or "No track"
    reaper.ImGui_Text(ctx, 'Selected track: ' .. seqName)

    -- Prüfe, ob Temp/Flash
    local isTempOrFlash = loadedtracks[tcTrack] and (
        loadedtracks[tcTrack].execoption == "Temp Button" or
        loadedtracks[tcTrack].execoption == "Flash Button"
    )

    if reaper.ImGui_BeginChild(ctx, 'left pane', paneWidth, windowHeight - 50, true) then
        reaper.ImGui_SetCursorPos(ctx, 10, 10)
        reaper.ImGui_Text(ctx, 'Cuenames')
        reaper.ImGui_SetCursorPos(ctx, paneWidth - fadeWidth - buttonWidth - 90, 10)
        reaper.ImGui_Text(ctx, 'Fadetimes')
        local j = 0
        local lineHeight = reaper.ImGui_GetTextLineHeight(ctx) + 8
        for i = 1, #NewCueNames, 1 do
            local cueID = (i < 10) and string.format('%02d', i) or i
            local startY = 30 + (i - 1) * lineHeight

            -- CUE NAME
            reaper.ImGui_SetCursorPos(ctx, 10, startY)
            if isTempOrFlash and i > 1 then
                reaper.ImGui_BeginDisabled(ctx)
                reaper.ImGui_SetNextItemWidth(ctx, textWidth)
                reaper.ImGui_InputText(ctx, 'Cue-' .. cueID, NewCueNames[i] or "", reaper.ImGui_InputTextFlags_ReadOnly())
                reaper.ImGui_EndDisabled(ctx)
            else
                reaper.ImGui_SetNextItemWidth(ctx, textWidth)
                local rv1
                rv1, NewCueNames[i] = reaper.ImGui_InputText(ctx, 'Cue-' .. cueID, NewCueNames[i])
            end

            -- FADETIME
            local fadeX = paneWidth - fadeWidth - buttonWidth - 90
            reaper.ImGui_SetCursorPos(ctx, fadeX, startY)
            if isTempOrFlash and i > 1 then
                reaper.ImGui_BeginDisabled(ctx)
                reaper.ImGui_SetNextItemWidth(ctx, fadeWidth)
                reaper.ImGui_InputText(ctx, 'Fade-' .. cueID, NewFadeTimes[i] or "", reaper.ImGui_InputTextFlags_ReadOnly())
                reaper.ImGui_EndDisabled(ctx)
            else
                reaper.ImGui_SetNextItemWidth(ctx, fadeWidth)
                local rv2
                rv2, NewFadeTimes[i] = reaper.ImGui_InputText(ctx, 'Fade-' .. cueID, NewFadeTimes[i])
            end

            -- JUMP BUTTON
            local jumpX = paneWidth - buttonWidth - 10
            reaper.ImGui_SetCursorPos(ctx, jumpX, startY)
            if reaper.ImGui_Button(ctx, 'jump ' .. i, buttonWidth, buttonHeight) then
                local trackItem = reaper.BR_GetMediaTrackByGUID(0, tcTrack)
                local item = reaper.GetTrackMediaItem(trackItem, j)
                local rv, itemGUID = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)
                local newCursorPos = loadedtracks[tcTrack].cue[itemGUID].itemStart
                setCursorToItem(newCursorPos)
            end
            j = j + 1
        end
        reaper.ImGui_EndChild(ctx)
    end
    reaper.ImGui_SetCursorPos(ctx, paneWidth + spaceBtn, 60)
    if reaper.ImGui_Button(ctx, 'WRITE NEW\n     DATA', buttonWidth, 80) then
        renameItems()
        NewCueNames = getCueNames()
        NewFadeTimes = getFadeTimes()
    end

    -- Dummy-Komponente hinzufügen, um die Fenstergrenzen zu validieren
    reaper.ImGui_Dummy(ctx, 0, 0)
end
function openCuesWindow()
    ImGui.SetNextWindowSize(ctx, 400, 440, ImGui.Cond_FirstUseEver())
    if not cueDocked then
        reaper.ImGui_SetNextWindowDockID(ctx, cueDockID, reaper.ImGui_Cond_FirstUseEver())
        cueDocked = true
    end
    visible, cuesChecked = ImGui.Begin(ctx, 'Cue Data', true, ImGui.WindowFlags_MenuBar())
    if visible then
        renameCuesWindow()
        getTrackContent()
        cueDockID = reaper.ImGui_GetWindowDockID(ctx)
        reaper.SetExtState("TCHelper", "CueDockID", tostring(cueDockID), true)
        reaper.ImGui_End(ctx)
    end
    return cuesChecked
end
function openTrackWindow()
    ImGui.SetNextWindowSize(ctx, 400, 440, ImGui.Cond_FirstUseEver())
    if not trackDocked then
        reaper.ImGui_SetNextWindowDockID(ctx, trackDockID, reaper.ImGui_Cond_FirstUseEver())
        trackDocked = true
    end
    visible, seqChecked = ImGui.Begin(ctx, 'Sequence Data', true, ImGui.WindowFlags_MenuBar())
    if visible then
        renameTrackWindow()
        getTrackContent()
        trackDockID = reaper.ImGui_GetWindowDockID(ctx)
        reaper.SetExtState("TCHelper", "TrackDockID", tostring(trackDockID), true)
        reaper.ImGui_End(ctx)
    end
    return seqChecked
end
function openConnectionWindow()
    local windowWidth, windowHeight = 525, 319
    reaper.ImGui_SetNextWindowSize(ctx, windowWidth, windowHeight, reaper.ImGui_Cond_Always())
    local windowFlags = reaper.ImGui_WindowFlags_NoResize()

    visible, networkChecked = reaper.ImGui_Begin(ctx, 'Connection Settings', true, windowFlags)
    if visible then
        if MAmode == 'Mode 3' then
            connectionWindowMode3()
        elseif MAmode == 'Mode 2' then
            connectionWindowMode2()
        end
        reaper.ImGui_End(ctx)
    end
    
    return networkChecked
end
---------------ADD Track -------------------------------------------------------------------
function addTrack()
    -- Stelle sicher, dass trackShortcuts initialisiert ist
    trackShortcuts = trackShortcuts or {}

    local red = 0
    local green = 0
    local blue = 0
    local buttonName = ''
    local trackAmmount = reaper.GetNumTracks()
    local newTrackID = trackAmmount + 1
    local rv, script_path = isInstalledViaReapack()
    local trackImage_path = script_path..dataFolder..iconFolder
    local newTrackGUID = {}
    local existingNames = {}
    local existingSeqIDs = {}
    local defaultShortcuts = {"1", "2", "3", "4", "5", "6", "7", "8", "9"}
    -- Sammle bestehende CueList-Namen
    local usedTracks = readTrackGUID('used')
    for i = 1, #usedTracks do
        local trackName = loadedtracks[usedTracks[i]].name
        existingNames[trackName] = true
    end

    -- Sammle bestehende Sequence IDs
    for i = 1, #usedTracks do
        local trackSeqID = tonumber(loadedtracks[usedTracks[i]].seqID)
        if trackSeqID then
            existingSeqIDs[trackSeqID] = true
        end
    end

    -- Stelle sicher, dass die Sequence ID eindeutig ist
    seqID = tonumber(reaper.GetExtState('trackconfig', 'seqId')) or 1
    while existingSeqIDs[seqID] do
        seqID = seqID + 1
    end
    reaper.SetExtState('trackconfig', 'seqId', tostring(seqID + 1), true)

    reaper.InsertTrackAtIndex(newTrackID, true)
    if selectedBtnOption == btnNames[1] then -------------CUELIST
        selectedIcon = trackIcon.name[1]
        buttonName = btnNames[1]
        red = 248
        green = 177
        blue = 55
    elseif selectedBtnOption == btnNames[2] then ---------FLASH
        selectedIcon = trackIcon.name[2]
        buttonName = btnNames[2]
        red = 0
        green = 129
        blue = 43
    elseif selectedBtnOption == btnNames[3] then ---------TEMP
        selectedIcon = trackIcon.name[3]
        buttonName = btnNames[3]
        red = 0
        green = 153
        blue = 205
    elseif selectedBtnOption == btnNames[4] then ---------TOP
        selectedIcon = trackIcon.name[4]
        buttonName = btnNames[4]
        red = 208
        green = 92
        blue = 120
    elseif selectedBtnOption == btnNames[5] then ---------TOP&RELEASE
        selectedIcon = trackIcon.name[5]
        buttonName = btnNames[5]
        red = 163
        green = 198
        blue = 142
    end

    -- Stelle sicher, dass der CueList-Name eindeutig ist
    cueListName = ensureUniqueSeqName(cueListName, existingNames)

    if MAmode == 'Mode 3' then
        trackName = '|'..cueListName .. '|SeqID:' .. seqID ..'|'..buttonName .. '|TC ID:' .. tcID..'|'
    elseif MAmode == 'Mode 2' then
        trackName = '|'..cueListName .. '|SeqID:' .. seqID ..'|'..buttonName .. '|TC ID:' .. tcID..'|Page:'..pageID..'|Exec ID:'..execID..'|'
    end
    local track = reaper.GetTrack(0, newTrackID - 1)
    local iconPath = trackImage_path .. selectedIcon
    reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', trackName, true)
    reaper.GetSetMediaTrackInfo_String(track, 'P_ICON', iconPath, true)
    reaper.SetTrackColor(track, reaper.ColorToNative(red, green, blue))

    newTrackGUID = reaper.GetTrackGUID(track)
    tracks[newTrackGUID] = {}
    tracks[newTrackGUID] = dummytrack
    tracks[newTrackGUID].id = newTrackGUID
    tracks[newTrackGUID].name = trackName
    tracks[newTrackGUID].execID = execID
    tracks[newTrackGUID].pageID = pageID
    tracks[newTrackGUID].seqID = seqID
    tracks[newTrackGUID].execoption = buttonName
    SetupSendedDataTrack(newTrackGUID)

    -- Füge den neuen Track zu trackShortcuts hinzu
    local usedTracks = readTrackGUID('used')
    for i = 1, #usedTracks, 1 do
        if i <= 9 then
            -- consoleMSG('usedTracks['..i..'] = ' .. usedTracks[i])
            -- consoleMSG('newTrackGUID = ' .. newTrackGUID)
            if newTrackGUID == usedTracks[i] then
                trackShortcuts[newTrackGUID] = defaultShortcuts[i]
                
            end
        end
    end
    saveShortcuts()
    getTrackContent()
    pendingLiveUpdate = true
end
function deleteTrack()
    --reaper.ShowConsoleMsg('\nDELETE TRACK START')
    getTrackContent()
    getSeqNames()
    local trackGUIDS = readTrackGUID('used')
    local selectedTrackGUID = readTrackGUID('selected')

    local trackPos = 1
    for i = 1, #trackGUIDS, 1 do
        if loadedtracks[trackGUIDS[i]].id == trackGUIDS[i] then
            trackPos = i
        end 
    end
    local numSelectedTracks = reaper.CountSelectedTracks(0)
    if numSelectedTracks > 0 then
        reaper.PreventUIRefresh(1) -- Disable UI updates to prevent flickering
        
        for i = numSelectedTracks, 1, -1 do
            local track = reaper.GetSelectedTrack(0, i-1)
            local trackGUID = reaper.GetTrackGUID(track)
            local trackName = loadedtracks[trackGUID] and loadedtracks[trackGUID].name or "Unknown"

            --table.remove(loadedtracks[trackGUID],trackPos)
            if liveupdatebox == true then
                local seqMessage = 'Delete Seq "'..trackName..'" /nc'
                local tcMessage = 'Delete Timecode '..tcID..'.1.'..(loadedtracks[trackGUID] and loadedtracks[trackGUID].nr or "Unknown")
                sendOSC(hostIP, consolePort, seqMessage)
                sendOSC(hostIP, consolePort, tcMessage)
            end
            reaper.DeleteTrack(track)
            loadedtracks[selectedTrackGUID] = nil

            -- Reduziere die Seq ID um 1
            local currentSeqID = tonumber(reaper.GetExtState('trackconfig', 'seqId')) or 1
            if currentSeqID > 1 then
                reaper.SetExtState('trackconfig', 'seqId', tostring(currentSeqID - 1), true)
            end
            -- Shortcut aus trackShortcuts entfernen
            if trackShortcuts and trackShortcuts[trackGUID] then
                trackShortcuts[trackGUID] = nil
            end
        end      
        saveShortcuts()
        reaper.PreventUIRefresh(-1) -- Enable UI updates
        reaper.UpdateArrange() -- Refresh the GUI
    else
        reaper.ShowMessageBox("No tracks selected.", "Error", 0)
    end
    getTrackContent()
    pendingLiveUpdate = true
    --reaper.ShowConsoleMsg('\nDELETE TRACK END')
end
function renameTrack(newSeqNames)
    getTrackContent()
    local trackGUIDs = readTrackGUID('used')
    local existingNames = {}

    -- Sammle bestehende Namen, um sie in ensureUniqueSeqName zu verwenden
    for i = 1, #trackGUIDs do
        local trackName = loadedtracks[trackGUIDs[i]].name
        existingNames[trackName] = true
    end

    for i = 1, #newSeqNames, 1 do
        local trackItem = reaper.BR_GetMediaTrackByGUID(0, trackGUIDs[i])
        if trackItem then
            local oldSeqID = loadedtracks[trackGUIDs[i]].seqID
            local oldButtonName = loadedtracks[trackGUIDs[i]].execoption
            local oldTCID = loadedtracks[trackGUIDs[i]].tcID

            -- ***LÖSUNG: Eigenen Namen vorübergehend aus existingNames entfernen***
            local oldName = loadedtracks[trackGUIDs[i]].name
            existingNames[oldName] = nil

            -- Überprüfe und stelle sicher, dass der neue Name eindeutig ist
            local uniqueName = ensureUniqueSeqName(newSeqNames[i], existingNames)

            -- Nach dem Check neuen Namen wieder eintragen
            existingNames[uniqueName] = true

            -- Generiere den neuen Namen basierend auf den bestehenden Daten
            local newName = ''
            if MAmode == 'Mode 3' then
                newName = '|' .. uniqueName .. '|SeqID:' .. oldSeqID .. '|' .. oldButtonName .. '|TC ID:' .. oldTCID .. '|'
            elseif MAmode == 'Mode 2' then
                local oldPageID = loadedtracks[trackGUIDs[i]].pageID
                local oldExecID = loadedtracks[trackGUIDs[i]].execID
                newName = '|' .. uniqueName .. '|SeqID:' .. oldSeqID .. '|' .. oldButtonName .. '|TC ID:' .. oldTCID .. '|Page:' .. oldPageID .. '|Exec ID:' .. oldExecID .. '|'
            end

            -- Aktualisiere den Track-Namen
            reaper.GetSetMediaTrackInfo_String(trackItem, 'P_NAME', newName, true)

            -- Aktualisiere den geladenen Track-Datensatz
            loadedtracks[trackGUIDs[i]].name = uniqueName

            -- Füge den neuen Namen zur Liste der bestehenden Namen hinzu
            existingNames[uniqueName] = true
        end
    end

    getTrackContent()
    trackRenamed = true
    pendingLiveUpdate = true
end
---------------Delete Selection-------------------------------------------------------------------
function deleteSelection()
    getTrackContent()
    --reaper.ShowConsoleMsg('\n--DELETE STARTED--')
    local selectedGUIDS = {}
    local trackGUID = readTrackGUID('selected')
    local numSelectedItems = reaper.CountSelectedMediaItems(0)
    local selectedItems = {}
    if numSelectedItems > 0 then
        for i = 0, numSelectedItems - 1 do
            local selectedItem = reaper.GetSelectedMediaItem(0, i)
            table.insert(selectedItems, selectedItem)
            local rv, loadedGUID = reaper.GetSetMediaItemInfo_String(selectedItem, "GUID", "", false)
            table.insert(selectedGUIDS, loadedGUID)
        end
        for i = #selectedGUIDS, 1, -1 do
            if loadedtracks[trackGUID] and loadedtracks[trackGUID].cue[selectedGUIDS[i]] then
                local cueName = loadedtracks[trackGUID].cue[selectedGUIDS[i]].name
                local cueListName = loadedtracks[trackGUID].name
                local trackID = loadedtracks[trackGUID].trackNr
                -- reaper.ShowConsoleMsg('\nCueName '..i..': '..cueName)
                -- reaper.ShowConsoleMsg('\nCueListName '..i..': '..cueListName)
                if liveupdatebox == true then
                    if loadedtracks[trackGUID].execoption == 'Cue List' then
                        local seqMessage = 'Delete Sequence "'..cueListName..'" Cue "'..cueName..'" /nc'
                        local TCMessage = 'Delete Timecode ' ..tcID ..'.1.'.. trackID .. '.1.1.'..loadedtracks[trackGUID].cue[selectedGUIDS[i]].cuenr..' /nc'
                        -- reaper.ShowConsoleMsg('\n'..seqMessage)
                        -- reaper.ShowConsoleMsg('\n'..TCMessage)
                        sendOSC(hostIP, consolePort, seqMessage)    
                        sendOSC(hostIP, consolePort, TCMessage)   
                    elseif loadedtracks[trackGUID].execoption == 'Flash Button' or 'Temp Button' then
                        local onNr = loadedtracks[trackGUID].cue[selectedGUIDS[i]].cuenr
                        local offNr = loadedtracks[trackGUID].cue[selectedGUIDS[i]].cuenr
                        if onNr == 1 then
                            onNr = onNr
                            offNr = offNr
                        else
                            onNr = onNr * 2 - 1
                            offNr = offNr * 2
                        end
                        local TCMessageOff = 'Delete Timecode ' ..tcID ..'.1.'.. trackID .. '.1.1.'..offNr..' /nc'
                        local TCMessageOn = 'Delete Timecode ' ..tcID ..'.1.'.. trackID .. '.1.1.'..onNr..' /nc'
                        sendOSC(hostIP, consolePort, TCMessageOff)
                        sendOSC(hostIP, consolePort, TCMessageOn)        
                        local itemCount = getItemCount() 
                        itemCount = itemCount - 1                    
                    end

                end
            end    
        end
        for i = 1, #selectedItems, 1 do
            reaper.DeleteTrackMediaItem(reaper.GetMediaItem_Track(selectedItems[i]), selectedItems[i])
        end
    else
        reaper.ShowMessageBox("No Cues selected.", "Error", 0)
    end
    NewCueNames = getCueNames()
    NewFadeTimes = getFadeTimes()
    getTrackContent()
    pendingLiveUpdate = true
    --reaper.ShowConsoleMsg('\n--DELETE ENDED--')
end
---------------ADD Item --------------------------------------------------------------------
function addItem(trackGUID)
    local definedTrackGUID = trackGUID
    getTrackContent()
    if definedTrackGUID == nil then
        noTrackError()
    end
    local retval
    local selected_trk = reaper.GetSelectedTrack(0, 0)
    trackGUID = definedTrackGUID or readTrackGUID('selected') -- Verwende den übergebenen Track oder den ausgewählten Track
    local playPos = reaper.GetPlayPosition()
    local cursorpos = reaper.GetCursorPosition()
    local media_item = nil
    local itemName = 'ph'
    local pressNr = cueNr
    local itemcount = getItemCount()

    if definedTrackGUID == nil then
        if not selected_trk then
            reaper.ShowMessageBox("No valid track selected or provided.", "Error", 0)
            return
        end
    end

    local track = reaper.BR_GetMediaTrackByGUID(0, trackGUID)
    if not track then
        reaper.ShowMessageBox("Track not found.", "Error", 0)
        return
    end

    -- Berechne die aktuelle Anzahl der Cues im Ziel-Track
    local targetTrackGUID = trackGUID
    local targetTrack = reaper.BR_GetMediaTrackByGUID(0, targetTrackGUID)
    local targetItemCount = reaper.CountTrackMediaItems(targetTrack)

    -- Setze die Cue-Nummer basierend auf der Anzahl der bestehenden Cues
    cueNr = targetItemCount + 1

    media_item = reaper.AddMediaItemToTrack(track)
    local insertTime = -1
    local playState = reaper.GetPlayState()
    if playState == 1 then
        insertTime = playPos
    else
        insertTime = cursorpos
    end
    if definedTrackGUID ~= nil then -- Name definition bei Shortcut benutzung
        if loadedtracks[definedTrackGUID].execoption == 'Cue List' then
            selectedOption = 'Cue List'
        elseif loadedtracks[definedTrackGUID].execoption == 'Flash Button' then
            selectedOption = 'Flash Button'
        elseif loadedtracks[definedTrackGUID].execoption == 'Temp Button' then
            selectedOption = 'Temp Button'
        end
        local itemammount = getItemCount(definedTrackGUID)
        inputCueName = 'Cue - '..itemammount
    end
    if selectedOption == 'Cue List' then 
        itemName = '|' .. inputCueName .. '|\n|' .. loadedtracks[trackGUID].execoption .. '|\n|Cue: ' .. cueNr .. '|\n|Fadetime: ' .. fadetime .. '|'
    elseif selectedOption == 'Flash Button' or 'Temp Button' then
        itemName = '|' .. inputCueName .. '|\n|' .. loadedtracks[trackGUID].execoption .. '|\n|Press: ' .. pressNr .. '|\n|Fadetime: ' .. fadetime .. '|\n|Hold: ' .. holdtime .. '|'
        pressNr = pressNr + 1
    end

    reaper.SetMediaItemInfo_Value(media_item, "D_POSITION", insertTime)
    if selectedOption == 'Cuelist' then
        reaper.SetMediaItemInfo_Value(media_item, "D_LENGTH", 10)
    elseif selectedOption == 'Flash Button' or 'Temp Button' then
        local holdnum = tonumber(holdtime)
        local fadenum = tonumber(fadetime)
        local endTime = holdnum + fadenum
        reaper.SetMediaItemInfo_Value(media_item, "D_LENGTH", holdnum)
    end

    if track then
        local itemCount = reaper.CountTrackMediaItems(track)
        if itemCount > 0 then
            reaper.GetSetMediaItemInfo_String(media_item, "P_NOTES", itemName, true)
        end
    end

    local newCueGUID = reaper.BR_GetMediaItemGUID(media_item)
    if tracks[trackGUID] == nil then
        tracks[trackGUID] = {}
        tracks[trackGUID] = dummytrack
    end
    if tracks[trackGUID].cue[newCueGUID] == nil then
        tracks[trackGUID].cue[newCueGUID] = {}
    end
    tracks[trackGUID].cue[newCueGUID].id = newCueGUID
    tracks[trackGUID].cue[newCueGUID].name = itemName
    tracks[trackGUID].cue[newCueGUID].fadetime = fadetime
    SetupSendedDataItem(trackGUID, newCueGUID)
    renumberItems()
    if trackShortcutsSafed == false then
        initializeTrackShortcuts()

    end
    getTrackContent()
    eventAdded = true
    pendingLiveUpdate = true
end
function renameItems()
    getTrackContent()
    local itemName = 'ph'
    local selectedTrack = reaper.GetSelectedTrack(0, 0)
    local trackGUID = readTrackGUID('selected')
    local cueAmmount = 0
    local cueGUIDs = 'empty'
    local mediaItem = {}
    if selectedTrack ~= nil then
        cueAmmount = reaper.CountTrackMediaItems(selectedTrack)
        cueGUIDs = readItemGUID(trackGUID)
    end
    local cueFade = {}

    -- Prüfe, ob der Track ein Temp oder Flash Button ist
    local isTempOrFlash = loadedtracks[trackGUID] and (
        loadedtracks[trackGUID].execoption == "Temp Button" or
        loadedtracks[trackGUID].execoption == "Flash Button"
    )

    -- Wenn Temp/Flash: hole den neuen Namen und die neue Fadezeit aus dem ersten Feld und setze sie für alle Cues
    local newNameForAll = nil
    local newFadeForAll = nil
    if isTempOrFlash and NewCueNames and #NewCueNames > 0 then
        newNameForAll = replaceSpecialCharacters(NewCueNames[1])
    end
    if isTempOrFlash and NewFadeTimes and #NewFadeTimes > 0 then
        newFadeForAll = NewFadeTimes[1]
    end

    for i = 1, cueAmmount, 1 do
        mediaItem[i] = reaper.BR_GetMediaItemByGUID(0, cueGUIDs[i])
    end
    for i = 1, cueAmmount, 1 do
        local inputName
        local inputFade
        if isTempOrFlash and newNameForAll then
            inputName = newNameForAll
        else
            inputName = replaceSpecialCharacters(NewCueNames[i])
        end
        if isTempOrFlash and newFadeForAll then
            inputFade = newFadeForAll
        else
            inputFade = NewFadeTimes[i]
        end
        itemName = '|' ..inputName..'|\n|' ..loadedtracks[trackGUID].execoption .. '|\n|Cue: ' .. i .. '|\n|Fadetime: ' ..inputFade .. '|'
        reaper.GetSetMediaItemInfo_String(mediaItem[i], "P_NOTES", itemName, true)
    end
    checkDuplicateCueNames()
    reaper.ThemeLayout_RefreshAll()
    getTrackContent()
    pendingLiveUpdate = true
end

function renameCuesWindow()
    local spaceBtn = 20
    local minPaneWidth = 100
    local minTextWidth = 100
    local minFadeWidth = 50
    local minButtonWidth = 100
    local minButtonHeight = 20
    local minWindowWidth = minPaneWidth + minButtonWidth + spaceBtn + 50

    local windowWidth, windowHeight = reaper.ImGui_GetWindowSize(ctx)
    windowWidth = math.max(windowWidth, minWindowWidth)
    local paneWidth = math.max(minPaneWidth, windowWidth - minButtonWidth - spaceBtn - 20)
    local fadeWidth = math.max(minFadeWidth, 50)
    local buttonWidth = math.max(minButtonWidth, 100)
    local buttonHeight = math.max(minButtonHeight, 20)
    local textWidth = paneWidth - fadeWidth - buttonWidth - 170
    local spacer = 20
    local usedTracks = readTrackGUID('used')
    local tcTrack = readTrackGUID('selected')

    -- Überprüfen, ob der ausgewählte Track in den verwendeten Tracks vorhanden ist
    local trackFound = false
    for _, track in ipairs(usedTracks) do
        if track == tcTrack then
            trackFound = true
            break
        end
    end
    -- Wenn der ausgewählte Track nicht in den verwendeten Tracks vorhanden ist, setze tcTrack auf den ersten verwendeten Track
    if not trackFound then
        tcTrack = usedTracks[1]
    end

    if tcTrack == nil or trackFound == false then
        reaper.ImGui_Text(ctx, 'No TCHelper track selected')
        tcTrack = previousTrackGUID
        return
    end
    if previousTrackGUID ~= tcTrack or eventAdded then
        NewCueNames = getCueNames()
        NewFadeTimes = getFadeTimes()
        previousTrackGUID = tcTrack
        eventAdded = false
    end

    if not app.layout then
        app.layout = {
            selected = 0,
        }
    end
    seqName = loadedtracks[tcTrack].name or "No track"
    reaper.ImGui_Text(ctx, 'Selected track: ' .. seqName)

    -- Prüfe, ob Temp/Flash
    local isTempOrFlash = loadedtracks[tcTrack] and (
        loadedtracks[tcTrack].execoption == "Temp Button" or
        loadedtracks[tcTrack].execoption == "Flash Button"
    )

    if reaper.ImGui_BeginChild(ctx, 'left pane', paneWidth, windowHeight - 50, true) then
        reaper.ImGui_SetCursorPos(ctx, 10, 10)
        reaper.ImGui_Text(ctx, 'Cuenames')
        reaper.ImGui_SetCursorPos(ctx, paneWidth - fadeWidth - buttonWidth - 90, 10)
        reaper.ImGui_Text(ctx, 'Fadetimes')
        local j = 0
        local lineHeight = reaper.ImGui_GetTextLineHeight(ctx) + 8
        for i = 1, #NewCueNames, 1 do
            local cueID = (i < 10) and string.format('%02d', i) or i
            local startY = 30 + (i - 1) * lineHeight

            -- CUE NAME
            reaper.ImGui_SetCursorPos(ctx, 10, startY)
            if isTempOrFlash and i > 1 then
                reaper.ImGui_BeginDisabled(ctx)
                reaper.ImGui_SetNextItemWidth(ctx, textWidth)
                reaper.ImGui_InputText(ctx, 'Cue-' .. cueID, NewCueNames[i] or "", reaper.ImGui_InputTextFlags_ReadOnly())
                reaper.ImGui_EndDisabled(ctx)
            else
                reaper.ImGui_SetNextItemWidth(ctx, textWidth)
                local rv1
                rv1, NewCueNames[i] = reaper.ImGui_InputText(ctx, 'Cue-' .. cueID, NewCueNames[i])
            end

            -- FADETIME
            local fadeX = paneWidth - fadeWidth - buttonWidth - 90
            reaper.ImGui_SetCursorPos(ctx, fadeX, startY)
            if isTempOrFlash and i > 1 then
                reaper.ImGui_BeginDisabled(ctx)
                reaper.ImGui_SetNextItemWidth(ctx, fadeWidth)
                reaper.ImGui_InputText(ctx, 'Fade-' .. cueID, NewFadeTimes[i] or "", reaper.ImGui_InputTextFlags_ReadOnly())
                reaper.ImGui_EndDisabled(ctx)
            else
                reaper.ImGui_SetNextItemWidth(ctx, fadeWidth)
                local rv2
                rv2, NewFadeTimes[i] = reaper.ImGui_InputText(ctx, 'Fade-' .. cueID, NewFadeTimes[i])
            end

            -- JUMP BUTTON
            local jumpX = paneWidth - buttonWidth - 10
            reaper.ImGui_SetCursorPos(ctx, jumpX, startY)
            if reaper.ImGui_Button(ctx, 'jump ' .. i, buttonWidth, buttonHeight) then
                local trackItem = reaper.BR_GetMediaTrackByGUID(0, tcTrack)
                local item = reaper.GetTrackMediaItem(trackItem, j)
                local rv, itemGUID = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)
                local newCursorPos = loadedtracks[tcTrack].cue[itemGUID].itemStart
                setCursorToItem(newCursorPos)
            end
            j = j + 1
        end
        reaper.ImGui_EndChild(ctx)
    end
    reaper.ImGui_SetCursorPos(ctx, paneWidth + spaceBtn, 60)
    if reaper.ImGui_Button(ctx, 'WRITE NEW\n     DATA', buttonWidth, 80) then
        renameItems()
        NewCueNames = getCueNames()
        NewFadeTimes = getFadeTimes()
    end

    -- Dummy-Komponente hinzufügen, um die Fenstergrenzen zu validieren
    reaper.ImGui_Dummy(ctx, 0, 0)
end
function renumberItems()
    local selTrack = readTrackGUID('selected')
    local track = reaper.BR_GetMediaTrackByGUID(0, selTrack)
    if selTrack ~= nil then
        local itemGUID = readItemGUID(selTrack)
        local itemamount = reaper.CountTrackMediaItems(track)
        local namePart = {}
        local oldCueNr = {}
        if loadedtracks[selTrack] ~= nil then
            local seqID = loadedtracks[selTrack].seqID
            for i = 1, itemamount do
                local name = ''
                namePart[i] = {}
                local rv = ''
                local mediaItem = reaper.BR_GetMediaItemByGUID(0, itemGUID[i])
                rv, name = reaper.GetSetMediaItemInfo_String(mediaItem, "P_NOTES", name, false)
                -- Robust: Wenn Note leer oder zerstört, mit Default auffüllen
                if not name or name == "" then
                    -- Versuche, die Daten aus loadedtracks zu holen
                    local cue = loadedtracks[selTrack].cue[itemGUID[i]]
                    local cueName = cue and cue.name or ("Cue - " .. i)
                    local execoption = loadedtracks[selTrack].execoption or "Cue List"
                    local fadetime = cue and cue.fadetime or "2"
                    name = "|" .. cueName .. "|\n|" .. execoption .. "|\n|Cue: " .. i .. "|\n|Fadetime: " .. fadetime .. "|"
                    reaper.GetSetMediaItemInfo_String(mediaItem, "P_NOTES", name, true)
                end
                for w in string.gmatch(name, "|([^|]+)|") do
                    table.insert(namePart[i], w)
                end
                -- Sicherstellen, dass alle Felder existieren
                namePart[i][1] = namePart[i][1] or ("Cue - " .. i)
                namePart[i][2] = namePart[i][2] or (loadedtracks[selTrack].execoption or "Cue List")
                namePart[i][3] = namePart[i][3] or ("Cue: " .. i)
                namePart[i][4] = namePart[i][4] or ("Fadetime: " .. (loadedtracks[selTrack].cue[itemGUID[i]] and loadedtracks[selTrack].cue[itemGUID[i]].fadetime or "2"))
                -- Robust: Nur wenn Feld existiert, dann match
                if namePart[i][3] and type(namePart[i][3]) == "string" then
                    oldCueNr[i] = tonumber(string.match(namePart[i][3], "Cue: (%d+)"))
                else
                    oldCueNr[i] = i
                end
                if selectedOption == 'Cue List' then
                    local newName = '|' ..namePart[i][1] ..'|\n|' ..namePart[i][2] .. '|\n|Cue: ' .. i .. '|\n|'..namePart[i][4].. '|'
                    reaper.GetSetMediaItemInfo_String(mediaItem, "P_NOTES", newName, true)
                    reaper.ThemeLayout_RefreshAll()                    
                else
                    local newName = '|' ..namePart[i][1] ..'|\n|' ..namePart[i][2] .. '|\n|Press: ' .. i .. '|\n|'..namePart[i][4].. '|'
                    reaper.GetSetMediaItemInfo_String(mediaItem, "P_NOTES", newName, true)
                    reaper.ThemeLayout_RefreshAll()                    
                end
                ----UPDATE CONSOLE SETUP 
                if liveupdatebox == true then
                    if selectedOption == 'Cue List' then 
                        if i ~= oldCueNr[i] then
                            local nextCue = i + 1
                            local cmd = 'Move Sequence '..seqID..' Cue "'..namePart[i][1]..'" at Sequence '..seqID..' Cue '..i
                            if MAmode == 'Mode 2' then
                                sendTelnet(cmd)
                            elseif MAmode == 'Mode 3' then
                                sendOSC(hostIP, consolePort, cmd)
                            end
                            if sendedData[selTrack] == nil then
                                SetupSendedDataTrack(selTrack)
                            end
                            if sendedData[selTrack].cue == nil then
                                sendedData[selTrack].cue = {}
                            end
                            if sendedData[selTrack].cue[itemGUID[i]] == nil then
                                SetupSendedDataItem(selTrack, itemGUID[i])
                            end
                            sendedData[selTrack].cue[itemGUID[i]].TCid = 'empty'
                            sendedData[selTrack].cue[itemGUID[i]].TCname = 'empty'
                            sendedData[selTrack].cue[itemGUID[i]].itemStart = 'empty'
                            sendedData[selTrack].execoption = 'empty'
                            sendedData[selTrack].cue[itemGUID[i]].token = 'empty'
                        end                
                    end
                end
            end
        end
    end
    pendingLiveUpdate = true
end
function moveItem(time)
    --reaper.ShowConsoleMsg('\nMOVE STARTED')
    local timeOffset = time
    local eventStartOld = {}
    local timedifference = {}
    local selectedItems = {}
    local newStartTime = {}
    local startcount = 1
    local numSelectedItems = reaper.CountSelectedMediaItems(0)
    for i = 0, numSelectedItems - 1 do
        local selectedItem = reaper.GetSelectedMediaItem(0, i)
        table.insert(selectedItems, selectedItem)
        eventStartOld[i] = reaper.GetMediaItemInfo_Value(selectedItem, "D_POSITION")
        if i > 0 then
            timedifference[i] = eventStartOld[i] - eventStartOld[0]
            --reaper.ShowConsoleMsg('\nStart: '..eventStartOld[i])
            --reaper.ShowConsoleMsg('\ndifference: '..timedifference[i])
        else
            timedifference[i] = 0
            --reaper.ShowConsoleMsg('\n'..i)
            --reaper.ShowConsoleMsg('\nStart: '..eventStartOld[i])
            --reaper.ShowConsoleMsg('\ndifference: '..timedifference[i])
        end
        newStartTime[startcount] = timeOffset + timedifference[i]
        startcount = startcount + 1
        --[[ reaper.ShowConsoleMsg('\nI: '..i..' GUID: '..itemGUID)
        reaper.ShowConsoleMsg('\nI: '..i..' timedifference: '..timedifference[i])
        reaper.ShowConsoleMsg('\nI: '..i..' newStart: '..newStartTime) ]]
    end
    for i = 1, #selectedItems, 1 do
        local itemGUID = reaper.BR_GetMediaItemGUID(selectedItems[i])
        --reaper.ShowConsoleMsg('\nJ: '..i..' GUID: '..itemGUID)
        reaper.SetMediaItemInfo_Value(selectedItems[i], "D_POSITION", newStartTime[i]) 
    
    end
   

   pendingLiveUpdate = true      
end
function setCursorToItem (itemPos)
    reaper.SetEditCurPos( itemPos, true, true )
end
function createCueInSelectedTrack()
    -- Hole die GUID des ausgewählten Tracks
    local selectedTrackGUID = readTrackGUID('selected')
    if not selectedTrackGUID then
        reaper.ShowMessageBox("No track selected. Please select a track.", "Error", 0)
        return
    end

    -- Füge ein Cue im ausgewählten Track hinzu
    addItem(selectedTrackGUID)
end
---------------SEND OSC --------------------------------------------------------------------
function setOSCcommand()
    getTrackContent()
    local cueGUID = {}
    local cueAmmount = {}
    local usedTrackGUID = readTrackGUID('used')
    local longestTime = getLongestTrackTime() + 10
    local buttonOption = ''
    local OscCommands = {
      sequence = {
        storeSeqCmd = {},
        labelSeqCmd = {},
        assignSeqCmd = {},
      },
      cue = {
        storeCueCmd = {},
        labelCueCmd = {},
        fadeCueCmd = {},
        holdCueCmd = {},
      },
      timecode = {
        tcStoreCmd = 'Store TC ' .. tcID,
        tcSetCmd = 'Set TC ' .. tcID .. ' Property "duration" ' .. longestTime,
        tcStoreTrackGroup = 'Store TC ' .. tcID .. '.1' .. ' "TC HELPER"',
        tcStoreCueCmd = {},
        tcTimeCueCmd = {},
        tcButtonCueCmd = {},
        tcDestinationCueCmd = {},
        tcStoreTrackCmd = {},
        tcAssignSeqCmd = {},
        tcStoreTimeRangeCmd = {},
        tcStoreSubTrackCmd = {},
        tcStatusONCueCmd = {},
        tcOffStatusCueCmd = {},
        tcOffStoreCueCmd = {},
        tcOffTimeCueCmd = {},
        tcOffButtonCueCmd = {},
        tcOffDestinationCueCmd = {},
        }
    }
    ------SEQ COMMAND---------
    for i = 1, #usedTrackGUID do
        cueGUID[i] = readItemGUID(usedTrackGUID[i])
        OscCommands.cue.storeCueCmd[i] = {}
        OscCommands.cue.labelCueCmd[i] = {}
        OscCommands.cue.fadeCueCmd[i] = {}
        OscCommands.cue.holdCueCmd[i] = {}
        
        
        OscCommands.timecode.tcStoreCueCmd[i] = {}
        OscCommands.timecode.tcTimeCueCmd[i] = {}
        OscCommands.timecode.tcButtonCueCmd[i] = {}
        OscCommands.timecode.tcDestinationCueCmd[i] = {}
        OscCommands.timecode.tcStatusONCueCmd[i] = {}
        
        OscCommands.timecode.tcOffStoreCueCmd[i] = {}
        OscCommands.timecode.tcOffTimeCueCmd[i] = {}
        OscCommands.timecode.tcOffButtonCueCmd[i] = {}
        OscCommands.timecode.tcOffDestinationCueCmd[i] = {}
        OscCommands.timecode.tcOffStatusCueCmd[i] = {}


        if loadedtracks[usedTrackGUID[i]].execoption == 'Cue List' then
            buttonOption = 'goto'
        elseif loadedtracks[usedTrackGUID[i]].execoption == 'Flash Button' then
            buttonOption = 'flash'
        elseif loadedtracks[usedTrackGUID[i]].execoption == 'Temp Button' then
            buttonOption = 'temp'
        elseif loadedtracks[usedTrackGUID[i]].execoption == 'Top Button' then
            buttonOption = 'top'
        elseif loadedtracks[usedTrackGUID[i]].execoption == 'Top&Release Button' then
            buttonOption = 'top'
        end

        OscCommands.sequence.storeSeqCmd[i] = 'Store Sequence ' ..loadedtracks[usedTrackGUID[i]].seqID
        OscCommands.sequence.labelSeqCmd[i] = 'Label Sequence ' ..loadedtracks[usedTrackGUID[i]].seqID .. ' "' .. loadedtracks[usedTrackGUID[i]].name .. '"'
        local trackID = reaper.BR_GetMediaTrackByGUID(0, usedTrackGUID[i])
        cueAmmount[i] = reaper.CountTrackMediaItems(trackID)
        -----TC TRACK COMMANDS
        OscCommands.timecode.tcStoreTrackCmd[i] = 'Store TC ' .. tcID .. '.1.' .. i
        OscCommands.timecode.tcAssignSeqCmd[i] = 'Assign Sequence ' ..loadedtracks[usedTrackGUID[i]].seqID .. ' at TC ' .. tcID .. '.1.' .. i
        OscCommands.timecode.tcStoreTimeRangeCmd[i] = 'Store TC ' .. tcID .. '.1.' .. i .. '.1'
        OscCommands.timecode.tcStoreSubTrackCmd[i] = 'Store Type "CmdSubTrack" Timecode ' .. tcID .. '.1.' .. i .. '.1.1'
        ------CUE COMMAND---------
        if loadedtracks[usedTrackGUID[i]].execoption == 'Cue List' then ------------------COMMANDS WENN TRACK CUELIST IST
            --reaper.ShowConsoleMsg('\n'..loadedtracks[usedTrackGUID[i]].execoption)
            for j = 1, cueAmmount[i] do
                OscCommands.cue.storeCueCmd[i][j] =              'Store Seq '  ..loadedtracks[usedTrackGUID[i]].seqID..'   Cue ' ..loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].cuenr .. ' /o'
                OscCommands.cue.labelCueCmd[i][j] =              'Label Seq '  ..loadedtracks[usedTrackGUID[i]].seqID ..'  Cue ' ..loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].cuenr ..' "'           ..loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].name .. '"/o'
                OscCommands.cue.fadeCueCmd[i][j] =               'Set Seq '    ..loadedtracks[usedTrackGUID[i]].seqID ..'  Cue ' ..loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].cuenr ..' CueFade '    ..loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].fadetime
                OscCommands.timecode.tcStoreCueCmd[i][j] =       'Store TC '   ..tcID ..'.1.'.. i .. '.1.1.'  ..loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].cuenr
                OscCommands.timecode.tcTimeCueCmd[i][j] =        'Set TC '     ..tcID ..'.1.' ..i ..'.1.1.'   ..loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].cuenr ..' Property "time" '               ..loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].itemStart
                OscCommands.timecode.tcButtonCueCmd[i][j] =      'Set TC '     ..tcID ..'.1.' ..i .. '.1.1.'  ..loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].cuenr ..' Property "token" "'             ..buttonOption .. '"'
                OscCommands.timecode.tcDestinationCueCmd[i][j] = 'Set TC '    ..tcID ..'.1.' ..i .. '.1.1.'   ..j ..' Property "cuedestination" "ShowData.DataPools.'..datapoolName..'.Sequences.'..loadedtracks[usedTrackGUID[i]].seqID..'.'..loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].name..'"'
                --reaper.ShowConsoleMsg('\ni: '..i..' j: '..j..' Cmd: '..OscCommands.timecode.tcButtonCueCmd[i][j])
            end

        elseif loadedtracks[usedTrackGUID[i]].execoption == 'Flash Button' or 'Temp Button' then
          -------------------------------------------------------------------------------COMMANDS WENN TRACK NICHT CUELIST IST
            local oncount = 1
            local offcount = 2
            --reaper.ShowConsoleMsg('\ni: '..i)
            for j = 1, cueAmmount[i], 1 do
                --local releaseBtnTime = loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].itemEnd - loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].fadetime
                local releaseBtnTime = loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].itemEnd
                OscCommands.cue.storeCueCmd[i][j] =              'Store Seq ' ..loadedtracks[usedTrackGUID[i]].seqID.. ' Cue 1  /m'
                OscCommands.cue.labelCueCmd[i][j] =              'Label Seq ' ..loadedtracks[usedTrackGUID[i]].seqID ..' Cue 1 "'           ..loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].name .. '"/o'
                OscCommands.cue.fadeCueCmd[i][j] =               'Set Seq '   ..loadedtracks[usedTrackGUID[i]].seqID ..' Cue 1 CueFade '    ..loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].fadetime
                OscCommands.timecode.tcStoreCueCmd[i][j] =       'Store TC '  ..tcID ..'.1.'.. i .. '.1.1.'   ..oncount
                OscCommands.timecode.tcTimeCueCmd[i][j] =        'Set TC '    ..tcID ..'.1.' ..i .. '.1.1.'   ..oncount ..' Property "time" '             ..loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].itemStart
                OscCommands.timecode.tcButtonCueCmd[i][j] =      'Set TC '    ..tcID ..'.1.' ..i .. '.1.1.'   ..oncount ..' Property "token" "'           ..buttonOption .. '"'
                OscCommands.timecode.tcStatusONCueCmd[i][j] =      'Set TC '    ..tcID ..'.1.'..i ..'.1.1.' ..oncount ..' Property "Status" "On"'
                OscCommands.timecode.tcDestinationCueCmd[i][j] = 'Set TC '    ..tcID ..'.1.' ..i .. '.1.1.'   ..oncount ..' Property "cuedestination" "ShowData.DataPools.Default.Sequences.'..loadedtracks[usedTrackGUID[i]].seqID..'.'..loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].name..'"'   
                
                OscCommands.timecode.tcOffStoreCueCmd[i][j] =       'Store TC '  ..tcID ..'.1.'.. i .. '.1.1.'   ..offcount
                OscCommands.timecode.tcOffTimeCueCmd[i][j] =        'Set TC '    ..tcID ..'.1.' ..i .. '.1.1.'   ..offcount ..' Property "time" '             ..releaseBtnTime
                OscCommands.timecode.tcOffButtonCueCmd[i][j] =      'Set TC '    ..tcID ..'.1.' ..i .. '.1.1.'   ..offcount ..' Property "token" "'           ..buttonOption .. '"'
                OscCommands.timecode.tcOffStatusCueCmd[i][j] =      'Set TC '    ..tcID ..'.1.'..i ..'.1.1.' ..offcount ..' Property "status" "Off"'
                OscCommands.timecode.tcOffDestinationCueCmd[i][j] = 'Set TC '    ..tcID ..'.1.' ..i .. '.1.1.'   ..offcount ..' Property "cuedestination" "ShowData.DataPools.'..datapoolName..'.Sequences.'..loadedtracks[usedTrackGUID[i]].seqID..'.'..loadedtracks[usedTrackGUID[i]].cue[cueGUID[i][j]].name..'"'   
                --reaper.ShowConsoleMsg('\nj: '..j)
                --reaper.ShowConsoleMsg('\noffcount: '..offcount)
                --reaper.ShowConsoleMsg('\ni: '..i..' j: '..j..' Cmd: '..OscCommands.timecode.tcStatusONCueCmd[i][j])
                oncount = oncount + 2
                offcount = offcount + 2
            end
        end    
    end
    getTrackContent()
    return OscCommands
end
function checkSendedData()
    --reaper.ShowConsoleMsg('\nCHECK SENDED DATA')
    getTrackContent()
    local checkData = {}
    checkData.track = {}
    checkData.item = {}
    
    local usedTracks = readTrackGUID('used')
    for i = 1, #usedTracks, 1 do

        local itemGuid = readItemGUID(usedTracks[i])
        local trackID = reaper.BR_GetMediaTrackByGUID(0, usedTracks[i])
        local itemAmmount = reaper.CountTrackMediaItems(trackID)
        --reaper.ShowConsoleMsg('\nNew Item Ammount: '..itemAmmount)
        --reaper.ShowConsoleMsg('\nold Item Ammount: '..sendedData[usedTracks[i]].itemAmmount)
        ----------TRACK VERGLEICH 
        if sendedData[usedTracks[i]] ~= nil then
            checkData.track[usedTracks[i]] = {}
            if sendedData[usedTracks[i]].name ~= loadedtracks[usedTracks[i]].name then
                checkData.track[usedTracks[i]].name = true
            else
                checkData.track[usedTracks[i]].name = false
            end

            if sendedData[usedTracks[i]].id ~= loadedtracks[usedTracks[i]].id or nil then
                checkData.track[usedTracks[i]].id = true
                --reaper.ShowConsoleMsloadedData.id = true')
            else
                checkData.track[usedTracks[i]].id = false
                --reaper.ShowConsoleMsg('\nsendedData.id = false')
            end
        
            if sendedData[usedTracks[i]].execoption ~= loadedtracks[usedTracks[i]].execoption then
                --reaper.ShowConsoleMsg('\nNew Data: '..loadedtracks[usedTracks[i]].execoption)
                checkData.track[usedTracks[i]].execoption = true
            else
                checkData.track[usedTracks[i]].execoption = false
            end
            if sendedData[usedTracks[i]].seqID ~= loadedtracks[usedTracks[i]].seqID then
                --reaper.ShowConsoleMsg('\nNew Data: '..loadedtracks[usedTracks[i]].seqID)
                checkData.track[usedTracks[i]].seqID = true
            else
                checkData.track[usedTracks[i]].seqID = false
            end
        
            if sendedData[usedTracks[i]].pageID ~= loadedtracks[usedTracks[i]].pageID then
                --reaper.ShowConsoleMsg('\nNew Data: '..loadedtracks[usedTracks[i]].pageID)
                checkData.track[usedTracks[i]].pageID = true
            else
                checkData.track[usedTracks[i]].pageID = false
            end
            if sendedData[usedTracks[i]].execID ~= loadedtracks[usedTracks[i]].execID then
                --reaper.ShowConsoleMsg('\nNew Data: '..loadedtracks[usedTracks[i]].execID)
                checkData.track[usedTracks[i]].execID = true
            else
                checkData.track[usedTracks[i]].execID = false
            end
            if sendedData[usedTracks[i]].trackNr ~= loadedtracks[usedTracks[i]].trackNr then
                --reaper.ShowConsoleMsg('\nNew Data: '..loadedtracks[usedTracks[i]].trackNr)
                checkData.track[usedTracks[i]].trackNr = true
            else
                checkData.track[usedTracks[i]].trackNr = false
            end
            if sendedData[usedTracks[i]].tcID ~= loadedtracks[usedTracks[i]].tcID then
                --reaper.ShowConsoleMsg('\nNew Data: '..loadedtracks[usedTracks[i]].tcID)
                checkData.track[usedTracks[i]].tcID = true
            else
                checkData.track[usedTracks[i]].tcID = false
            end
        end

        --------------ITEM VERGLEICH
        for j = 1, itemAmmount do
            if sendedData[usedTracks[i]].cue[itemGuid[j]] ~= nil and itemAmmount > 0 then
                --reaper.ShowConsoleMsg(itemAmmount)
                checkData.item[itemGuid[j]] = {}
                if sendedData[usedTracks[i]].cue[itemGuid[j]].name ~= loadedtracks[usedTracks[i]].cue[itemGuid[j]].name then
                    -- reaper.ShowConsoleMsg('\nsended Name: '..sendedData[usedTracks[i]].cue[itemGuid[j]].name)                    
                    -- reaper.ShowConsoleMsg('\nloaded Name: '..loadedtracks[usedTracks[i]].cue[itemGuid[j]].name)                    
                    checkData.item[itemGuid[j]].name = true
                else
                    checkData.item[itemGuid[j]].name = false                   
                end
                if sendedData[usedTracks[i]].cue[itemGuid[j]].id ~= loadedtracks[usedTracks[i]].cue[itemGuid[j]].id then
                    --reaper.ShowConsoleMsg('\nNew Data: '..loadedtracks[usedTracks[i]].cue[itemGuid[j]].id)
                    checkData.item[itemGuid[j]].id = true
                    --reaper.ShowConsoleMsg('\nid:'..j..' true')
                else
                    checkData.item[itemGuid[j]].id = false
                    --reaper.ShowConsoleMsloadedData: '..loadedtracks[usedTracks[i]].cue[itemGuid[j]].id)
                    --reaper.ShowConsoleMsg('\nid:'..j..' false')
                end
                if sendedData[usedTracks[i]].cue[itemGuid[j]].cuenr ~= loadedtracks[usedTracks[i]].cue[itemGuid[j]].cuenr then
                    --reaper.ShowConsoleMsg('\nNew Data: '..loadedtracks[usedTracks[i]].cue[itemGuid[j]].cuenr)
                    checkData.item[itemGuid[j]].cuenr = true
                else
                    checkData.item[itemGuid[j]].cuenr = false
                end
                if sendedData[usedTracks[i]].cue[itemGuid[j]].fadetime ~= loadedtracks[usedTracks[i]].cue[itemGuid[j]].fadetime then
                    --reaper.ShowConsoleMsg('\nNew Data: '..loadedtracks[usedTracks[i]].cue[itemGuid[j]].fadetime)
                    checkData.item[itemGuid[j]].fadetime = true
                else
                    checkData.item[itemGuid[j]].fadetime = false
                end
                if sendedData[usedTracks[i]].cue[itemGuid[j]].holdtime ~= loadedtracks[usedTracks[i]].cue[itemGuid[j]].holdtime then
                    --reaper.ShowConsoleMsg('\nNew Data: '..loadedtracks[usedTracks[i]].cue[itemGuid[j]].holdtime)
                    checkData.item[itemGuid[j]].holdtime = true
                else
                    checkData.item[itemGuid[j]].holdtime = false
                end
                if sendedData[usedTracks[i]].cue[itemGuid[j]].itemStart ~= loadedtracks[usedTracks[i]].cue[itemGuid[j]].itemStart then
                    --reaper.ShowConsoleMsg('\nNew Data: '..loadedtracks[usedTracks[i]].cue[itemGuid[j]].itemStart)
                    checkData.item[itemGuid[j]].itemStart = true
                else
                    checkData.item[itemGuid[j]].itemStart = false
                end
                if sendedData[usedTracks[i]].cue[itemGuid[j]].itemEnd ~= loadedtracks[usedTracks[i]].cue[itemGuid[j]].itemEnd then
                    --reaper.ShowConsoleMsg('\nNew Data: '..loadedtracks[usedTracks[i]].cue[itemGuid[j]].itemEnd)
                    checkData.item[itemGuid[j]].itemEnd = true
                else
                    checkData.item[itemGuid[j]].itemEnd = false
                end
                
                if sendedData[usedTracks[i]].itemAmmount ~= loadedtracks[usedTracks[i]].itemAmmount then
                    checkData.item[itemGuid[j]].itemStore = true
                else
                    checkData.item[itemGuid[j]].itemStore = false
                end
                if sendedData[usedTracks[i]].cue[itemGuid[j]].TCid ~= loadedtracks[usedTracks[i]].cue[itemGuid[j]].TCid then
                    checkData.item[itemGuid[j]].TCid = true
                    -- reaper.ShowConsoleMsg('\nsended TC ID: '..sendedData[usedTracks[i]].cue[itemGuid[j]].TCid)
                    -- reaper.ShowConsoleMsg('\nloaded TC ID: '..loadedtracks[usedTracks[i]].cue[itemGuid[j]].TCid)
                    -- reaper.ShowConsoleMsg('\nTC ID: TRUE')

                else
                    checkData.item[itemGuid[j]].TCid = false
                    -- reaper.ShowConsoleMsg('\n TC ID: FALSE')
                end
                if sendedData[usedTracks[i]].cue[itemGuid[j]].TCname ~= loadedtracks[usedTracks[i]].cue[itemGuid[j]].TCname then
                    checkData.item[itemGuid[j]].TCname = true
                    --reaper.ShowConsoleMsg('\n TC NAME: TRUE')
                else
                    checkData.item[itemGuid[j]].TCname = false
                   --reaper.ShowConsoleMsg('\n TC NAME: FALSE')
                end
                if sendedData[usedTracks[i]].cue[itemGuid[j]].token ~= loadedtracks[usedTracks[i]].cue[itemGuid[j]].token then
                    checkData.item[itemGuid[j]].token = true
                    --reaper.ShowConsoleMsg('\n TC TOKEN: TRUE')
                else
                    checkData.item[itemGuid[j]].token = false
                   --reaper.ShowConsoleMsg('\n TC TOKEN: FALSE')
                end
                -- SPEZIALFALL: Temp/Flash Button → Name des ersten Cues als Track-Flag
                if j == 1 and (
                    loadedtracks[usedTracks[i]].execoption == "Temp Button" or
                    loadedtracks[usedTracks[i]].execoption == "Flash Button"
                ) then
                    -- Prüfe, ob sich der Name des ersten Cues geändert hat
                    if sendedData[usedTracks[i]].cue[itemGuid[j]].name ~= loadedtracks[usedTracks[i]].cue[itemGuid[j]].name then
                        -- Setze ein Flag am Track, damit sendToConsole das Label sendet
                        checkData.track[usedTracks[i]].tempCueNameChanged = true
                    else
                        checkData.track[usedTracks[i]].tempCueNameChanged = false
                    end
                end
            else
                SetupSendedDataItem(usedTracks[i],itemGuid[j])
            end 
        end
    end
    return checkData
end
function sendToConsole(hostIP, consolePort, OscCommands)
    local seqCheck = checkSeqInfo()
    local usedTracks = readTrackGUID('used')
    local sendedCheck = checkSendedData()
    local itemAmmount = {}
    if seqCheck == false then
        for i = 1, #usedTracks, 1 do
            local trackID = reaper.BR_GetMediaTrackByGUID(0, usedTracks[i])
            itemAmmount[i] = reaper.CountTrackMediaItems(trackID)
        end
      
        for i = 1, #usedTracks, 1 do -------------------STORE SEQ COMMANDS   
            local itemGuid = readItemGUID(usedTracks[i])            
            if sendedCheck.track[usedTracks[i]].id == true  then
                sendOSC(hostIP, consolePort, OscCommands.sequence.storeSeqCmd[i])
                sendedData[usedTracks[i]].id = copy3(loadedtracks[usedTracks[i]].id)

                --reaper.ShowConsoleMsg('\n'..OscCommands.sequence.storeSeqCmd[i])
            end
            if sendedCheck.track[usedTracks[i]].name == true  then
                sendOSC(hostIP, consolePort, OscCommands.sequence.labelSeqCmd[i])
                sendedData[usedTracks[i]].name = copy3(loadedtracks[usedTracks[i]].name)

                --reaper.ShowConsoleMsg('\n'..OscCommands.sequence.labelSeqCmd[i])
            end        
            for j = 1, itemAmmount[i] do -------------------COMMANDS DIE MIT JEDEM CUE AUSGEFÜHRT WERDEN
              -----STORE SEQUENZEN
                if itemGuid[j] ~= nil then 
                    if sendedCheck.item[itemGuid[j]] ~= nil then                        
                        if loadedtracks[usedTracks[i]].execoption == 'Cue List' then
                            -----------CUE LIST SEQUENZEN
                            if sendedCheck.item[itemGuid[j]].id == true then 
                                sendOSC(hostIP, consolePort, OscCommands.cue.storeCueCmd[i][j])
                                sendedData[usedTracks[i]].cue[itemGuid[j]].id = copy3(loadedtracks[usedTracks[i]].cue[itemGuid[j]].id)    
                                --reaper.ShowConsoleMsg('\n'..OscCommands.cue.storeCueCmd[i][j])
                            end
                            if sendedCheck.item[itemGuid[j]].name == true then 
                                sendOSC(hostIP, consolePort, OscCommands.cue.labelCueCmd[i][j])
                                sendedData[usedTracks[i]].cue[itemGuid[j]].name = copy3(loadedtracks[usedTracks[i]].cue[itemGuid[j]].name)
                                --reaper.ShowConsoleMsg('\n'..OscCommands.cue.labelCueCmd[i][j])
                            end
                            if sendedCheck.item[itemGuid[j]].fadetime == true then 
                                sendOSC(hostIP, consolePort, OscCommands.cue.fadeCueCmd[i][j])
                                sendedData[usedTracks[i]].cue[itemGuid[j]].fadetime = copy3(loadedtracks[usedTracks[i]].cue[itemGuid[j]].fadetime)
                            end                                                                                      
                        else    ----TEMP&FLASH SEQUENZEN
                            if sendedCheck.track[usedTracks[i]].tempCueNameChanged == true then
                                sendOSC(hostIP, consolePort, OscCommands.cue.labelCueCmd[i][1])
                                -- Update sendedData, damit die Änderung erkannt wird
                                local firstItemGuid = itemGuid[1]
                                sendedData[usedTracks[i]].cue[firstItemGuid].name = copy3(loadedtracks[usedTracks[i]].cue[firstItemGuid].name)
                            end
                    
                            if sendedData[usedTracks[i]].tempNameSended == false then 
                                sendOSC(hostIP, consolePort, OscCommands.cue.labelCueCmd[i][1])
                                sendedData[usedTracks[i]].tempNameSended = true
                            end
                            if sendedData[usedTracks[i]].tempFadeSended == false then 
                                sendOSC(hostIP, consolePort, OscCommands.cue.fadeCueCmd[i][1])
                                sendedData[usedTracks[i]].tempFadeSended = true
                            end                        
                        end
                    end
                end      
            end
        end

        --------TIMECODE SHOW SETUP------------------------------------
        -------COMMANDS DIE TC SHOW SPEZIFISCH SIND UND NUR EINMAL AUSGEFÜHRT WERDEN-------------------
        if sendedData.TCsendedShow == false then
            sendOSC(hostIP, consolePort, OscCommands.timecode.tcStoreCmd)
            sendOSC(hostIP, consolePort, OscCommands.timecode.tcSetCmd)
            sendOSC(hostIP, consolePort, OscCommands.timecode.tcStoreTrackGroup)
            sendedData.TCsendedShow = true
        end
    
        for i = 1, #usedTracks, 1 do --------------------------TIMECODE COMMANDS DIE TRACK SPEZIFISCH SIND
            local itemGuid = readItemGUID(usedTracks[i])
            if sendedData[usedTracks[i]].TCsendedTrack == false  then
                sendOSC(hostIP, consolePort, OscCommands.timecode.tcStoreTrackCmd[i])
                sendOSC(hostIP, consolePort, OscCommands.timecode.tcAssignSeqCmd[i])
                sendOSC(hostIP, consolePort, OscCommands.timecode.tcStoreSubTrackCmd[i])
                sendOSC(hostIP, consolePort, OscCommands.timecode.tcStoreTimeRangeCmd[i])
                --reaper.ShowConsoleMsg('\n'..OscCommands.timecode.tcStoreTrackCmd[i])
                sendedData[usedTracks[i]].TCsendedTrack = true
                
            end
            
            for j = 1, itemAmmount[i], 1 do ---------------------------TIMECODE COMMANDS DIE EVENT SPEZIEFISCH SIND
                if OscCommands.timecode.tcStoreCueCmd[i][j] or OscCommands.timecode.tcStatusONCueCmd[i][j] ~= nil then
                    if sendedCheck.item[itemGuid[j]] ~= nil then                        
                        if loadedtracks[usedTracks[i]].execoption == 'Cue List' then
                            if sendedCheck.item[itemGuid[j]].TCid == true then 
                                sendOSC(hostIP, consolePort, OscCommands.timecode.tcStoreCueCmd[i][j])---HIER WIRD EIN NEUES TC EVENT GESCHICKT
                                sendOSC(hostIP, consolePort, OscCommands.timecode.tcSetCmd)
                                --reaper.ShowConsoleMsg('\n-'..OscCommands.timecode.tcStoreCueCmd[i][j])
                                sendedData[usedTracks[i]].cue[itemGuid[j]].TCid = copy3(loadedtracks[usedTracks[i]].cue[itemGuid[j]].TCid)

                            end
                            if sendedCheck.item[itemGuid[j]].itemStart == true then 
                                sendOSC(hostIP, consolePort, OscCommands.timecode.tcTimeCueCmd[i][j])--HIER WIRD DEM TC EVENT EINE ZEIT GEGEBEN 
                                --reaper.ShowConsoleMsg('\n-'..OscCommands.timecode.tcTimeCueCmd[i][j])
                                sendedData[usedTracks[i]].cue[itemGuid[j]].itemStart = copy3(loadedtracks[usedTracks[i]].cue[itemGuid[j]].itemStart)
                            end
                            if sendedCheck.item[itemGuid[j]].TCname == true then 
                                sendOSC(hostIP, consolePort, OscCommands.timecode.tcDestinationCueCmd[i][j])--HIER WIRD DEM TC EVENT EIN CUE ZUGEWIESEN
                                --reaper.ShowConsoleMsg('\n-'..OscCommands.timecode.tcDestinationCueCmd[i][j])
                                
                                sendedData[usedTracks[i]].cue[itemGuid[j]].TCname = copy3(loadedtracks[usedTracks[i]].cue[itemGuid[j]].TCname)
                            end                
                            if sendedCheck.item[itemGuid[j]].token == true then 
                                sendOSC(hostIP, consolePort, OscCommands.timecode.tcButtonCueCmd[i][j])--HIER WIRD DEM TC EVENT EINE FUNKTION GEGEBEN
                                --reaper.ShowConsoleMsg('\n-'..OscCommands.timecode.tcButtonCueCmd[i][j])
                                
                                sendedData[usedTracks[i]].cue[itemGuid[j]].token = copy3(loadedtracks[usedTracks[i]].cue[itemGuid[j]].token)
                            end                
                            
                        else
                            --reaper.ShowConsoleMsg('\nEXEC OPTION: '..loadedtracks[usedTracks[i]].execoption)
                            if sendedCheck.item[itemGuid[j]].TCid == true then 
                                sendOSC(hostIP, consolePort, OscCommands.timecode.tcStoreCueCmd[i][j])---HIER WIRD EIN NEUES ON TC EVENT GESCHICKT
                                sendOSC(hostIP, consolePort, OscCommands.timecode.tcButtonCueCmd[i][j])--HIER WIRD DEM ON TC EVENT EINE FUNKTION GEGEBEN
                                
                                sendOSC(hostIP, consolePort, OscCommands.timecode.tcOffStoreCueCmd[i][j])--HIER WIRD EIN NEUES OFF TC EVENT GESCHICKT
                                sendOSC(hostIP, consolePort, OscCommands.timecode.tcOffButtonCueCmd[i][j])--HIER WIRD DEM OFF TC EVENT EINE FUNKTION GEGEBEN   
                                sendOSC(hostIP, consolePort, OscCommands.timecode.tcOffStatusCueCmd[i][j])--OFF TOKEN FÜR RELEASE CUE
                                sendOSC(hostIP, consolePort, OscCommands.timecode.tcSetCmd)
                                sendedData[usedTracks[i]].cue[itemGuid[j]].TCid = copy3(loadedtracks[usedTracks[i]].cue[itemGuid[j]].TCid)
                            end
                            
                            
                            if sendedCheck.item[itemGuid[j]].itemStart == true then 
                                
                                sendOSC(hostIP, consolePort, OscCommands.timecode.tcTimeCueCmd[i][j])--HIER WIRD ON CUE TIME GEGEBEN
                                sendedData[usedTracks[i]].cue[itemGuid[j]].itemStart = copy3(loadedtracks[usedTracks[i]].cue[itemGuid[j]].itemStart)                                
                            end
                            
                            if sendedCheck.item[itemGuid[j]].itemEnd == true then
                                sendOSC(hostIP, consolePort, OscCommands.timecode.tcOffTimeCueCmd[i][j])
                                sendedData[usedTracks[i]].cue[itemGuid[j]].itemEnd = copy3(loadedtracks[usedTracks[i]].cue[itemGuid[j]].itemEnd)
                            end
                            if sendedCheck.item[itemGuid[j]].cuenr == true then                                 
                                sendOSC(hostIP, consolePort, OscCommands.timecode.tcOffButtonCueCmd[i][j])
                                --sendOSC(hostIP, consolePort, OscCommands.timecode.tcOffStatusCueCmd[i][j])--OFF TOKEN FÜR End CUE
                                sendedData[usedTracks[i]].cue[itemGuid[j]].cuenr = copy3(loadedtracks[usedTracks[i]].cue[itemGuid[j]].cuenr)
                            end                 
                            if sendedCheck.item[itemGuid[j]].TCname == true then 
                                sendOSC(hostIP, consolePort, OscCommands.timecode.tcDestinationCueCmd[i][j])--HIER WIRD DEM TC EVENT EIN CUE ZUGEWIESEN
                                sendOSC(hostIP, consolePort, OscCommands.timecode.tcOffDestinationCueCmd[i][j])--HIER WIRD DEM OFF TC EVENT EIN CUE ZUGEWIESEN
                                --reaper.ShowConsoleMsg('\n-'..OscCommands.timecode.tcDestinationCueCmd[i][j])
                                
                                sendedData[usedTracks[i]].cue[itemGuid[j]].TCname = copy3(loadedtracks[usedTracks[i]].cue[itemGuid[j]].TCname)
                            end                
                        end
                    end                
                end
            end
        end
    else
      reaper.ShowMessageBox('TC Helper\nDOUBLE NAME FOUND', 'Error', 0)
    end
    --sendedData = copy3(loadedtracks)
    --reaper.ShowConsoleMsg('\nEND OF SEND TO CONSOLE')
end
function sendOSC(hostIP, consolePort, cmd)
    local delay = 0.001

    sleep(delay)
    local msg = osc_encode('/' .. prefix .. '/cmd', 's', cmd)
    
    --local msg = '/reaper/cmd "Store Seq 1001"'
    
    -- Send message
    -- change here to the host an port you want to contact
    if hostIP ~= dummyIPstring then
        local host, port = hostIP, consolePort
        -- create a new UDP object
        local udp = assert(socket.udp())
        -- contact daytime host
        assert(udp:sendto(msg, host, port))
    else
        reaper.ShowMessageBox('\nPlease enter correct IP Adress', 'Error', 0)
    end
end
-----------------MA2 MODE-----------------------------------------------------------------------
-----------------WRITING SEQ XML-----------------------------------------------------------------------
function XMLwriting(object,script)
    local reaperPath = reaper.GetResourcePath()
    local xmlPath = reaperPath..'/Scripts/'..repositoryName
    getTrackContent()
    local dir = {}
    dir.temp = xmlPath
    local fn = {temp = 'temp_'..object..'.xml'}
    local file = {temp = dir.temp..fn.temp}
    local writefile = io.open(file.temp, 'w')
	writefile:write(script)
	writefile:close()
end
function setupSeqXml ()
    --consoleMSG('SEQ XML START')
    getTrackContent()
    local trackGUIDs = readTrackGUID('used')
    
    local seqNames = {}
    local itemGUIDs = {}
    local cueAmmount = 0
    local seqID = 'empty'
    --local cue = 'empty'
    local text = 'empty'
    text = [[
        
    <?xml version="1.0" encoding="utf-8"?>
    <?xml-stylesheet type="text/xsl" href="styles/sequ@html@default.xsl"?>
    <?xml-stylesheet type="text/xsl" href="styles/sequ@executorsheet.xsl" alternate="yes"?>
    <?xml-stylesheet type="text/xsl" href="styles/sequ@trackingsheet.xsl" alternate="yes"?>
    <MA xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.malighting.de/grandma2/xml/MA" xsi:schemaLocation="http://schemas.malighting.de/grandma2/xml/MA http://schemas.malighting.de/grandma2/xml/3.9.60/MA.xsd" major_vers="3" minor_vers="9" stream_vers="60">
    <Info datetime="2024-07-23T18:16:00" showfile="TC HELPER EXPORT" />
    ]]
    for i = 1, #trackGUIDs, 1 do
        seqNames[i] = loadedtracks[trackGUIDs[i]].name
        itemGUIDs = readItemGUID(trackGUIDs[i])
        cueAmmount = #itemGUIDs
        seqID = loadedtracks[trackGUIDs[i]].seqID
        
        local seqdef =
        [[<Sequ index="]]..seqID..[[" name="]]..seqNames[i]..[[" timecode_slot="255" forced_position_mode="0">
        <Cue xsi:nil="true" />
        ]]
        text = text..seqdef
        
        for j = 1, cueAmmount, 1 do
            local cueName = loadedtracks[trackGUIDs[i]].cue[itemGUIDs[j]].name
            local cueFade = loadedtracks[trackGUIDs[i]].cue[itemGUIDs[j]].fadetime
            local cue = [[
                <Cue index="]]..j..[[">
                <Number number="]]..j..[[" sub_number="0" />
                <CuePart index="0" name="]]..cueName..[[" basic_fade="]]..cueFade..[[">
                <CuePartPresetTiming>
                <PresetTiming />
                <PresetTiming />
                <PresetTiming />
                <PresetTiming />
                <PresetTiming />
                <PresetTiming />
                <PresetTiming />
                <PresetTiming />
                <PresetTiming />
                <PresetTiming />
                <PresetTiming />
                </CuePartPresetTiming>
                </CuePart>
                </Cue>
                ]]
                text = text..cue
            end
            text = text..[[
                </Sequ>
                </MA>
                
                
                
                
                ]]
                
            end
            --consoleMSG('SEQ XML END')
            return text
        end
function pushXML(object)
    local ip = hostIP
    local bash, system = defineBash()
    local reaperPath = reaper.GetResourcePath()
    local filepath = reaperPath..'/Scripts/'..repositoryName..'/temp_'..object..'.xml'
    local ftpUser = 'data'
    local ftpPw = 'data'
    local file = ("'%s'"):format(filepath)
    local upload = ('curl -T %s -u %s:%s ftp://%s'):format(file, ftpUser, ftpPw, ip)
    --consoleMSG(upload)
    if system == 'macOS' then
        local ret = reaper.ExecProcess(bash..upload,0)
        --consoleMSG(ret)
    elseif system == 'win' then
        reaper.ImGui_Text(ctx, 'Windows not supported yet')
    end
end
function sendTelnet(maCommand)
    consoleMSG('telnet Test START')
    local cmd = maCommand
    local user = userName
    local ip = hostIP
    local port = '30000'
    local bash, system = defineBash()   
    
    if system == 'macOS' then
        local telnet_string = ([['(echo Login "%s" && echo %s && sleep 1) | /opt/homebrew/bin/telnet %s %s']]):format(user, cmd, ip, port)
        ret = reaper.ExecProcess(bash .. telnet_string, 0)
        consoleMSG(ret)
        consoleMSG(telnet_string)
        consoleMSG('telnet Test END')
    elseif system == 'win' then
        reaper.ImGui_Text(ctx, 'Windows not supported yet')
        
    end
            
end
function importInShowfile(object,objectID)
    --consoleMSG('IMPORT IN SHOWFILE START')
    local importID = objectID
    local filename = 'temp_'..object..''
    local filepath = 'empty'
    if ma2Loopback == 'true' then
        filepath = 'C:/ProgrammData/MA Lighting Technologies/grandma'
    elseif ma2Loopback == 'false' then
        filepath = '/'
        
    end
    telnetCommand = ([[Import "%s" at %s %s /path=""%s""]]):format(filename, object, importID, filepath)
    sendTelnet(telnetCommand)
    --consoleMSG('IMPORT IN SHOWFILE END')
end
function sendToConsoleMA2(OscCommands)
    local seqCheck = checkSeqInfo()
    local usedTracks = readTrackGUID('used')
    local sendedCheck = checkSendedData()
    local itemAmmount = {}
    if seqCheck == false then
        for i = 1, #usedTracks, 1 do
            local trackID = reaper.BR_GetMediaTrackByGUID(0, usedTracks[i])
            itemAmmount[i] = reaper.CountTrackMediaItems(trackID)
        end
      
        for i = 1, #usedTracks, 1 do -------------------STORE SEQ COMMANDS   
            local itemGuid = readItemGUID(usedTracks[i])            
            if sendedCheck.track[usedTracks[i]].id == true  then
                sendTelnet(OscCommands.sequence.storeSeqCmd[i])
                sendedData[usedTracks[i]].id = copy3(loadedtracks[usedTracks[i]].id)

                --reaper.ShowConsoleMsg('\n'..OscCommands.sequence.storeSeqCmd[i])
            end
            if sendedCheck.track[usedTracks[i]].name == true  then
                sendTelnet(OscCommands.sequence.labelSeqCmd[i])
                sendedData[usedTracks[i]].name = copy3(loadedtracks[usedTracks[i]].name)

                --reaper.ShowConsoleMsg('\n'..OscCommands.sequence.labelSeqCmd[i])
            end        
            for j = 1, itemAmmount[i] do -------------------COMMANDS DIE MIT JEDEM CUE AUSGEFÜHRT WERDEN
              -----STORE SEQUENZEN
                if itemGuid[j] ~= nil then 
                    if sendedCheck.item[itemGuid[j]] ~= nil then                        
                        if loadedtracks[usedTracks[i]].execoption == 'Cue List' then
                            -----------CUE LIST SEQUENZEN
                            if sendedCheck.item[itemGuid[j]].id == true then 
                                sendTelnet(OscCommands.cue.storeCueCmd[i][j])
                                sendedData[usedTracks[i]].cue[itemGuid[j]].id = copy3(loadedtracks[usedTracks[i]].cue[itemGuid[j]].id)    
                                --reaper.ShowConsoleMsg('\n'..OscCommands.cue.storeCueCmd[i][j])
                            end
                            if sendedCheck.item[itemGuid[j]].name == true then 
                                sendTelnet(OscCommands.cue.labelCueCmd[i][j])
                                sendedData[usedTracks[i]].cue[itemGuid[j]].name = copy3(loadedtracks[usedTracks[i]].cue[itemGuid[j]].name)
                                --reaper.ShowConsoleMsg('\n'..OscCommands.cue.labelCueCmd[i][j])
                            end
                            if sendedCheck.item[itemGuid[j]].fadetime == true then 
                                sendTelnet(OscCommands.cue.fadeCueCmd[i][j])
                                sendedData[usedTracks[i]].cue[itemGuid[j]].fadetime = copy3(loadedtracks[usedTracks[i]].cue[itemGuid[j]].fadetime)
                            end                                                                                      
                        else    ----TEMP&FLASH SEQUENZEN
                            if sendedData[usedTracks[i]].tempCueSended == false then
                                sendTelnet(OscCommands.cue.storeCueCmd[i][1])
                                sendedData[usedTracks[i]].tempCueSended = true
                            end
                            if sendedData[usedTracks[i]].tempNameSended == false then 
                                sendTelnet(OscCommands.cue.labelCueCmd[i][1])
                                sendedData[usedTracks[i]].tempNameSended = true
                            end
                            if sendedData[usedTracks[i]].tempFadeSended == false then 
                                sendTelnet(OscCommands.cue.fadeCueCmd[i][1])
                                sendedData[usedTracks[i]].tempFadeSended = true
                            end                        
                        end
                    end
                end      
            end
        end

        
    else
      reaper.ShowMessageBox('TC Helper\nDOUBLE NAME FOUND', 'Error', 0)
    end
    --sendedData = copy3(loadedtracks)
    --reaper.ShowConsoleMsg('\nEND OF SEND TO CONSOLE')
end
-- local dock = -3
checkSWS()
InitiateSendedData()
getTrackContent()
checkSendedData()
defineMA3ModeOnFirstStrartup()
copyReaperTemplate()
initializeTrackShortcuts()
loadShortcuts()
loadGlobalShortcuts()
local xmlContent, code = fetchXML(page)
if xmlContent then
    
    newVersion = checkForNewVersion(version, xmlContent, false)
    --consoleMSG('xmlContent: '..xmlContent)
    --consoleMSG('code: '..code)
else
    -- Keine Internetverbindung, aber TCHelper startet trotzdem
    --reaper.ShowConsoleMsg("No internet connection. TCHelper will start without checking for updates.\n")
end
startup = true
-- Stellen Sie sicher, dass latestVersion definiert ist
local flags = reaper.ImGui_WindowFlags_MenuBar()   -- Add Menu bar and remove the rezise feature. 
local function loop()
    if addonCheck == true then
        renumberItems()
        checkAndRestoreNotes()
        --setIPAdress()
        --updateInputCueName()
        
        checkShortcuts() -- Überprüfe Tastendrücke

        -- Live Update: Änderungen nachholen, wenn aktiviert wird
        if liveupdatebox and not lastLiveUpdateState and pendingLiveUpdate then
            mergeDataOption()
            pendingLiveUpdate = false
        end

        -- Normales Live Update Verhalten
        if liveupdatebox == true then
            mergeDataOption()
            pendingLiveUpdate = false
        end

        lastLiveUpdateState = liveupdatebox

        --reaper.ShowConsoleMsg('\n'..inputCueName)
        --getTrackContent()
        snapCursorToSelection()
        cueCount = getItemCount()
        getCursorPosition()
        getSelectedOption()
        --liveTrackCount = readTrackGUID('used')

        reaper.ImGui_PushFont(ctx, sans_serif)
        --------------------------------------------------------------------------------------------------------
        --GUI COLOR STYLE----------------------------------------------------------------------------------------
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(),                      0xDCDCDCFF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextDisabled(),              0x808080FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(),                  0x333333FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(),                   0x42424200)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(),                   0x282828F0)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(),                    0x6E6E8080)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_BorderShadow(),              0x00000000)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),                   0x6D76768A)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(),            0x57575766)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(),             0x828282AB)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(),                   0x6D7676FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(),             0x6D7676FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgCollapsed(),          0x00000082)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_MenuBarBg(),                 0x333333FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(),               0x26262687)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(),             0x474747FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(),      0x575757FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(),       0x1DB287FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),                 0x1DB287FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrab(),                0x2C2B2BFF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrabActive(),          0x1DB287FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),                    0x4684739C)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),             0x478473FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),              0x1DB287FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),                    0x1DB2874F)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(),             0x1DB287CC)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),              0x1DB287FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(),                 0x1DB28780)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SeparatorHovered(),          0x1DB287C7)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SeparatorActive(),           0x1DB287FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(),                0x1DB28733)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(),         0x1DB287AB)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(),          0x1DB287F2)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabHovered(),                0x478473FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Tab(),                       0x2D4F47FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabSelected(),               0x478473FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabSelectedOverline(),       0x1DB287FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabDimmed(),                 0x111A26F8)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabDimmedSelected(),         0x23436CFF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabDimmedSelectedOverline(), 0x808080FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DockingPreview(),            0x1DB287B3)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DockingEmptyBg(),            0x333333FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotLines(),                 0x9C9C9CFF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotLinesHovered(),          0xFF6E59FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotHistogram(),             0x223F37FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotHistogramHovered(),      0x1DB287FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableHeaderBg(),             0x303033FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableBorderStrong(),         0x4F4F59FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableBorderLight(),          0x3B3B40FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableRowBg(),                0x00000000)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableRowBgAlt(),             0xFFFFFF0F)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextSelectedBg(),            0x223F3759)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DragDropTarget(),            0xFFFF00E6)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_NavHighlight(),              0x1DB287FF)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_NavWindowingHighlight(),     0xFFFFFFB3)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_NavWindowingDimBg(),         0xCCCCCC33)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ModalWindowDimBg(),          0xCCCCCC59)
        -------------------------------------------------------------------------------------------------
        --GUI WINDOW STYLE-------------------------------------------------------------------------------
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_Alpha(),                       1)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_DisabledAlpha(),               0.6)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(),               8, 8)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(),              6)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowBorderSize(),            1)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowMinSize(),               32, 32)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowTitleAlign(),            0, 0.5)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildRounding(),               6)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildBorderSize(),             1)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_PopupRounding(),               6)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_PopupBorderSize(),             1)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),                4, 3)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(),               2)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameBorderSize(),             1)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),                 8, 4)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemInnerSpacing(),            4, 4)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_IndentSpacing(),               18)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_CellPadding(),                 4, 2)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarSize(),               14)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarRounding(),           6)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabMinSize(),                 12)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabRounding(),                1)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabRounding(),                 2)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabBorderSize(),               0)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabBarBorderSize(),            0)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TableAngledHeadersAngle(),     0.610865)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TableAngledHeadersTextAlign(), 0.5, 0)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ButtonTextAlign(),             0.5, 0.5)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SelectableTextAlign(),         0, 0)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextBorderSize(),     3)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextAlign(),          0, 0.5)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextPadding(),        20, 3)
        -------------------------------------------------------------------------------------------------

        reaper.ImGui_SetNextWindowSize(ctx, 200, 80, reaper.ImGui_Cond_FirstUseEver())
        ---------- DOCK
        if not mainDocked then
            --local dock_id = reaper.ImGui_GetID(ctx, "bottom_left")
            reaper.ImGui_SetNextWindowDockID(ctx, mainDockID, reaper.ImGui_Cond_FirstUseEver())
            mainDocked = true
        end
        local visible, open = reaper.ImGui_Begin(ctx, script_title, true, flags)
        if visible then
            TCHelper_Window()
            mainDockID = reaper.ImGui_GetWindowDockID(ctx)
            reaper.SetExtState("TCHelper", "DockID", tostring(mainDockID), true)
            reaper.ImGui_End(ctx)
        end
        if firstopened == false then
            openCuesWindow()
            openTrackWindow()
            firstopened = true
        end
        if cuesChecked == true then
            openCuesWindow()
        end
        if seqChecked == true then
            openTrackWindow()
        end
        if networkChecked == true then
            openConnectionWindow()
        end
        if shortcutsChecked == true then
            shortcutsChecked = openShortcutWindow()
        end
        ShowAboutWindow()
        ShowNewVersionUpdateWindow(newVersion)
        if manualCheck == true then
            ShowOldVersionUpdateWindow(version)
        end
        reaper.ImGui_PopStyleColor(ctx, 57)
        reaper.ImGui_PopStyleVar(ctx, 32)
        reaper.ImGui_PopFont(ctx)
        if open then
            reaper.defer(loop)
        end
    end
end

reaper.defer(loop)