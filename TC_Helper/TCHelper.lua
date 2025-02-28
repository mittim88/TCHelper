-- @description TCHelper
-- @version 3.0.4
-- @author mittim88
-- @provides
--   /TC_Helper/*.lua

local mode2BETA = false
local version = '3.0.4'
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
local dummyIPstring = '--Enter console IP--'
local tracks = {}
local loadedtracks = {}
local sendedData = {}
local dummytrack = {}
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
local selectedIcon = ''
local iconFolder = 'TCHelper_Images'
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
local NewSeqNames = {}
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
        local itemGUID = readItemGUID(trackGUID[i])
        for j = 1, #itemGUID do
            if sendedData[trackGUID[i]].cue[itemGUID[j]].id == nil then
                SetupSendedDataItem (trackGUID[i],itemGUID[j])
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
function getItemCount()
    local selectedTrack = 'noTrack'
    selectedTrack = reaper.GetSelectedTrack(0, 0)
    if selectedTrack == nil then
        itemCount = 0
    else
        itemCount = reaper.CountTrackMediaItems(selectedTrack)
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
        
        oldCueName[i] = loadedtracks[trackID].cue[cueGUIDs[i]].name
    
        --reaper.ShowConsoleMsg(oldCueName[i])
    end
    return oldCueName
end
function getSeqNames ()
    local usedTracks = readTrackGUID('used')
    for i = 1, #usedTracks, 1 do
        NewSeqNames[i] = loadedtracks[usedTracks[i]].name
    end
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
        oldFadeTime[i] = loadedtracks[trackID].cue[cueGUIDs[i]].fadetime
        --reaper.ShowConsoleMsg(oldFadeTime[i])
    end
    return oldFadeTime
end
function checkTCHelperTracks()
    local selTrack = readTrackGUID('selected')
    local tcHelperTracks = readTrackGUID('used')
    local trackCheck = false
    if selTrack == nil then
        reaper.ShowMessageBox('\nNo Track selected\nPlease select your desired Track', 'Error', 0)
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
            --reaper.ImGui_MenuItem(ctx, '(demo menu)', nil, false, false)
            if ImGui.MenuItem(ctx, 'About') then
                local rv = reaper.ShowMessageBox('Version:\n'..version..'\nmade by: \nLichtwerk\nTim Eschert\nSupport:\ne-mail: support@lichtwerk.info', 'About TC Helper', 0)
            end
            if ImGui.MenuItem(ctx, 'Merge data') then
                mergeDataOption()
                local rv = reaper.ShowMessageBox('Merged data', script_title,0)
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
                getSeqNames()
                seqChecked = true
            end
            reaper.ImGui_EndMenu(ctx)
        end
        if reaper.ImGui_BeginMenu(ctx, 'Settings') then
            if ImGui.MenuItem(ctx, 'Network') then
                networkChecked = true
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
                    if selectedOption == 'Cue List' then
                        inputCueName = 'Cue - ' .. itemcount + 1
                        cueNr = itemcount + 1
                        --reaper.ShowConsoleMsg('\n'..selectedOption)
                        
                    else
                        inputCueName = 'Cue - ' ..1
                        cueNr = 1
                        --reaper.ShowConsoleMsg('\n'..selectedOption)
                        
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
function connectionWindowMode2()
    ---------------INPUTS---------------------------------------------------------------
    ---------------Input IP---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 250)
    
    rv, hostIP = reaper.ImGui_InputText(ctx, 'Host IP', hostIP)
    
    ---------------Input Port---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 250)
    rv, userName = reaper.ImGui_InputText(ctx, 'Username', userName)
    
    ---------------Input Test Message ---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 250)
    rv, testcmd2 = reaper.ImGui_InputText(ctx, 'Testcommand', testcmd2)
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
    
    
    
    
    ---------------Input Port---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 250)
    rv, consolePort = reaper.ImGui_InputText(ctx, 'Port', consolePort)
    ---------------Input Praefix---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 250)
    rv, prefix = reaper.ImGui_InputText(ctx, 'Prefix', prefix)
    ---------------Input Profile---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 250)
    rv, datapoolName = reaper.ImGui_InputText(ctx, 'DataPool', datapoolName)
    
    ---------------Input Test Message ---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 250)
    rv, testcmd3 = reaper.ImGui_InputText(ctx, 'Testcommand', testcmd3)
    ---------------BUTTON---------------------------------------------------------------
    ---------------Test Button---------------------------------------------------------------
    
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
    if loopback == 'false' then
        ImGui.PushID(ctx, 1)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button(),        Color.HSV(1 / 0, 1, 0.3, 1.0))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), Color.HSV(1 / 0, 1, 0.5, 1.0))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(),  Color.HSV(1 / 0, 1, 0,5, 1.0))
        if reaper.ImGui_Button(ctx, '    Connect to \nGrandMA3 OnPC', 250, 70) then
            hostIP = '127.0.0.1'
            loopback = 'true'
            reaper.SetExtState('console','3onPC', loopback, true)
        end
        ImGui.PopStyleColor(ctx, 3)
        ImGui.PopID(ctx)
    else
        ImGui.PushID(ctx, 1)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button(),        Color.HSV(1 / 3, 1, 0.3, 1.0))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), Color.HSV(1 / 3, 1, 0.5, 1.0))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(),  Color.HSV(1 / 3, 1, 0.5, 1.0))
        if reaper.ImGui_Button(ctx, '   Connected to \nGrandMA3 OnPC', 250, 70) then
            local ipOld = reaper.GetExtState('network','ip')
            hostIP = ipOld
            loopback = 'false'
            reaper.SetExtState('console','3onPC', loopback, true)
        end
        ImGui.PopStyleColor(ctx, 3)
        ImGui.PopID(ctx)
    end
    
    
    reaper.ImGui_SetCursorPos(ctx, 500, toptextYoffset + 50)
    rv,liveupdatebox = ImGui.Checkbox(ctx, 'Live update to console', liveupdatebox)
    
    ---------------Single Update Button---------------------------------------------------------------
    --[[ reaper.ImGui_SetCursorPos(ctx, 300, 190)
    if reaper.ImGui_Button(ctx, 'Load Project', 100, 50) then
        renumberItems()
        reaper.ImGui_SameLine(ctx)
    end ]]
end
function ToolsWindow()
    local cursorposition = reaper.GetCursorPosition()
    
    local systemFramerate = reaper.TimeMap_curFrameRate(0)
    local framerateText = 'Project Framerate: '..systemFramerate..' Frames'
    local inputwidth = 40
    local timetextX = 20
    local timetextY = 60
    local offset = 55
    local Yoffset = 30
    local hhSeconds = 0
    local mmSeconds = 0
    local ssfloat = 0
    local ffSeconds = 0
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
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, inputwidth)
    rv2, inputMM = reaper.ImGui_InputTextWithHint(ctx, ':', 'mm', inputMM)
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, inputwidth)
    rv3, inputSS = reaper.ImGui_InputTextWithHint(ctx, ': ', 'ss', inputSS)    
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, inputwidth)
    rv4, inputFF = reaper.ImGui_InputTextWithHint(ctx, 'New items time', 'ff', inputFF)
    if reaper.ImGui_Button(ctx, 'Set item to time', 200, 50) then
        hhSeconds = tonumber(inputHH) * 3600
        mmSeconds = tonumber(inputMM) * 60
        ssfloat = tonumber(inputSS)
        ffSeconds = tonumber(inputFF) / (systemFramerate)
        local newTime = hhSeconds + mmSeconds + ssfloat + ffSeconds
        moveItem (newTime)
        
    end
    rv,snapCursorbox = ImGui.Checkbox(ctx, 'Snap cursor to item', snapCursorbox)
    
    
    reaper.ImGui_SetCursorPos(ctx, 500, 90)
    ImGui.Text(ctx, '               Select before or after cursor')
    reaper.ImGui_SetCursorPos(ctx, 500, 110)
    if reaper.ImGui_Button(ctx, 'Before', 100, 100) then
        selectToolsmaller()
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'ALL', 100, 100) then
        selectToolall()
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'After', 100, 100) then
        selectToolhigher()
        
    end
    reaper.ImGui_SameLine(ctx)
    if not popups.popups then
        popups.popups = {
            selectedExecOption = 1,
        }
    end
    
    if ImGui.Button(ctx, 'Track option') then
        ImGui.OpenPopup(ctx, 'my_select_popup')
    end
    reaper.ImGui_SameLine(ctx)
    ImGui.Text(ctx, selOptions[popups.popups.selectedExecOption] or '<None>')
    if ImGui.BeginPopup(ctx, 'my_select_popup') then
        ImGui.SeparatorText(ctx, 'Track Option')
        for i, options in ipairs(selOptions) do
            if ImGui.Selectable(ctx, options) then
                popups.popups.selectedExecOption = i
            end
        end
        ImGui.EndPopup(ctx)
    end
    for i = 1, #selOptions, 1 do
        if popups.popups.selectedExecOption == i then
            selectedTrackOption = selOptions[i]
        end
    end

    --TC HELPER NAME + Mode
   reaper.ImGui_SetCursorPos(ctx,toptextXoffset, 10 + toptextYoffset)
   ImGui.Text(ctx, headerText)
end
function CueListSetupWindow()
    local buttonX = 10
    local buttonY = 150
    local buttonWidth = 120
    local buttonHeight = 80
    local buttonSpace = 10

    ImGui.SeparatorText(ctx, 'SETUP CUELIST')
    ---------------INPUTS---------------------------------------------------------------
    ---------------Input Cuelist Name---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 300)
    rv, cueListName = reaper.ImGui_InputText(ctx, 'Cuelist Name', cueListName)
    cueListName = replaceSpecialCharacters(cueListName)
    ---------------Input Sequence ID---------------------------------------------------------------
    reaper.ImGui_SetCursorPos(ctx, 500, 80)
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    rv, seqID = reaper.ImGui_InputText(ctx, 'Sequence ID', seqID)
    reaper.ImGui_SetCursorPos(ctx, 500, 110)
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    rv, tcID = reaper.ImGui_InputText(ctx, 'Timecode ID', tcID)
    if MAmode == 'Mode 2' then
        ---------------BUTTON---------------------------------------------------------------
        ---------------Input Page Number---------------------------------------------------------------
        reaper.ImGui_SetCursorPos(ctx, 500, 140)
        reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
        rv, pageID = reaper.ImGui_InputText(ctx, 'Page Number', pageID)
        ---------------Input Executor ID ---------------------------------------------------------------
        reaper.ImGui_SetCursorPos(ctx, 500,170)
        reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
        rv, execID = reaper.ImGui_InputText(ctx, 'Executor ID', execID)
        
    end
    reaper.ImGui_SetCursorPos(ctx, 700, 80)
    
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
        deleteTrack()
        reaper.ImGui_SameLine(ctx)
    end
    ImGui.PopStyleColor(ctx, 3)
    ImGui.PopID(ctx)
    
    
    
    
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
     --TC HELPER NAME + Mode
   reaper.ImGui_SetCursorPos(ctx,toptextXoffset, 10 + toptextYoffset)
   ImGui.Text(ctx, headerText)
end
------------------------------------------------------------------------------
---------------ADD CUE WINDOW---------------------------------------------------------------
function CueItemWindow()
    
    ImGui.SeparatorText(ctx, 'SETUP EVENT')
    ---------------Input Cuelist Name---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 300)
    rv, inputCueName = reaper.ImGui_InputText(ctx, 'Cuename', inputCueName)
    inputCueName = replaceSpecialCharacters(inputCueName)
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    rv, fadetime = reaper.ImGui_InputText(ctx, 'Fadetime ', fadetime)
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    
    rv, cueNr = reaper.ImGui_InputText(ctx, 'cue nr (will be set automatically)', cueNr)
    
    ---------------Add Item Button---------------------------------------------------------------
    reaper.ImGui_SetCursorPos(ctx, 500, toptextYoffset + 55)
    if reaper.ImGui_Button(ctx, 'Add cue', 100, 80) then
        local check = checkTCHelperTracks()

        if check == false then
            --consoleMSG('Check False')
        else
            --consoleMSG('Check true')

        addItem()
        end
        reaper.ImGui_SameLine(ctx)
    end 
    ---------------Delete Item Button---------------------------------------------------------------
    reaper.ImGui_SetCursorPos(ctx, 610, toptextYoffset + 55)
    
    ImGui.PushID(ctx, 1)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button(),        Color.HSV(1 / 0, 1, 0.3, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), Color.HSV(1 / 0, 1, 0.8, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(),  Color.HSV(1 / 0, 1, 1, 1.0))
    
    if reaper.ImGui_Button(ctx, '  Delete\nselection', 100, 80) then
        deleteSelection()
        reaper.ImGui_SameLine(ctx)
    end 
    ImGui.PopStyleColor(ctx, 3)
    ImGui.PopID(ctx)
    --TC HELPER NAME + Mode
    reaper.ImGui_SetCursorPos(ctx,toptextXoffset, 10 + toptextYoffset)
    ImGui.Text(ctx, headerText)
end
function TempItemWindow()
    ImGui.SeparatorText(ctx, 'SETUP EVENT')
    ---------------Input Cuelist Name---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 300)
    rv, fadetime = reaper.ImGui_InputText(ctx, 'Fadetime ', fadetime)
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    rv, holdtime = reaper.ImGui_InputText(ctx, 'Holdtime in sec', holdtime)
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    
    
    
    ---------------Add Item Button---------------------------------------------------------------
    reaper.ImGui_SetCursorPos(ctx, 500, toptextYoffset + 55)
    if reaper.ImGui_Button(ctx, 'Add buttonpress', 150, 80) then
        --cueName = 'Cue '..cueNr
        local check = checkTCHelperTracks()

        if check == false then
            --consoleMSG('Check False')
        else
            --consoleMSG('Check true')

        addItem()
        end
        reaper.ImGui_SameLine(ctx)
    end
    ---------------Delete Item Button---------------------------------------------------------------
    reaper.ImGui_SetCursorPos(ctx, 660, toptextYoffset + 55)
    ImGui.PushID(ctx, 1)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button(),        Color.HSV(1 / 0, 1, 0.3, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), Color.HSV(1 / 0, 1, 0.8, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(),  Color.HSV(1 / 0, 1, 1, 1.0))
    if reaper.ImGui_Button(ctx, '  Delete\nSelection', 100, 80) then
        deleteSelection()
        reaper.ImGui_SameLine(ctx)
    end 
    
    
    ImGui.PopStyleColor(ctx, 3)
    ImGui.PopID(ctx)
    --TC HELPER NAME + Mode
    reaper.ImGui_SetCursorPos(ctx,toptextXoffset, 10 + toptextYoffset)
    ImGui.Text(ctx, headerText)
end
-----------------RENAMEING DATA WINDOWS-------------------------------------------------------------
function renameTrackWindow()
    local spaceBtn = 50
    local paneWidth = 400
    local usedTracks = readTrackGUID('used')
    local seqNames = {}
    local seqIDs = {}
    for i = 1, #usedTracks, 1 do
        seqIDs[i] = loadedtracks[usedTracks[i]].seqID
    end
   
    if not app.layout then
        app.layout = {
            selected = 0,
        }
    end
    if ImGui.BeginChild(ctx, 'left pane', paneWidth, 0, true) then
        reaper.ImGui_Text(ctx, 'Sequencenames')
        for i = 1, #NewSeqNames, 1 do
            ImGui.SetNextItemWidth(ctx, 150)
            rv, NewSeqNames[i] = reaper.ImGui_InputText(ctx, 'Seq '..seqIDs[i], NewSeqNames[i])
        end
        ImGui.EndChild(ctx)
    end
    reaper.ImGui_SetCursorPos(ctx, paneWidth + spaceBtn, 60)
    if reaper.ImGui_Button(ctx, 'WRITE NEW\n     DATA', 100, 100) then
        renameTrack(NewSeqNames)
    end 
    reaper.ImGui_SetCursorPos(ctx, paneWidth + spaceBtn, 180)
    if reaper.ImGui_Button(ctx, 'Reload data', 100, 100) then
               NewCueNames = getSeqNames()
       end 
end
function renameCuesWindow()
    local spaceBtn = 50
    local paneWidth = 400
    local tcTrack = readTrackGUID('selected')
    if tcTrack == false then
        reaper.ImGui_Text(ctx, 'No track selected')
    else

        if not app.layout then
            app.layout = {
                selected = 0,
            }
        end
        reaper.ImGui_Text(ctx,'Selected track: '..seqName)
        if ImGui.BeginChild(ctx, 'left pane', paneWidth, 0, true) then
            reaper.ImGui_SetCursorPos(ctx, 50,10)
            reaper.ImGui_Text(ctx, 'Cuenames')
            reaper.ImGui_SetCursorPos(ctx,250,10)
            reaper.ImGui_Text(ctx, 'Fadetimes')
            local j = 0
            for i = 1, #NewCueNames, 1 do
                local cueID
                if i < 10 then
                    cueID = string.format('%02d', i)
                else
                    cueID = i
                end
                ImGui.SetNextItemWidth(ctx, 150)
                rv, NewCueNames[i] = reaper.ImGui_InputText(ctx, 'Cue-'..cueID, NewCueNames[i])
                reaper.ImGui_SameLine(ctx)
                ImGui.SetNextItemWidth(ctx, 50)
                rv, NewFadeTimes[i] = reaper.ImGui_InputText(ctx, 'Fade-'..cueID, NewFadeTimes[i])
                reaper.ImGui_SameLine(ctx)
                
                
                if reaper.ImGui_Button(ctx, 'Select '..i, 50,19) then
                    local trackItem = reaper.BR_GetMediaTrackByGUID( 0, tcTrack )
                    local item = reaper.GetTrackMediaItem(trackItem, j)
                    local rv, itemGUID = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)
                    local newCursorPos = loadedtracks[tcTrack].cue[itemGUID].itemStart
                    setCursorToItem(newCursorPos)
                    --reaper.ShowConsoleMsg('\n Select: '..itemGUID)
                end 
                j = j + 1


            end
            ImGui.EndChild(ctx)
            
        end

    end
    reaper.ImGui_SetCursorPos(ctx, paneWidth + spaceBtn, 60)
    if reaper.ImGui_Button(ctx, 'WRITE NEW\n     DATA', 100, 100) then
        renameItems()
    end 
    
    reaper.ImGui_SetCursorPos(ctx, paneWidth + spaceBtn, 180)
    if reaper.ImGui_Button(ctx, 'Reload data', 100, 100) then
     --reaper.ShowConsoleMsg('\nLOAD')
        local validTracks = checkTCHelperTracks()
        if validTracks == true then
            local selTrack = readTrackGUID('selected')
            seqName = loadedtracks[selTrack].name
            NewCueNames = getCueNames()
            NewFadeTimes = getFadeTimes()
        else
        end
    end 
end



function openCuesWindow()

    ImGui.SetNextWindowSize(ctx, 400, 440, ImGui.Cond_FirstUseEver())
    --local selTrack = readTrackGUID('selected')
    --seqName = loadedtracks[selTrack].name
    visible,cuesChecked = ImGui.Begin(ctx, 'Cue Data', true, ImGui.WindowFlags_MenuBar())
    if visible then
        renameCuesWindow()
        getTrackContent()
        reaper.ImGui_End(ctx)
    end
    
    return cuesChecked
end
function openTrackWindow()

    ImGui.SetNextWindowSize(ctx, 400, 440, ImGui.Cond_FirstUseEver())
    --local selTrack = readTrackGUID('selected')
    --seqName = loadedtracks[selTrack].name
    visible,seqChecked = ImGui.Begin(ctx, 'Sequence Data', true, ImGui.WindowFlags_MenuBar())
    if visible then
        renameTrackWindow()
        getTrackContent()
        reaper.ImGui_End(ctx)
    end
   
    return seqChecked
end
function openConnectionWindow()

    ImGui.SetNextWindowSize(ctx, 800, 800, ImGui.Cond_FirstUseEver())
  visible,networkChecked = ImGui.Begin(ctx, 'Connection Settings', true)
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
    local red = 0
    local green = 0
    local blue = 0
    local buttonName = ''
    local trackAmmount = reaper.GetNumTracks()
    local newTrackID = trackAmmount + 1
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
    local trackName = 'empty'
    if MAmode == 'Mode 3' then
        trackName = '|'..cueListName .. '|SeqID:' .. seqID ..'|'..buttonName .. '|TC ID:' .. tcID..'|'
    elseif MAmode == 'Mode 2' then
        trackName = '|'..cueListName .. '|SeqID:' .. seqID ..'|'..buttonName .. '|TC ID:' .. tcID..'|Page:'..pageID..'|Exec ID:'..execID..'|'
    end
    local iconPath = iconFolder .. '/' .. selectedIcon
    local track = reaper.GetTrack(0, newTrackID - 1)
    local trackstring = tostring(track)
    reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', trackName, true)
    reaper.GetSetMediaTrackInfo_String(track, 'P_ICON', iconPath, true)
    reaper.SetTrackColor(track, reaper.ColorToNative(red, green, blue))
    
    local newTrackGUID = {}
    newTrackGUID = reaper.GetTrackGUID(track)
    tracks[newTrackGUID] = {}
    tracks[newTrackGUID] = dummytrack
    tracks[newTrackGUID].id = newTrackGUID
    tracks[newTrackGUID].name = trackName
    tracks[newTrackGUID].execID = execID
    tracks[newTrackGUID].pageID = pageID
    tracks[newTrackGUID].seqID = seqID
    tracks[newTrackGUID].execoption = buttonName
    SetupSendedDataTrack (newTrackGUID)
    getTrackContent()
end
function deleteTrack()
    --reaper.ShowConsoleMsg('\nDELETE TRACK START')
    
    local numSelectedTracks = reaper.CountSelectedTracks(0)
    if numSelectedTracks > 0 then
        reaper.PreventUIRefresh(1) -- Disable UI updates to prevent flickering
        
        for i = numSelectedTracks, 1, -1 do
            local track = reaper.GetSelectedTrack(0, i-1)
            local trackGUID = reaper.GetTrackGUID(track)
            local trackName = loadedtracks[trackGUID].name
            if liveupdatebox == true then
                local seqMessage = 'Delete Seq "'..trackName..'" /nc'
                local tcMessage = 'Delete Timecode '..tcID..'.1.'..loadedtracks[trackGUID].nr
                sendOSC(hostIP, consolePort, seqMessage)
                sendOSC(hostIP, consolePort, tcMessage)
            end
            reaper.DeleteTrack(track)
        end      
        reaper.PreventUIRefresh(-1) -- Enable UI updates
        reaper.UpdateArrange() -- Refresh the GUI
    else
        reaper.ShowMessageBox("No tracks selected.", "Error", 0)
    end
    getTrackContent()
    --reaper.ShowConsoleMsg('\nDELETE TRACK END')
end
function renameTrack(newSeqNames)
    getTrackContent()
    local trackGUIDs = readTrackGUID('used')
    local newName = {}
    for i = 1, #newSeqNames, 1 do
        local trackItem = reaper.BR_GetMediaTrackByGUID(0, trackGUIDs[i])
        local ret, oldName = reaper.GetTrackName(trackItem)
        local oldSeqID = loadedtracks[trackGUIDs[i]].seqID
        local oldButtonName = loadedtracks[trackGUIDs[i]].execoption
        local oldTCID = loadedtracks[trackGUIDs[i]].execoption
        if MAmode == 'Mode 3' then
            newName = '|'..newSeqNames[i] .. '|SeqID:' .. oldSeqID ..'|'..oldButtonName .. '|TC ID:' .. oldTCID..'|'
        elseif MAmode == 'Mode 2' then
            local oldPageID = loadedtracks[trackGUIDs[i]].pageID
            local oldExecID = loadedtracks[trackGUIDs[i]].execID
            newName = '|'..newSeqNames[i] .. '|SeqID:' .. oldSeqID ..'|'..oldButtonName .. '|TC ID:' .. oldTCID..'|Page:'..oldPageID..'|Exec ID:'..oldExecID..'|'
        end
        reaper.GetSetMediaTrackInfo_String(trackItem, 'P_NAME', newName, true)
    end
    getTrackContent()
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
        for i = 1, #selectedItems, 1 do
            reaper.DeleteTrackMediaItem(reaper.GetMediaItem_Track(selectedItems[i]), selectedItems[i])
        end
    else
        reaper.ShowMessageBox("No Cues selected.", "Error", 0)
    end

    getTrackContent()
    --reaper.ShowConsoleMsg('\n--DELETE ENDED--')
end
---------------ADD Item --------------------------------------------------------------------
function addItem()
    getTrackContent()
    noTrackError()
    local retval
    local selected_trk = reaper.GetSelectedTrack(0, 0)
    local trackGUID = readTrackGUID('selected')
    local playPos = reaper.GetPlayPosition()
    local cursorpos = reaper.GetCursorPosition()
    local media_item = nil
    local itemName = 'ph'
    local pressNr = cueNr
    local itemcount = getItemCount()

    if selected_trk == nil then
        selected_trk = 'noTrack'
    else
        media_item = reaper.AddMediaItemToTrack(selected_trk)
        local insertTime = -1
        local playState = reaper.GetPlayState()
        if playState == 1 then
            insertTime = playPos
        else
            insertTime = cursorpos
        end
    
        if selectedOption == 'Cue List' then
            itemName = '|' ..inputCueName ..'|\n|' ..loadedtracks[trackGUID].execoption .. '|\n|Cue: ' .. cueNr .. '|\n|Fadetime: ' ..fadetime .. '|'
        elseif selectedOption == 'Flash Button' or 'Temp Button' then
            itemName = '|' ..inputCueName ..'|\n|' ..loadedtracks[trackGUID].execoption .. '|\n|Press: ' .. pressNr .. '|\n|Fadetime: ' ..fadetime .. '|\n|Hold: ' .. holdtime .. '|'
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
        local selectedTrack = reaper.GetSelectedTrack(0, 0)
        if selectedTrack ~= nil then
            local itemCount = reaper.CountTrackMediaItems(selectedTrack)
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
    end
    getTrackContent()
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
    for i = 1, cueAmmount, 1 do
        mediaItem[i] = reaper.BR_GetMediaItemByGUID(0, cueGUIDs[i])
    end
    for i = 1, cueAmmount, 1 do
        local inputName = replaceSpecialCharacters(NewCueNames[i])
        local inputFade = NewFadeTimes[i]
        itemName = '|' ..inputName..'|\n|' ..loadedtracks[trackGUID].execoption .. '|\n|Cue: ' .. i .. '|\n|Fadetime: ' ..inputFade .. '|'
        reaper.GetSetMediaItemInfo_String(mediaItem[i], "P_NOTES", itemName, true)
    end
    reaper.ThemeLayout_RefreshAll()
    getTrackContent()
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
                for w in string.gmatch(name, "|([^|]+)|") do
                    --namePart[i] = w or 'not defined'
                    table.insert(namePart[i], w)
                end
                
                oldCueNr[i] = tonumber(string.match(namePart[i][3], "Cue: (%d+)"))
                --oldCueNr[i] = tonumber(namePart[i][3]:gsub("%D", ""))
                
                --reaper.ShowConsoleMsg('\nName Part: '..namePart[i][3])
                --reaper.ShowConsoleMsg('\noldNumber: '..oldCueNr[i])
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
                        ---------CUELIST RENUMBERRING
                        if i ~= oldCueNr[i] then
                            local nextCue = i + 1
                            --reaper.ShowConsoleMsg('\nrenumber Start')
                            --reaper.ShowConsoleMsg('\ni: '..i)
                            --reaper.ShowConsoleMsg('\noldNumber: '..oldCueNr[i]) 

                            local cmd = 'Move Sequence '..seqID..' Cue "'..namePart[i][1]..'" at Sequence '..seqID..' Cue '..i
                            if MAmode == 'Mode 2' then
                                sendTelnet(cmd)
                            elseif MAmode == 'Mode 3' then
                                sendOSC(hostIP, consolePort, cmd)
                            end
                            sendedData[selTrack].cue[itemGUID[i]].TCid = 'empty'
                            sendedData[selTrack].cue[itemGUID[i]].TCname = 'empty'
                            sendedData[selTrack].cue[itemGUID[i]].itemStart = 'empty'
                            sendedData[selTrack].execoption = 'empty'
                            sendedData[selTrack].cue[itemGUID[i]].token = 'empty'
                            --reaper.ShowConsoleMsg('\n LIST RENUMBER END')
                        end                
                    end
                end
            end
        end
    end
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
   

        
end
function setCursorToItem (itemPos)
    reaper.SetEditCurPos( itemPos, true, true )
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
                OscCommands.cue.storeCueCmd[i][j] =              'Store Seq ' ..loadedtracks[usedTrackGUID[i]].seqID.. ' Cue 1  /o'
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
                            if sendedData[usedTracks[i]].tempCueSended == false then
                                sendOSC(hostIP, consolePort, OscCommands.cue.storeCueCmd[i][1])
                                sendedData[usedTracks[i]].tempCueSended = true
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
function sendOSC(hostIP, consolePort, cmd) --2480
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
local dock = -3
checkSWS()
InitiateSendedData()
getTrackContent()
checkSendedData()
defineMA3ModeOnFirstStrartup()
local flags = reaper.ImGui_WindowFlags_MenuBar()   -- Add Menu bar and remove the rezise feature. 
local function loop()
    if addonCheck == true then
        renumberItems()
        --setIPAdress()
        if liveupdatebox == true then --LIVE UPDATE IM LOOP AKTIVIERT
            mergeDataOption()
        end
        --reaper.ShowConsoleMsg('\n'..inputCueName)
        --getTrackContent()
        snapCursorToSelection()
        cueCount = getItemCount()
        getCursorPosition()
        getSelectedOption()

        reaper.ImGui_PushFont(ctx, sans_serif)
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




reaper.ImGui_SetNextWindowSize(ctx, 400, 80, reaper.ImGui_Cond_FirstUseEver())
---------- DOCK
if dock then
    reaper.ImGui_SetNextWindowDockID(ctx, dock)
    dock = nil
end
local visible, open = reaper.ImGui_Begin(ctx, script_title, true, flags)
if visible then
    TCHelper_Window()
    reaper.ImGui_End(ctx)
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
        reaper.ImGui_PopStyleColor(ctx, 57)
        reaper.ImGui_PopStyleVar(ctx, 32)
        reaper.ImGui_PopFont(ctx)
        if open then
            reaper.defer(loop)
        end
    end
end
reaper.defer(loop)