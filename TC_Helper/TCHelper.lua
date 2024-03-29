-- @description TCHelper
-- @version 2.7.2
-- @author mittim88
-- @provides
--   /TC_Helper/*.lua



local version = '2.7.2'
local testcmd = 'Echo --CONNECTION IS FINE--'
local script_title = 'TC HELPER'
local hostIP = reaper.GetExtState('network','ip')

local prefix = reaper.GetExtState('network','prefix')
local consolePort = reaper.GetExtState('network','port')

local cueListName = 'Test Cuelist'
local pageID = 11
local seqID = tonumber(reaper.GetExtState('trackconfig', 'seqId'))
local seqBase = tonumber(reaper.GetExtState('trackconfig', 'seqId'))
if seqID == nil then
    seqID = 1
    seqBase = 1
end
local execID = 301
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
local dummyIPstring = '--Enter Console IP--'
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
local iconFolder = 'TE'
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
local loopback = false
local addonCheck = true
local NewCueNames = {}
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
end
sendedData.TCsendedShow = false    
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
-- function print(val)

--   reaper.ShowConsoleMsg(tostring(val) .. '\n')
-- end

-- load namespace
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
    --reaper.ShowConsoleMsg('\nGUI Addons vorhanden')
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

function checkSWS()
    local version = reaper.CF_GetSWSVersion()
    if version == nil then
        reaper.ShowMessageBox('\nSWS Addon not installed\nPlease Install SWS Extenstions:\nhttps://www.sws-extension.org', 'Error', 0)
        addonCheck = false
    end
    
end

-----------------------------------------------------------------
-----------------BACKGROUND STUFF-------------------------------------------------------------
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
    local check = '-'
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
    local check = '-'
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
                for w in string.gmatch(name, "[^-]+") do
                    table.insert(word, w)
                end
                if loadedtracks[loadedTrackGUID[tGC]] == nil then
                    loadedtracks[loadedTrackGUID[tGC]] = {}
                end
                local seqNr = word[2]:gsub("%D", "")
                local tcNr = word[4]:gsub("%D", "")
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
-----------------------------------------------------------------
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
local old_trackcount = -1
local function TCHelper_Window()
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
        if ImGui.BeginTabItem(ctx, 'Connection',0,0) then
            testWindow()
            ImGui.EndTabItem(ctx)
        end
        ImGui.EndTabBar(ctx)
    end
end
local rv
function testWindow()
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
    rv, testcmd = reaper.ImGui_InputText(ctx, 'Test Command', testcmd)
    ---------------BUTTON---------------------------------------------------------------
    ---------------Test Button---------------------------------------------------------------
    
    if reaper.ImGui_Button(ctx, '          Save\nNetwork Config', 121, 50) then
        reaper.SetExtState('network','ip',hostIP,true)
        reaper.SetExtState('network','port',consolePort,true)
        reaper.SetExtState('network','prefix',prefix,true)
        reaper.SetExtState('basic','dataPoolName',datapoolName,true)
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, '          Load\nNetwork Config', 121, 50) then
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
    if reaper.ImGui_Button(ctx, '      Test\nConnection', 121, 50) then
        sendOSC(hostIP, consolePort, testcmd)
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
    if loopback == false then
        ImGui.PushID(ctx, 1)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button(),        Color.HSV(1 / 0, 1, 0.3, 1.0))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), Color.HSV(1 / 0, 1, 0.5, 1.0))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(),  Color.HSV(1 / 0, 1, 0,5, 1.0))
        if reaper.ImGui_Button(ctx, '    Connect to \nGrandMA3 OnPC', 250, 70) then
            hostIP = '127.0.0.1'
            loopback = true
        end
        ImGui.PopStyleColor(ctx, 3)
        ImGui.PopID(ctx)
    else
        ImGui.PushID(ctx, 1)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button(),        Color.HSV(1 / 3, 1, 0.3, 1.0))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), Color.HSV(1 / 3, 1, 0.5, 1.0))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(),  Color.HSV(1 / 3, 1, 0.5, 1.0))
        if reaper.ImGui_Button(ctx, '    Connected to \nGrandMA3 OnPC', 250, 70) then
            local ipOld = reaper.GetExtState('network','ip')
            hostIP = ipOld
            loopback = false
        end
        ImGui.PopStyleColor(ctx, 3)
        ImGui.PopID(ctx)
    end
    
    
    reaper.ImGui_SetCursorPos(ctx, 500, 35)
    rv,liveupdatebox = ImGui.Checkbox(ctx, 'Live Update to Console', liveupdatebox)
    reaper.ImGui_SetCursorPos(ctx, 800, 35)
    ImGui.Text(ctx, 'LichtWerk\n\nmade by: Tim Eschert\ncontact:\ne-mail: support@lichtwerk.info')
    
    reaper.ImGui_SetCursorPos(ctx, 800, 10)
    ImGui.Text(ctx, script_title..' v.'..version)
    
    
    ---------------Single Update Button---------------------------------------------------------------
    --[[ reaper.ImGui_SetCursorPos(ctx, 300, 190)
    if reaper.ImGui_Button(ctx, 'Load Project', 100, 50) then
        renumberItems()
        reaper.ImGui_SameLine(ctx)
    end ]]
end

-----------------RENAMEING CUES WINDOW-------------------------------------------------------------
function renameCuesWindow()
    local selTrack = readTrackGUID('selected')
    if selTrack == nil then
        reaper.ImGui_Text(ctx, 'NO TRACK SELECTED')
    else
        if not app.layout then
            app.layout = {
                selected = 0,
            }
        end
        
        reaper.ImGui_Text(ctx, 'Cuenames:')
        if ImGui.BeginChild(ctx, 'left pane', 400, 0, true) then
            for i = 1, #NewCueNames, 1 do
                rv, NewCueNames[i] = reaper.ImGui_InputText(ctx, 'Cue '..i , NewCueNames[i])
            end
            ImGui.EndChild(ctx)
            
        end
        
        reaper.ImGui_SetCursorPos(ctx, 500, 60)
        if reaper.ImGui_Button(ctx, 'Rename Cues', 100, 100) then
            renameItems()
        end 
        -- reaper.ImGui_SetCursorPos(ctx, 500, 170)
        -- if reaper.ImGui_Button(ctx, 'Cancel', 100, 100) then
         
        -- end 

        
    end
end
function openCuesWindow()

    ImGui.SetNextWindowSize(ctx, 400, 440, ImGui.Cond_FirstUseEver())
  local visible,open = ImGui.Begin(ctx, 'Rename Cues', true, ImGui.WindowFlags_MenuBar())
  if visible then
    
    renameCuesWindow()
    getTrackContent()
    reaper.ImGui_End(ctx)
    end
    if open then
        reaper.defer(openCuesWindow)
    end
    return open
end
------------------------------------------------------------------------------
function ToolsWindow()
    local cursorposition = reaper.GetCursorPosition()
    
    local systemFramerate = reaper.TimeMap_curFrameRate(0)
    local framerateText = 'Project Framerate: '..systemFramerate..' Frames'
    local inputwidth = 40
    local timetextX = 20
    local timetextY = 80
    local offset = 55
    local hhSeconds = 0
    local mmSeconds = 0
    local ssfloat = 0
    local ffSeconds = 0
    ImGui.SeparatorText(ctx, 'Selection Tools')
    ImGui.Text(ctx, framerateText)
    reaper.ImGui_SetCursorPos(ctx, timetextX, timetextY)
    ImGui.Text(ctx, 'hh')
    reaper.ImGui_SetCursorPos(ctx, timetextX + offset, timetextY)
    ImGui.Text(ctx, 'mm')
    reaper.ImGui_SetCursorPos(ctx, timetextX + 115, timetextY)
    ImGui.Text(ctx, 'ss')
    reaper.ImGui_SetCursorPos(ctx, timetextX + 180, timetextY)
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
    rv4, inputFF = reaper.ImGui_InputTextWithHint(ctx, 'New Items Time', 'ff', inputFF)
    if reaper.ImGui_Button(ctx, 'Set Item to Time', 200, 50) then
            hhSeconds = tonumber(inputHH) * 3600
            mmSeconds = tonumber(inputMM) * 60
            ssfloat = tonumber(inputSS)
            ffSeconds = tonumber(inputFF) / (systemFramerate)
        local newTime = hhSeconds + mmSeconds + ssfloat + ffSeconds
        moveItem (newTime)
    
    end
    rv,snapCursorbox = ImGui.Checkbox(ctx, 'Snap Cursor to Item', snapCursorbox)
    if reaper.ImGui_Button(ctx, 'Rename Cues', 200, 50) then
            NewCueNames = getCueNames()
            openCuesWindow()
    
    end
    
    reaper.ImGui_SetCursorPos(ctx, 500, 90)
    ImGui.Text(ctx, 'Select Before or After Cursor')
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
    
    if ImGui.Button(ctx, 'Track Option') then
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
    reaper.ImGui_SetCursorPos(ctx, 800, 10)
    ImGui.Text(ctx, script_title)
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
    reaper.ImGui_SetCursorPos(ctx, 500, 59)
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    rv, seqID = reaper.ImGui_InputText(ctx, 'Sequence ID', seqID)
    reaper.ImGui_SetCursorPos(ctx, 500, 84)
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    rv, tcID = reaper.ImGui_InputText(ctx, 'Timecode ID', tcID)
    reaper.ImGui_SetCursorPos(ctx, 500, 120)

    if reaper.ImGui_Button(ctx, 'Save Track Config', 145, 50) then
        reaper.SetExtState('trackconfig', 'seqId', seqID , true)
        reaper.SetExtState('trackconfig', 'tcId', tcID, true)

        reaper.ImGui_SameLine(ctx)
    end
    ---------------BUTTON---------------------------------------------------------------
    ---------------Input Page Number---------------------------------------------------------------
    -- reaper.ImGui_SetCursorPos(ctx, 500, 134)
    -- reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    -- rv, pageID = reaper.ImGui_InputText(ctx, 'Page Number', pageID)
    -- ---------------Input Executor ID ---------------------------------------------------------------
    -- reaper.ImGui_SetCursorPos(ctx, 500, 109)
    -- reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    -- rv, execID = reaper.ImGui_InputText(ctx, 'Executor ID', execID)
    ---------------Input TimecodeID---------------------------------------------------------------
    ---------------Add Item Button---------------------------------------------------------------

    reaper.ImGui_SetCursorPos(ctx, buttonX, buttonY)
    if reaper.ImGui_Button(ctx, '    Add\nTC Track', buttonWidth, buttonHeight) then
        addTrack()

        reaper.ImGui_SameLine(ctx)
    end
    reaper.ImGui_SetCursorPos(ctx, buttonX+buttonWidth+buttonSpace, buttonY)
    
    ImGui.PushID(ctx, 1)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button(),        Color.HSV(1 / 0, 1, 0.3, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), Color.HSV(1 / 0, 1, 0.8, 1.0))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(),  Color.HSV(1 / 0, 1, 1, 1.0))
    if reaper.ImGui_Button(ctx, '  Delete\nTC Track', buttonWidth, buttonHeight) then
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
    reaper.ImGui_SetCursorPos(ctx, 9, 99)
    if ImGui.Button(ctx, 'Select Exec Option') then
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
    reaper.ImGui_SetCursorPos(ctx, 800, 10)
    ImGui.Text(ctx, script_title)
end
---------------ADD CUE WINDOW---------------------------------------------------------------
function CueItemWindow()

    ImGui.SeparatorText(ctx, 'SETUP EVENT')
    ---------------Input Cuelist Name---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 300)
    rv, inputCueName = reaper.ImGui_InputText(ctx, 'Cue Name', inputCueName)
    inputCueName = replaceSpecialCharacters(inputCueName)
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    rv, fadetime = reaper.ImGui_InputText(ctx, 'Fade Time ', fadetime)
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)

    rv, cueNr = reaper.ImGui_InputText(ctx, 'Cue Nr (Will be set automatically)', cueNr)

    ---------------Add Item Button---------------------------------------------------------------
    reaper.ImGui_SetCursorPos(ctx, 500, 60)
    if reaper.ImGui_Button(ctx, 'Add Cue', 100, 80) then
        addItem()
        reaper.ImGui_SameLine(ctx)
    end 
    ---------------Delete Item Button---------------------------------------------------------------
    reaper.ImGui_SetCursorPos(ctx, 610, 60)

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
    reaper.ImGui_SetCursorPos(ctx, 800, 10)
    ImGui.Text(ctx, 'TC HELPER')
end
function TempItemWindow()
    ImGui.SeparatorText(ctx, 'SETUP EVENT')
    ---------------Input Cuelist Name---------------------------------------------------------------
    reaper.ImGui_SetNextItemWidth(ctx, 300)
    rv, fadetime = reaper.ImGui_InputText(ctx, 'Fade Time ', fadetime)
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    rv, holdtime = reaper.ImGui_InputText(ctx, 'Hold Time in sec', holdtime)
    reaper.ImGui_SetNextItemWidth(ctx, standardTextwith)
    
    
    
    ---------------Add Item Button---------------------------------------------------------------
    reaper.ImGui_SetCursorPos(ctx, 500, 60)
    if reaper.ImGui_Button(ctx, 'Add Button Press', 150, 80) then
        --cueName = 'Cue '..cueNr
        addItem()
        reaper.ImGui_SameLine(ctx)
    end
    ---------------Delete Item Button---------------------------------------------------------------
    reaper.ImGui_SetCursorPos(ctx, 660, 60)
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
    reaper.ImGui_SetCursorPos(ctx, 800, 10)
    ImGui.Text(ctx, script_title)
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
    
    local trackName = '-'..cueListName .. '-SeqID:' .. seqID ..'-'..buttonName .. '-TC ID:' .. tcID
    local iconPath = iconFolder .. '/' .. selectedIcon
    local track = reaper.GetTrack(0, newTrackID - 1)
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
---------------Delete Selection-------------------------------------------------------------------
function deleteSelection()
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
            local fadenum = tonumber (fadetime)
            local endTime = holdnum + fadenum
            reaper.SetMediaItemInfo_Value(media_item, "D_LENGTH", holdnum)
        end
        local selectedTrack = reaper.GetSelectedTrack(0, 0)
        if selectedTrack ~= nil then
            local itemCount = reaper.CountTrackMediaItems(selectedTrack)
            if itemCount > 0 then
            -- Use lastItem as the last touched media item
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
        SetupSendedDataItem (trackGUID,newCueGUID)
        renumberItems()
    end
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
                            sendOSC(hostIP, consolePort, cmd)
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
function renameItems()
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
        cueFade[i] = loadedtracks[trackGUID].cue[cueGUIDs[i]].fadetime
        mediaItem[i] = reaper.BR_GetMediaItemByGUID(0, cueGUIDs[i])
    end
    for i = 1, cueAmmount, 1 do
            local inputName = replaceSpecialCharacters(NewCueNames[i])
            itemName = '|' ..inputName..'|\n|' ..loadedtracks[trackGUID].execoption .. '|\n|Cue: ' .. i .. '|\n|Fadetime: ' ..cueFade[i] .. '|'

            reaper.GetSetMediaItemInfo_String(mediaItem[i], "P_NOTES", itemName, true)
    
        
    end
    reaper.ThemeLayout_RefreshAll()
    --reaper.ShowConsoleMsg('\nrenaming ENd')
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
      reaper.ShowConsoleMsg('\nDOUBLE NAME FOUND')
    end
    --sendedData = copy3(loadedtracks)
    --reaper.ShowConsoleMsg('\nEND OF SEND TO CONSOLE')
end

function sendOSC(hostIP, consolePort, cmd)
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
local dock = -3
checkSWS()
InitiateSendedData()
getTrackContent()

checkSendedData()

local function loop()
    if addonCheck == true then
        renumberItems()
        --setIPAdress()
        if liveupdatebox == true then --LIVE UPDATE IM LOOP AKTIVIERT
            if loadProjectMarker == false then
                sendedData = copy3(loadedtracks)
                loadProjectMarker = true
            end
            checkItemStatus()
            local OscCommands = setOSCcommand()
            sendToConsole(hostIP, consolePort, OscCommands)
        end
        --reaper.ShowConsoleMsg('\n'..inputCueName)
        --getTrackContent()
        snapCursorToSelection()
        cueCount = getItemCount()
        getCursorPosition()
        getSelectedOption()
        reaper.ImGui_PushFont(ctx, sans_serif)
        reaper.ImGui_SetNextWindowSize(ctx, 400, 80, reaper.ImGui_Cond_FirstUseEver())
        ---------- DOCK
        if dock then
            reaper.ImGui_SetNextWindowDockID(ctx, dock)
            dock = nil
        end
        ---------- DOCK
        local visible, open = reaper.ImGui_Begin(ctx, script_title, true)
        if visible then
            TCHelper_Window()
            reaper.ImGui_End(ctx)
        end
        reaper.ImGui_PopFont(ctx)
        if open then
            reaper.defer(loop)
        end
        
    end
end
reaper.defer(loop)
