local script_path = debug.getinfo(1, 'S').source:match([[^@?(.*[\/])[^\/]-$]])
package.path = script_path .. "?.lua;" .. package.path
local projectData = require('projectData')
local reaperHelper = require('reaperHelper')
local selectionTools = {}
function selectionTools.snapCursorToSelection()
    local selectedItem = reaperHelper.getFirstTouchedMediaItem()
    --local selectedItem = reaper.GetSelectedMediaItem(0, 0)
    if snapCursorbox == true then
        if selectedItem ~= nil then
            local startTime = reaper.GetMediaItemInfo_Value(selectedItem, "D_POSITION")
            reaper.SetEditCurPos(startTime, true, false)
        end
    end
end
function selectionTools.selectToolsmaller()
    local trackGUID = {}
    local trackAmmount = 0
    local cursorposition = reaper.GetCursorPosition()
    if selectedTrackOption == 'selected Track' then
        trackGUID[1] = projectData.readTrackGUID('selected')
        trackAmmount = 1
    elseif selectedTrackOption == 'all Tracks' then
        trackGUID = projectData.readTrackGUID('used')        
        trackAmmount = #trackGUID
    end
    for i = 1, trackAmmount do
        local itemGUID = projectData.readItemGUID(trackGUID[i])
        for j = 1, #itemGUID, 1 do
            if loadedtracks[trackGUID[i]].cue[itemGUID[j]].itemStart <= cursorposition then
                local itemhandle = reaper.BR_GetMediaItemByGUID( 0, loadedtracks[trackGUID[i]].cue[itemGUID[j]].id)
                reaper.SetMediaItemSelected(itemhandle, true) -- Select the item
                reaper.UpdateArrange() -- Update the arrangement to show the selection
            end
        end
    end
end
function selectionTools.selectToolhigher()
    local trackGUID = {}
    local trackAmmount = 0
    local cursorposition = reaper.GetCursorPosition()
    if selectedTrackOption == 'selected Track' then
        trackGUID[1] = projectData.readTrackGUID('selected')
        trackAmmount = 1
    elseif selectedTrackOption == 'all Tracks' then
        trackGUID = projectData.readTrackGUID('used')        
        trackAmmount = #trackGUID
    end
    for i = 1, trackAmmount do
        local itemGUID = projectData.readItemGUID(trackGUID[i])
        for j = 1, #itemGUID, 1 do
            if loadedtracks[trackGUID[i]].cue[itemGUID[j]].itemStart >= cursorposition then
                local itemhandle = reaper.BR_GetMediaItemByGUID( 0, loadedtracks[trackGUID[i]].cue[itemGUID[j]].id)
                reaper.SetMediaItemSelected(itemhandle, true) -- Select the item
                reaper.UpdateArrange() -- Update the arrangement to show the selection
            end
        end
    end
end
function selectionTools.selectToolall()
    local trackGUID = {}
    local trackAmmount = 0
    if selectedTrackOption == 'selected Track' then
        trackGUID[1] = projectData.readTrackGUID('selected')
        trackAmmount = 1
    elseif selectedTrackOption == 'all Tracks' then
        trackGUID = projectData.readTrackGUID('used')        
        trackAmmount = #trackGUID
    end
    for i = 1, trackAmmount do
        local itemGUID = projectData.readItemGUID(trackGUID[i])
        for j = 1, #itemGUID, 1 do            
            local itemhandle = reaper.BR_GetMediaItemByGUID( 0, loadedtracks[trackGUID[i]].cue[itemGUID[j]].id)
            reaper.SetMediaItemSelected(itemhandle, true) -- Select the item
            reaper.UpdateArrange() -- Update the arrangement to show the selection
        end
    end
end
return selectionTools