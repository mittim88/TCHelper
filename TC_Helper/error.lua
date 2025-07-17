local error = {}
function error.noTrackError()
    local selected_trk = reaper.GetSelectedTrack(0, 0)
    if selected_trk == nil then
        reaper.ShowMessageBox("No Track selected", "Error", 0)
    end    
end





return error