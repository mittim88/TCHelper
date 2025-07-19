local script_path = debug.getinfo(1, 'S').source:match([[^@?(.*[\/])[^\/]-$]])
package.path = script_path .. "?.lua;" .. package.path

local projectData = require("projectData")

local reaperHelper = {}
function reaperHelper.getCursorPosition()
    cursor = reaper.GetCursorContext2(true)
    return cursor
end
function reaperHelper.getFirstTouchedMediaItem()
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
function reaperHelper.checkTCHelperTracks()
    local selTrack = projectData.readTrackGUID('selected')
    local tcHelperTracks = projectData.readTrackGUID('used')
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
function reaperHelper.togglePlayPause()
    if reaper.GetPlayState() == 0 then
        reaper.OnPlayButton() -- Startet die Wiedergabe
    else
        reaper.OnPauseButton() -- Pausiert die Wiedergabe
    end
end
function reaperHelper.checkIfTrackSelected()
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
return reaperHelper