local script_path = debug.getinfo(1, 'S').source:match([[^@?(.*[\/])[^\/]-$]])
package.path = script_path .. "?.lua;" .. package.path
local error = require('error')
local projectData = {}
function projectData.readTrackGUID(token)
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
                error.noTrackError()  
            end
        end
        return trackGUID[1]
    end
end
function projectData.readItemGUID(trackGUID)
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
function projectData.getSelectedItemGUID()
    local selectedItem = reaper.GetSelectedMediaItem(0, 0) -- Get the first selected item
    local GUID = reaper.BR_GetMediaItemGUID(selectedItem)
    return GUID
end
function projectData.getItemCount(GUID)
    -- Gibt die Anzahl der Items im ausgewählten Track zurück, oder 0, wenn kein
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
function projectData.getCueNames()
    local trackID = projectData.readTrackGUID('selected')
    local selectedTrack = 'noTrack'
    selectedTrack = reaper.GetSelectedTrack(0, 0)
    local itemCount = 0
    local cueGUIDs = 'empty'
    if selectedTrack == nil then
        itemCount = 0
    else
        itemCount = reaper.CountTrackMediaItems(selectedTrack)
        cueGUIDs = projectData.readItemGUID(trackID)
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
function projectData.getSeqNames () 
    local newSeqNames = {}
    local usedTracks = projectData.readTrackGUID('used')
    for i = 1, #usedTracks, 1 do
        newSeqNames[i] = loadedtracks[usedTracks[i]].name
    end
    return newSeqNames
end
function projectData.getFadeTimes()
    local trackID = projectData.readTrackGUID('selected')
    local selectedTrack = 'noTrack'
    selectedTrack = reaper.GetSelectedTrack(0, 0)
    local itemCount = 0
    local cueGUIDs = 'empty'

    if selectedTrack == nil then
        itemCount = 0
    else
        itemCount = reaper.CountTrackMediaItems(selectedTrack)
        cueGUIDs = projectData.readItemGUID(trackID)
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
function projectData.getSelectedOption()
    local oldTrack = 'empty'
    if cursor == 1 then
        local selectedTrack = projectData.readTrackGUID('selected')
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
function projectData.getLongestTrackTime()
    local longestLength = reaper.GetProjectLength(0)
    return longestLength
end
return projectData